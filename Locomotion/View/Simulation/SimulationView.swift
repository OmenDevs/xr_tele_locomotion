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
    @State private var joystick3DViewModel = Joystick3DViewModel()
    @Environment(InteractionConfig.self) private var interactionConfig
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

            if interactionConfig.selectedInteraction == .joystick3D {
                await Joystick3DContent.addJoysticks(to: content, viewModel: joystick3DViewModel)
            }

            frameSubscription = content.subscribe(to: SceneEvents.Update.self) { event in
                let deltaTime = event.deltaTime
                Task { @MainActor in
                    if self.interactionConfig.selectedInteraction == .joystick3D {
                        Joystick3DContent.handleFrameUpdate(
                            scene: event.scene,
                            deltaTime: deltaTime,
                            viewModel: self.joystick3DViewModel
                        )
                    }
                    self.simulationTick(deltaTime: deltaTime)
                    guard let robot = event.scene.findEntity(named: "robot") else { return }
                    robot.position = SIMD3<Float>(
                        Float(self.robotSimulator.robotX),
                        1,
                        Float(self.robotSimulator.robotY)
                    )
                    robot.orientation = simd_quatf(
                        angle: Float(-self.robotSimulator.robotHeading),
                        axis: SIMD3<Float>(0, 1, 0)
                    )
                }
            }
        }
        .joystick3DGesture(viewModel: joystick3DViewModel)
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
