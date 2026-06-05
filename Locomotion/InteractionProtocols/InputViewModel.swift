import SwiftUI
import Observation

enum ActiveHand {
    case none, left, right
}

/// Observable source of truth for input → normalized velocities.
/// Shared by joystick (2D/3D) and gesture-based interaction protocols.
@Observable @MainActor
final class InputViewModel {

    static let shared = InputViewModel()

    // MARK: - Gesture activation (gesture-based protocol only)

    var isActive: Bool = false
    var activeHand: ActiveHand = .none

    // MARK: - Normalized output velocities (-1…+1)

    var velocityX: Double = 0.0
    var velocityY: Double = 0.0
    var angularVelocity: Double = 0.0

    // MARK: - Reset

    func reset() {
        isActive = false
        activeHand = .none
        velocityX = 0.0
        velocityY = 0.0
        angularVelocity = 0.0
    }
}
