import RealityKit

struct ColorPegComponent: Component {
    let color: MastermindGameState.Color
}

struct GuessSlotComponent: Component {
    let row: Int
    let column: Int
}

struct SubmitButtonComponent: Component {}

struct FeedbackPegComponent: Component {
    let row: Int
    let index: Int
}

struct SecretCodeSlotComponent: Component {
    let column: Int
}
