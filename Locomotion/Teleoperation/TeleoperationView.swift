//
//  TeleoperationView.swift
//  Locomotion
//
//  Created by Julio Enrique Sanchez Guajardo on 10/04/26.
//

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
    @State private var gestureInputState = GestureInputState()
    @State private var turnProcessor = TurnGestureProcessor()
    @State private var dragVisualizer = DragGestureVisualizer()

    // MARK: - Throttling for velocity sending

    @State private var lastSendTime: TimeInterval = 0
    private let sendInterval: TimeInterval = 0.2

    // Track previous values to send final zero on release.
    @State private var previouslyActive: Bool = false

    var body: some View {
        RealityView { content in
            content.add(dragVisualizer.rootEntity)

            // Start hand tracking when gesture-based is selected.
            if interactionConfig.selectedInteraction == .gestureBased {
                handSkeletonProvider.skeletonData = skeletonData
                Task { await handSkeletonProvider.start() }
                Task { await devicePoseProvider.start() }
            }

            frameSubscription = content.subscribe(to: SceneEvents.Update.self) { event in
                let deltaTime = event.deltaTime
                teleoperationTick(deltaTime: deltaTime)
            }
        }
    }

    private func teleoperationTick(deltaTime: TimeInterval) {
        guard interactionConfig.selectedInteraction == .gestureBased else {
            // Joystick modes: velocity is sent by ControlPanelView.
            return
        }

        // Run both gesture processors. The first-pinch-wins lock in each
        // converges on the same hand so drag and turn share an active hand.
        turnProcessor.update(skeletonData: skeletonData, state: gestureInputState)
        GestureInputViewModel.shared.update(
            skeletonData: skeletonData,
            headTransform: devicePoseProvider.currentDeviceTransform(),
            state: gestureInputState
        )

        if gestureInputState.isActive,
           let dragOrigin = GestureInputViewModel.shared.dragOrigin,
           let cursor = GestureInputViewModel.shared.cursorPoint {
            dragVisualizer.update(with: DragVisualizerState(
                origin: dragOrigin,
                cursor: cursor,
                yaw: GestureInputViewModel.shared.frozenYaw ?? 0,
                normalizedTurnAngle: gestureInputState.normalizedTurnAngle
            ))
        } else {
            dragVisualizer.hide()
        }

        if previouslyActive && !gestureInputState.isActive {
            previouslyActive = false
            client.sendVelocity(velocityX: 0, velocityY: 0, omega: 0)
            return
        }
        previouslyActive = gestureInputState.isActive

        guard gestureInputState.isActive else { return }

        lastSendTime += deltaTime
        guard lastSendTime >= sendInterval else { return }
        lastSendTime = 0

        client.sendVelocity(
            velocityX: gestureInputState.velocityX,
            velocityY: gestureInputState.velocityY,
            omega: gestureInputState.angularVelocity
        )
    }
}

#Preview {
    TeleoperationView()
}
