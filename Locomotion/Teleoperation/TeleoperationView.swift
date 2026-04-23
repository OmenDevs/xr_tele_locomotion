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
    @Environment(InteractionConfig.self) private var interactionConfig
    @Environment(HandSkeletonData.self) private var skeletonData

    // MARK: - Gesture-based interaction

    @State private var handSkeletonProvider = HandSkeletonProvider()
    @State private var gestureInputState = GestureInputState()
    @State private var turnProcessor = TurnGestureProcessor()
    @State private var turnVisualizer = TurnGestureVisualizer()

    // MARK: - Throttling for velocity sending

    @State private var lastSendTime: TimeInterval = 0
    private let sendInterval: TimeInterval = 0.2

    // Track previous values to send final zero on release.
    @State private var previouslyActive: Bool = false

    var body: some View {
        RealityView { content in
            // Add gesture visualizer root to the scene.
            content.add(turnVisualizer.rootEntity)

            // Start hand tracking when gesture-based is selected.
            if interactionConfig.selectedInteraction == .gestureBased {
                handSkeletonProvider.skeletonData = skeletonData
                Task { await handSkeletonProvider.start() }
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

        // Run the turn gesture processor.
        turnProcessor.update(skeletonData: skeletonData, state: gestureInputState)

        // Update visualization.
        if gestureInputState.isActive,
           let refDir = turnProcessor.currentReferenceDirection,
           let curDir = turnProcessor.currentFingerDirection {
            turnVisualizer.update(with: TurnVisualizerState(
                origin: turnProcessor.axisOrigin,
                axis: turnProcessor.axisDirection,
                referenceDir: refDir,
                currentDir: curDir
            ))
        } else {
            turnVisualizer.hide()
        }

        // Check if we just released — send one final zero.
        if previouslyActive && !gestureInputState.isActive {
            previouslyActive = false
            // TODO: Send final zero velocity via WebRTC.
            // client.sendVelocity(velocityX: 0, velocityY: 0, omega: 0)
            return
        }
        previouslyActive = gestureInputState.isActive

        guard gestureInputState.isActive else { return }

        // Throttle: only send at sendInterval (10 Hz).
        lastSendTime += deltaTime
        guard lastSendTime >= sendInterval else { return }
        lastSendTime = 0

        let velX = gestureInputState.velocityX
        let velY = gestureInputState.velocityY
        let omega = gestureInputState.angularVelocity

        // TODO: Uncomment when RobotWebRTCClient is injected.
        // client.sendVelocity(velocityX: velX, velocityY: velY, omega: omega)
        print("🤖 Gesture → vx: \(String(format: "%.2f", velX)),"
              + " vy: \(String(format: "%.2f", velY)),"
              + " ω: \(String(format: "%.2f", omega))")
    }
}

#Preview {
    TeleoperationView()
}
