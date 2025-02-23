import SwiftUI

struct ARMastermindView: View {
    @StateObject private var gameState = MastermindGameState()
    @State private var isSecretCodeVisible = false
    @State private var isInstructionVisible = false // Initially instruction is hidden, controlled by state
    @State private var isTutorialVisible = false // Initially tutorial is hidden, controlled by state
    @State private var tutorialStep = 1
    
    
    var body: some View {
        ZStack {
            ARViewContainer(gameState: gameState, instructionVisibility: $isInstructionVisible)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                HStack {
                    if !isInstructionVisible && !isTutorialVisible {
                        TimerView(seconds: gameState.timeRemaining)
                    }
                    Spacer()
                    Text("MASTERMIND")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.brown.opacity(0.8))
                        .cornerRadius(10)
                    Spacer()
                    if !isInstructionVisible && !isTutorialVisible {
                        Button("RESET") {
                            gameState.clearCurrentRow()
                        }
                        .foregroundColor(.yellow)
                        .padding()
                        .background(Color.brown.opacity(0.8))
                        .cornerRadius(10)
                    }
                }
                .padding()
                
                if isInstructionVisible && !isTutorialVisible { // Show instruction conditionally
                    Text("Point your iPad at a flat surface.\nTap on the semi-transparent board to place the game.")
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                } else if !isInstructionVisible && !isTutorialVisible {
                    if gameState.isSecretCodeRevealed {
                        HStack(spacing: 15) {
                            ForEach(gameState.secretCode.indices, id: \.self) { index in
                                Circle()
                                    .fill(Color(gameState.secretCode[index].uiColor))
                                    .frame(width: 30, height: 30)
                                    .overlay(Circle().stroke(Color.white.opacity(0.7), lineWidth: 1))
                            }
                        }
                        .padding(.bottom, 10)
                    }
                    
                    if !gameState.message.isEmpty {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            Text(gameState.message)
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(10)
                                .opacity(gameState.messageOpacity)
                        }
                    }
                }
                
                
                Spacer()
            }
            .padding()
            
            VStack {
                Spacer()
                if !isInstructionVisible && !isTutorialVisible {
                    Button("SUBMIT GUESS") {
                        gameState.submitGuess()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.green.opacity(0.8))
                    .cornerRadius(10)
                    .padding(.bottom, 20)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            
            // Tutorial Overlay
            if !gameState.hasTutorialBeenShown { // Show tutorial only once
                TutorialView(step: tutorialStep) { nextStep in
                    if nextStep {
                        tutorialStep += 1
                        if tutorialStep > 5 {
                            isTutorialVisible = false
                            // Instruction will be shown conditionally in onAppear
                            gameState.hasTutorialBeenShown = true
                            gameState.startGameTimer()
                        }
                    } else {
                        isTutorialVisible = false
                        // Instruction will be shown conditionally in onAppear
                        gameState.hasTutorialBeenShown = true
                        gameState.startGameTimer()
                    }
                }
                .id(tutorialStep)
            }
        }
        .alert(isPresented: $gameState.showAlert) {
            Alert(
                title: Text(gameState.hasWon ? "Congratulations!" : "Game Over"),
                message: Text(gameState.message),
                dismissButton: .default(Text("Play Again")) {
                    gameState.resetGame()
                    isSecretCodeVisible = false
                    isInstructionVisible = false // Instruction should not reappear on reset anymore
                    // isInstructionVisible = true // Instruction should not reappear on reset anymore
                    isTutorialVisible = false
                    tutorialStep = 1
                }
            )
        }
        .onReceive(gameState.$isSecretCodeRevealed) { isRevealed in
            isSecretCodeVisible = isRevealed
        }
        .onAppear {
            isTutorialVisible = !gameState.hasTutorialBeenShown // Show tutorial only once
            
            if !gameState.hasTutorialBeenShown && !gameState.hasInstructionBeenShown {
                isInstructionVisible = true // Show instruction after tutorial (first time only)
            } else {
                isInstructionVisible = false // Hide instruction if tutorial is not shown OR instruction already shown
            }
        }
    }
}
