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
    @State private var devicePoseProvider = DevicePoseProvider()
    @Environment(HandSkeletonData.self) private var skeletonData

    // MARK: - Gesture-based interaction

    @State private var turnProcessor = TurnGestureProcessor()
    @State private var dragVisualizer = DragGestureVisualizer()

    var recording: RecordingViewModel

    var body: some View {
        RealityView { content in
            let rootEntity = Entity()
            content.add(rootEntity)

            let portalContentRoot = Entity()
            portalContentRoot.components.set(WorldComponent())
            rootEntity.addChild(portalContentRoot)

            let portalEntity = ModelEntity(
                mesh: .generatePlane(width: 1.0, height: 0.6, cornerRadius: 0.03),
                materials: [PortalMaterial()]
            )
            portalEntity.position = SIMD3<Float>(0, 1, -1)
            portalEntity.components.set(PortalComponent(target: portalContentRoot))
            rootEntity.addChild(portalEntity)

            guard let scenarioEntity = try? await Entity(named: "MapMars", in: realityKitContentBundle) else { return }
            scenarioEntity.name = "scenarioEntity"
            portalContentRoot.addChild(scenarioEntity)

            switch interactionConfig.selectedInteraction {
            case .joystick2D:
                break
            case .joystick3D:
                break
            case .gestureBased:
                content.add(dragVisualizer.rootEntity)
                handSkeletonProvider.skeletonData = skeletonData
                Task { await handSkeletonProvider.start() }
                Task { await devicePoseProvider.start() }
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
        .overlay { interactionOverlay }
    }

    func simulationTick(deltaTime: TimeInterval) {
        if interactionConfig.selectedInteraction == .gestureBased {
            turnProcessor.update(skeletonData: skeletonData, state: InputViewModel.shared)
            GestureInputViewModel.shared.update(
                skeletonData: skeletonData,
                headTransform: devicePoseProvider.currentDeviceTransform(),
                state: InputViewModel.shared
            )

            if InputViewModel.shared.isActive,
               let dragOrigin = GestureInputViewModel.shared.dragOrigin,
               let cursor = GestureInputViewModel.shared.cursorPoint {
                dragVisualizer.update(with: DragVisualizerState(
                    origin: dragOrigin,
                    cursor: cursor,
                    yaw: GestureInputViewModel.shared.frozenYaw ?? 0,
                    normalizedTurnAngle: InputViewModel.shared.angularVelocity
                ))
            } else {
                dragVisualizer.hide()
            }
        }

        recording.addTelemetryEntry(
            deltaTime: deltaTime,
            normalizedVelocityX: InputViewModel.shared.velocityX,
            normalizedVelocityY: InputViewModel.shared.velocityY,
            normalizedAngularVelocity: InputViewModel.shared.angularVelocity)
        robotSimulator.updateInputs(
            normalizedVelocityX: InputViewModel.shared.velocityX,
            normalizedVelocityY: -InputViewModel.shared.velocityY,
            normalizedAngularVelocity: InputViewModel.shared.angularVelocity)
        robotSimulator.update(deltaTime: deltaTime)
    }
}

extension SimulationView {
    @ViewBuilder
    var interactionOverlay: some View {
        if interactionConfig.selectedInteraction == .joystick3D {
            Joystick3DView()
        }
    }
}

#Preview {
    SimulationView(recording: RecordingViewModel())
}
