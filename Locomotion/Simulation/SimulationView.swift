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
    @State private var frameSubscription: EventSubscription?
    @Environment(POVSimulatorViewModel.self) private var povSimulator
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
                simulationTick(deltaTime: event.deltaTime)
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
        povSimulator.updateScenario(
            normalizedVelocityX: InputViewModel.shared.velocityX,
            normalizedVelocityY: InputViewModel.shared.velocityY,
            normalizedAngularVelocity: -InputViewModel.shared.angularVelocity,
            deltaTime: deltaTime)
    }
    /// Recursively replaces every ``PhysicallyBasedMaterial`` on `entity` and
    /// its descendants with an ``UnlitMaterial`` carrying the same base color
    /// and texture, so the scene renders without lighting inside the portal.
    @MainActor
    private func makeUnlit(_ entity: Entity) {
        if let model = entity as? ModelEntity, var component = model.model {
            component.materials = component.materials.map { mat in
                guard let pbr = mat as? PhysicallyBasedMaterial else { return mat }
                var unlit = UnlitMaterial()
                unlit.color = .init(tint: pbr.baseColor.tint, texture: pbr.baseColor.texture)
                return unlit
            }
            model.model = component
        }
        for child in entity.children {
            makeUnlit(child)
        }
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
