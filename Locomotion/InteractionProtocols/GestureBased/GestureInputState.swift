//
//  GestureInputState.swift
//  Locomotion
//
//  Created by Bekhruzjon Hakmirzaev on 23/04/26.
//

import Foundation

/// Which hand is currently driving the gesture.
enum ActiveHand {
    case none, left, right
}

/// Observable source of truth for gesture-based input → normalized velocities.
///
/// Mirrors `InputViewModel` for joystick, but for gesture-based control.
/// Produces `velocityX`, `velocityY`, `angularVelocity` from gesture processors.
@Observable @MainActor
final class GestureInputState {

    // MARK: - Activation

    /// Whether any gesture is currently active (pinch held).
    var isActive: Bool = false

    /// Which hand activated first and is driving the gesture.
    var activeHand: ActiveHand = .none

    // MARK: - Drag-based movement (future — populated by drag processor)

    /// Lateral movement, normalized -1…+1.
    var dragX: Double = 0.0

    /// Forward/backward movement, normalized -1…+1.
    var dragY: Double = 0.0

    // MARK: - Turn angle

    /// Turn angle normalized to -1…+1.  Populated by `TurnGestureProcessor`.
    var normalizedTurnAngle: Double = 0.0

    // MARK: - Normalized output velocities (convenience for pipeline)

    /// Linear velocity along X axis (normalized).
    var velocityX: Double { dragX }

    /// Linear velocity along Y axis (normalized).
    var velocityY: Double { dragY }

    /// Angular velocity ω (normalized -1…+1).
    var angularVelocity: Double { normalizedTurnAngle }

    // MARK: - Reset

    func reset() {
        isActive = false
        activeHand = .none
        dragX = 0.0
        dragY = 0.0
        normalizedTurnAngle = 0.0
    }
}
