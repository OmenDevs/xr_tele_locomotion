//
//  RobotSimulatorViewModel.swift
//  Locomotion
//
//  Created by Julio Enrique Sanchez Guajardo on 27/03/26.
//

import Foundation

@Observable
class RobotSimulatorViewModel {

    private(set) var isSimulatorActive: Bool = true

    private var normalizedVelocityX: Double = 0.0
    private var normalizedVelocityY: Double = 0.0
    private var normalizedAngularVelocity: Double = 0.0

    var robotX: Double = 0.0 // meters
    var robotY: Double = 0.0 // meters
    var robotHeading: Double = 0.0 // radians

    private var velocityX: Double = 0.0       // m/s
    private var velocityY: Double = 0.0       // m/s
    private var angularVelocity: Double = 0.0 // rad/s

    let maxLinearSpeed: Double  = 3.0   // m/s
    let maxAngularSpeed: Double = 2.0   // rad/s

    func updateInputs(normalizedVelocityX: Double, normalizedVelocityY: Double, normalizedAngularVelocity: Double) {
        self.normalizedVelocityX = normalizedVelocityX
        self.normalizedVelocityY = normalizedVelocityY
        self.normalizedAngularVelocity = normalizedAngularVelocity
    }

    func update(deltaTime: TimeInterval) {
        guard
            isSimulatorActive,
            deltaTime > 0,
            normalizedVelocityX != 0.0 || normalizedVelocityY != 0.0 || normalizedAngularVelocity != 0.0
        else { return }

        let localVX = normalizedVelocityX * maxLinearSpeed
        let localVY = normalizedVelocityY * maxLinearSpeed
        angularVelocity = normalizedAngularVelocity * maxAngularSpeed

        velocityX = localVX * cos(robotHeading) - localVY * sin(robotHeading)
        velocityY = localVX * sin(robotHeading) + localVY * cos(robotHeading)

        robotX       += velocityX       * deltaTime
        robotY       += velocityY       * deltaTime
        let newHeading = robotHeading + angularVelocity * deltaTime
        robotHeading = atan2(sin(newHeading), cos(newHeading))
    }

    func setSimulatorActive(_ active: Bool) {
        isSimulatorActive = active
    }
}
