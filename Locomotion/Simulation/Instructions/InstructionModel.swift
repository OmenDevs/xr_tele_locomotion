import Foundation

enum InstructionCompletion {
    case pinch
    case moveForward
    case moveBackward
    case moveSideways
    case rotateRight
    case rotateLeft
}

struct Instruction: Identifiable {
    let id = UUID()
    let text: String
    let video: String?
    let completion: InstructionCompletion
}
