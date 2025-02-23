import SwiftUI

struct TutorialView: View {
    @State var step: Int
    var completion: (_ nextStep: Bool) -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8).edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                
                // Step Content (Switch based on tutorialStep)
                switch step {
                case 1:
                    step1Content()
                case 2:
                    step2Content()
                case 3:
                    step3Content()
                case 4:
                    step4Content()
                case 5:
                    step5Content()
                default:
                    Text("Tutorial Completed!")
                }
                
                Spacer()
                
                HStack {
                    Button("Close Tutorial") {
                        completion(false) // Just signal tutorial close
                    }
                    .padding()
                    .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button("Next") {
                        completion(true) // Signal next step or tutorial completion
                    }
                    .padding()
                    .foregroundColor(.white)
                }
                .padding(.horizontal, 50)
                .padding(.bottom, 30)
            }
            .foregroundColor(.white)
        }
    }
    
    // MARK: - Step Content Functions
    @ViewBuilder
    private func step1Content() -> some View {
        VStack(spacing: 20) {
            Image("ar_board_static_image")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 300)
            
            Text("This is your AR Mastermind board, where all the action happens!")
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    
    @ViewBuilder
    private func step2Content() -> some View {
        VStack(spacing: 20) {
            Text("Step 2: Guessing Slots")
                .font(.title)
                .padding(.bottom, 10)
            
            Image("guess_rows")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 300)
            
            Text("Place your guessed colors in these slots to test your combination.")
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Text("Once your guess row is ready, tap on green submit to get the feedback")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
    
    @ViewBuilder
    private func step3Content() -> some View {
        VStack(spacing: 20) {
            Text("Step 3: Color Selection Panel")
                .font(.title)
                .padding(.bottom, 10)
            
            Image("color_selection")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 300)
            
            Text("Tap a color to place it into the slots to make your guess.")
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    @ViewBuilder
    private func step4Content() -> some View {
        VStack(spacing: 20) {
            Text("Step 4: Feedback Pegs")
                .font(.title)
                .padding(.bottom, 10)
            
            Image("feedback_section")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 300)
            
            Text("After submitting your guess, these pegs will give clues:")
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            VStack(alignment: .leading) {
                Text("⚫️ Black peg: Right color, right position.")
                Text("⚪️ White peg: Right color, wrong position.")
                Text("   No peg: The color isn’t in the code.")
            }
            .font(.subheadline)
            .padding(.top, 10)
        }
    }
    
    @ViewBuilder
    private func step5Content() -> some View {
        VStack(spacing: 20) {
            Text("Step 5: Secret Code (Hidden Row)")
                .font(.title)
                .padding(.bottom, 10)
            
            Image("secret_code")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 300)
            
            Text("The secret code is hidden here. Your goal is to guess the correct colors and positions!")
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}
