//
//  SimulationView.swift
//  Locomotion
//
//  Created by Julio Enrique Sanchez Guajardo on 25/03/26.
//

import SwiftUI
import RealityKit

struct SimulationView: View {
    @Environment(\.openWindow) private var openWindow
    @State private var frameSubscription: EventSubscription?
    @State private var robotSimulator = RobotSimulatorViewModel()
    @Environment(InteractionConfig.self) private var interactionConfig

    @State private var handSkeletonProvider = HandSkeletonProvider()
    @Environment(HandSkeletonData.self) private var skeletonData

    var recording: RecordingViewModel

    var body: some View {
        RealityView { content in
            guard let robot = try? await Entity(named: "Mech_Drone", in: Bundle.main) else { return }
            robot.name = "robot"
            robotSimulator.robotY = -1.0
            robot.position = SIMD3<Float>(0, 1, -1)
            for animation in robot.availableAnimations {
                robot.playAnimation(animation.repeat())
            }
            content.add(robot)

            handSkeletonProvider.skeletonData = skeletonData
            Task { await handSkeletonProvider.start() }

            frameSubscription = content.subscribe(to: SceneEvents.Update.self) { event in
                let deltaTime = event.deltaTime
                simulationTick(deltaTime: deltaTime)

                guard let robot = event.scene.findEntity(named: "robot") else { return }
                                robot.position = SIMD3<Float>(
                                    Float(robotSimulator.robotX),
                                    1,
                                    Float(robotSimulator.robotY)
                                )
                                robot.orientation = simd_quatf(
                                    angle: Float(-robotSimulator.robotHeading),
                                    axis: SIMD3<Float>(0, 1, 0)
                                )
            }

        }
    }
    func simulationTick(deltaTime: TimeInterval) {
        let velocityX = InputViewModel.shared.velocityX
        let velocityY = InputViewModel.shared.velocityY
        let angularVelocity = InputViewModel.shared.angularVelocity

        recording.addTelemetryEntry(
            deltaTime: deltaTime,
            normalizedVelocityX: velocityX,
            normalizedVelocityY: velocityY,
            normalizedAngularVelocity: angularVelocity)
        robotSimulator.updateInputs(
            normalizedVelocityX: velocityX,
            normalizedVelocityY: -velocityY,
            normalizedAngularVelocity: angularVelocity)
        robotSimulator.update(deltaTime: deltaTime)
    }
}

#Preview {
    SimulationView(recording: RecordingViewModel())
}
