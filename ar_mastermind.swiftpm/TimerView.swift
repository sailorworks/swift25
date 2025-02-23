import SwiftUI

struct TimerView: View {
    let seconds: Int
    
    var body: some View {
        Text(String(format: "%02d:%02d", (seconds % 3600) / 60, seconds % 60))
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(.white)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.brown)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.yellow, lineWidth: 2)
                    )
            )
    }
}
