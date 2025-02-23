import SwiftUI
import Combine

class MastermindGameState: ObservableObject {
    @Published var timeRemaining: Int = 600
    @Published var currentRow: Int = 0
    @Published var gameOver: Bool = false
    @Published var hasWon: Bool = false
    @Published var selectedColor: Color?
    @Published var message: String = ""
    @Published var showAlert: Bool = false
    @Published var messageOpacity: Double = 0
    @Published var isSecretCodeRevealed = false
    @Published var gameStarted: Bool = false
    @Published var hasTutorialBeenShown: Bool = false
    @Published var hasInstructionBeenShown: Bool = false // NEW STATE VARIABLE for instruction
    
    
    @Published var secretCode: [Color]
    var currentGuess: [Color?] = Array(repeating: nil, count: 4)
    @Published var guesses: [[Color?]] = Array(repeating: Array(repeating: nil, count: 4), count: 10)
    @Published var feedback: [[FeedbackPeg]] = Array(repeating: [], count: 10)
    private var timer: Timer?
    @Published var animatingPeg: (row: Int, column: Int)?
    
    enum Color: String, CaseIterable {
        case red, purple, yellow, brown, green, blue
        
        var uiColor: UIColor {
            switch self {
            case .red: return .systemRed
            case .purple: return .systemPurple
            case .yellow: return .systemYellow
            case .brown: return .brown
            case .green: return .systemGreen
            case .blue: return .systemBlue
            }
        }
    }
    
    enum FeedbackPeg: CaseIterable {
        case correct, wrongPosition, incorrect
        
        var color: UIColor {
            switch self {
            case .correct: return .black
            case .wrongPosition: return .white
            case .incorrect: return .lightGray
            }
        }
    }
    
    init() {
        secretCode = Self.generateSecretCode() // Generate initial secret code
        print("Secret Code: \(secretCode)")
        // Timer will be started explicitly after instructions
    }
    
    static func generateSecretCode() -> [Color] { // Static function to generate secret code
        return Array(0..<4).map { _ in Color.allCases.randomElement()! }
    }
    
    func startGameTimer() { // New function to start timer
        if !gameStarted { // Prevent starting timer multiple times
            startTimer()
            gameStarted = true
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self = self else { 
                timer.invalidate()
                return
            }
            if self.timeRemaining > 0 && !self.gameOver {
                self.timeRemaining -= 1
            } else {
                self.endGame(false)
                timer.invalidate()
            }
        }
    }
    
    func endGame(_ won: Bool) {
        gameOver = true
        hasWon = won
        timer?.invalidate()
        isSecretCodeRevealed = true // Reveal the secret code when the game ends
        message = won ? "Congratulations! You've won!" : "Game Over! Try again!"
        showAlert = !won // Show alert only if lost, not won
        messageOpacity = 1.0 // Fade message in
        
        if won {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { // Stay for 5 seconds, then reset
                withAnimation(.easeInOut(duration: 0.5)) { // Fade out animation before reset
                    self.messageOpacity = 0.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // Wait for fade out then reset
                    self.resetGame()
                }
            }
        }
    }
    
    func resetGame() {
        secretCode = Self.generateSecretCode()
        print("New Secret Code: \(secretCode)")
        timeRemaining = 600
        currentRow = 0
        gameOver = false
        hasWon = false
        selectedColor = nil
        currentGuess = Array(repeating: nil, count: 4)
        guesses = Array(repeating: Array(repeating: nil, count: 4), count: 10)
        feedback = Array(repeating: [], count: 10)
        message = ""
        showAlert = false
        messageOpacity = 0.0
        isSecretCodeRevealed = false
        gameStarted = false
      
        startGameTimer()
    }
    
    func clearCurrentRow() {
        guard !gameOver else { return }
        
        guesses[currentRow] = Array(repeating: nil, count: 4)
        currentGuess = Array(repeating: nil, count: 4)
        message = "Current row cleared."
        
        messageOpacity = 1.0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.5)) {
                self.messageOpacity = 0.0
            }
        }
    }
    
    
    func checkGuess(row: Int, col: Int) -> FeedbackPeg {
        let secret = secretCode[col]
        let guess = guesses[row][col]
        
        guard let guessUnwrapped = guess else {
            return .incorrect
        }
        
        if guessUnwrapped == secret {
            return .correct
        } else if secretCode.contains(guessUnwrapped) {
            return .wrongPosition
        } else {
            return .incorrect
        }
    }
    
    func checkCurrentGuess() -> [FeedbackPeg] {
        var feedback: [FeedbackPeg] = []
        let guess = guesses[currentRow]
        var secretCodeCopy: [Color?] = secretCode.map { $0 as Color? }
        var guessCopy: [Color?] = guess
        
        // 1. Check for Black Pegs (Correct color and position)
        for index in 0..<4 {
            if guess[index] == secretCodeCopy[index] {
                feedback.append(.correct)
                secretCodeCopy[index] = nil
                guessCopy[index] = nil
            }
        }
        
        // 2. Check for White Pegs (Correct color, wrong position)
        for guessIndex in 0..<4 {
            if let guessColor = guessCopy[guessIndex] {
                if let secretIndex = secretCodeCopy.firstIndex(where: { $0 == guessColor }) {
                    feedback.append(.wrongPosition)
                    secretCodeCopy[secretIndex] = nil
                    guessCopy[guessIndex] = nil
                }
            }
        }
        
        // 3. Fill remaining feedback with incorrect pegs if needed, up to 4
        while feedback.count < 4 {
            feedback.append(.incorrect)
        }
        
        return feedback.shuffled()
    }
    
    func getNextAvailableSlot() -> (row: Int, column: Int)? {
        for col in 0..<4 {
            if guesses[currentRow][col] == nil {
                return (currentRow, col)
            }
        }
        return nil // Row is full
    }
    
    // MARK: - New Property: Check if current row is filled
    var isCurrentRowFilled: Bool {
        return !guesses[currentRow].contains(nil)
    }
    
    // MARK: - Submit Guess Function called by both UI and AR Buttons
    func submitGuess() {
        guard !gameOver else { return } // Prevent submit if game over
        
        // MARK: - Check if current row is filled before submitting
        if !isCurrentRowFilled {
            message = "Please fill the current row"
            // showAlert = true // Removed alert
            messageOpacity = 1.0 // Fade message in
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { // Display for 3 seconds
                withAnimation(.easeInOut(duration: 0.5)) { // Fade out animation
                    self.messageOpacity = 0.0 // Fade message out
                }
            }
            return // Exit submitGuess if row is not filled, game continues
        }
        
        let feedbackResult = checkCurrentGuess()
        feedback[currentRow] = feedbackResult
        
        if feedbackResult.allSatisfy({ peg in
            peg == MastermindGameState.FeedbackPeg.correct
        }) {
            endGame(true) // Game won
        } else {
            if currentRow < 9 {
                currentRow += 1 // Move to next row
                currentGuess = Array(repeating: nil, count: 4) // Reset current guess for new row
            } else {
                endGame(false) // Game over - ran out of rows
            }
        }
    }
}
