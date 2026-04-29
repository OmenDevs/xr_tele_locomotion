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
    @State private var POVSimulator = POVSimulatorViewModel()
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

            guard let scenarioEntity = try? await Entity(named: "MapMars", in: realityKitContentBundle) else { return }
            scenarioEntity.name = "scenarioEntity"
            content.add(scenarioEntity)

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
                guard let scenarioEntity = event.scene.findEntity(named: "scenarioEntity") else { return }
                let userPose = Transform(
                    rotation: simd_quatf(
                        angle: Float(POVSimulator.scenarioHeading),
                        axis: SIMD3<Float>(0, 1, 0)),
                    translation: SIMD3<Float>(
                        Float(POVSimulator.scenarioX),
                        0,
                        -Float(POVSimulator.scenarioY))
                )
                scenarioEntity.transform = Transform(matrix: userPose.matrix.inverse)

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
        POVSimulator.updateScenario(
            normalizedVelocityX: velocityX,
            normalizedVelocityY: velocityY,
            normalizedAngularVelocity: -angularVelocity,
            deltaTime: deltaTime)
    }
}

#Preview {
    SimulationView(recording: RecordingViewModel())
}
