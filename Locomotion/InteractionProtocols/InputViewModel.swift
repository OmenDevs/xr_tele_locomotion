//
//  InputViewModel.swift
//  Locomotion
//
//  Created by Bekhruzjon Hakmirzaev on 26/03/26.
//

import SwiftUI
import Observation

/// Observable source of truth for joystick input → normalized velocities.
///
/// Produce `velocityX`, `velocityY`, `angularVelocity` from joystick input.
@Observable @MainActor
final class InputViewModel {

    static let shared = InputViewModel()

    // MARK: - Joystick raw inputs  (-1 … +1)

    var leftStickX: Double = 0.0   // lateral
    var leftStickY: Double = 0.0   // forward / backward
    var rightStickX: Double = 0.0   // angular rotation

    // MARK: - Normalized output velocities

    /// Linear velocity along X axis (m/s).
    var velocityX: Double { leftStickX }

    /// Linear velocity along Y axis (m/s).
    var velocityY: Double { leftStickY }

    /// Angular velocity ω (rad/s).
    var angularVelocity: Double { rightStickX }

    // MARK: - Reset

    func reset() {
        leftStickX = 0
        leftStickY = 0
        rightStickX = 0
    }
}
