import SwiftUI
import RealityKit

struct TeleoperationView: View {
    @State private var frameSubscription: EventSubscription?
    @Environment(RobotWebRTCClient.self) private var client
    @Environment(InteractionConfig.self) private var interactionConfig
    @Environment(HandSkeletonData.self) private var skeletonData

    // MARK: - Gesture-based interaction

    @State private var handSkeletonProvider = HandSkeletonProvider()

    @State private var devicePoseProvider = DevicePoseProvider()
    @State private var turnProcessor = TurnGestureProcessor()
    @State private var dragVisualizer = DragGestureVisualizer()

    // MARK: - Throttling for velocity sending

    @State private var lastSendTime: TimeInterval = 0
    private let sendInterval: TimeInterval = 0.2

    var body: some View {
        RealityView { content in
            content.add(dragVisualizer.rootEntity)

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
                teleoperationTick(deltaTime: deltaTime)
            }
        }
        .overlay { interactionOverlay }
    }

    private func teleoperationTick(deltaTime: TimeInterval) {
        switch interactionConfig.selectedInteraction {
        case .joystick2D:
            return
        case .joystick3D:
            break
        case .gestureBased:
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

        // Shared continuous send for joystick3D and gestureBased.
        lastSendTime += deltaTime
        guard lastSendTime >= sendInterval else { return }
        lastSendTime = 0

        client.sendVelocity(
            velocityX: InputViewModel.shared.velocityX,
            velocityY: InputViewModel.shared.velocityY,
            angularVelocity: InputViewModel.shared.angularVelocity
        )
    }
}

// MARK: - Overlays

extension TeleoperationView {
    @ViewBuilder
    var interactionOverlay: some View {
        if interactionConfig.selectedInteraction == .joystick3D {
            Joystick3DView()
        }
    }
}

#Preview {
    TeleoperationView()
}
