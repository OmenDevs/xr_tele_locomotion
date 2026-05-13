//
//  POVSimulatorViewModel.swift
//  Locomotion
//
//  Created by Julio Enrique Sanchez Guajardo on 27/03/26.
//

import Foundation

/// Integrates normalized joystick/gesture inputs into a 2D world pose
/// (`scenarioX`, `scenarioY`, `scenarioHeading`) by scaling them with
/// `maxLinearSpeed` / `maxAngularSpeed` and stepping by `deltaTime`.
@Observable
class POVSimulatorViewModel {

    private(set) var isSimulatorActive: Bool = true

    private var normalizedVelocityX: Double = 0.0
    private var normalizedVelocityY: Double = 0.0
    private var normalizedAngularVelocity: Double = 0.0

    var scenarioX: Double = 0.0 // meters
    var scenarioY: Double = 0.0 // meters
    var scenarioHeading: Double = 0.0 // radians

    private var velocityX: Double = 0.0       // m/s
    private var velocityY: Double = 0.0       // m/s
    private var angularVelocity: Double = 0.0 // rad/s

    let maxLinearSpeed: Double  = 5.0   // m/s
    let maxAngularSpeed: Double = 0.5   // rad/s

    func updateScenario(normalizedVelocityX: Double,
                        normalizedVelocityY: Double,
                        normalizedAngularVelocity: Double,
                        deltaTime: TimeInterval) {
        updateInputs(normalizedVelocityX: normalizedVelocityX,
                     normalizedVelocityY: normalizedVelocityY,
                     normalizedAngularVelocity: normalizedAngularVelocity)
        update(deltaTime: deltaTime)
    }

    private func updateInputs(normalizedVelocityX: Double,
                              normalizedVelocityY: Double,
                              normalizedAngularVelocity: Double) {
        self.normalizedVelocityX = normalizedVelocityX
        self.normalizedVelocityY = normalizedVelocityY
        self.normalizedAngularVelocity = normalizedAngularVelocity
    }

    private func update(deltaTime: TimeInterval) {
        guard
            isSimulatorActive,
            deltaTime > 0,
            normalizedVelocityX != 0.0 || normalizedVelocityY != 0.0 || normalizedAngularVelocity != 0.0
        else { return }

        let localVX = normalizedVelocityX * maxLinearSpeed
        let localVY = normalizedVelocityY * maxLinearSpeed
        angularVelocity = normalizedAngularVelocity * maxAngularSpeed

        // Rotate body-frame velocity into the world frame by scenarioHeading.
        velocityX = localVX * cos(scenarioHeading) - localVY * sin(scenarioHeading)
        velocityY = localVX * sin(scenarioHeading) + localVY * cos(scenarioHeading)

        scenarioX       += velocityX       * deltaTime
        scenarioY       += velocityY       * deltaTime
        let newHeading = scenarioHeading + angularVelocity * deltaTime
        scenarioHeading = atan2(sin(newHeading), cos(newHeading))
    }

    func setSimulatorActive(_ active: Bool) {
        isSimulatorActive = active
    }
}
