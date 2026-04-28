//
//  SimulationView.swift
//  Locomotion
//
//  Created by Julio Enrique Sanchez Guajardo on 25/03/26.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct SimulationView: View {
    @Environment(\.openWindow) private var openWindow
    @State private var frameSubscription: EventSubscription?
    @State private var robotSimulator = RobotSimulatorViewModel()
    @Environment(InteractionConfig.self) private var interactionConfig

    @State private var handSkeletonProvider = HandSkeletonProvider()
    @Environment(HandSkeletonData.self) private var skeletonData

    // MARK: - Gesture-based interaction

    @State private var gestureInputState = GestureInputState()
    @State private var turnProcessor = TurnGestureProcessor()
    @State private var dragVisualizer = DragGestureVisualizer()
    @State private var pinchInput = PinchInputViewModel.shared

    var recording: RecordingViewModel

    var body: some View {
        RealityView { content in
            guard let robot = try? await Entity(named: "Mech_Drone", in: realityKitContentBundle) else { return }
            robot.name = "robot"
            robotSimulator.robotY = -1.0
            robot.position = SIMD3<Float>(0, 1, -1)
            for animation in robot.availableAnimations {
                robot.playAnimation(animation.repeat())
            }
            content.add(robot)
            switch interactionConfig.selectedInteraction {
            case .joystick2D:
                break
            case .joystick3D:
                handSkeletonProvider.skeletonData = skeletonData
                pinchInput.skeletonData = skeletonData
                Task { await handSkeletonProvider.start() }
            case .gestureBased:
                content.add(dragVisualizer.rootEntity)
                handSkeletonProvider.skeletonData = skeletonData
                Task { await handSkeletonProvider.start() }
            }

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
                switch interactionConfig.selectedInteraction {
                case .joystick2D:
                    break
                case .joystick3D:
                    pinchInput.update()
                case .gestureBased:
                    break
                }
            }

        }
    }

    func simulationTick(deltaTime: TimeInterval) {
        let velocityX: Double
        let velocityY: Double
        let angularVelocity: Double

        switch interactionConfig.selectedInteraction {
        case .gestureBased:
            // Run the turn gesture processor.
            turnProcessor.update(skeletonData: skeletonData, state: gestureInputState)

            GestureInputViewModel.shared.update(skeletonData: skeletonData, state: gestureInputState)

            if gestureInputState.isActive,
               let dragOrigin = GestureInputViewModel.shared.dragOrigin,
               let cursor = GestureInputViewModel.shared.cursorPoint {
                dragVisualizer.update(with: DragVisualizerState(
                    origin: dragOrigin,
                    cursor: cursor,
                    normalizedTurnAngle: gestureInputState.normalizedTurnAngle
                ))
            } else {
                dragVisualizer.hide()
            }

            velocityX = gestureInputState.velocityX
            velocityY = gestureInputState.velocityY
            angularVelocity = gestureInputState.angularVelocity

        case .joystick2D, .joystick3D:
            velocityX = InputViewModel.shared.velocityX
            velocityY = InputViewModel.shared.velocityY
            angularVelocity = InputViewModel.shared.angularVelocity
        }

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
