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
    @State private var joystick3DViewModel = Joystick3DViewModel()
    @State private var sendTimer: Timer?
    @Environment(InteractionConfig.self) private var interactionConfig
    @Environment(RobotWebRTCClient.self) private var client
    @Environment(InputViewModel.self) private var input

    var body: some View {
        RealityView { content in
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
                }
            }
        }
        .joystick3DGesture(viewModel: joystick3DViewModel)
        .onChange(of: input.velocityX) { onVelocityChanged() }
        .onChange(of: input.velocityY) { onVelocityChanged() }
        .onChange(of: input.angularVelocity) { onVelocityChanged() }
        .onDisappear {
            sendTimer?.invalidate()
            sendTimer = nil
        }
    }

    // MARK: - Velocity Sending

    /// Throttled velocity sending via data channel (5 commands in 1 second while hold).
    private func onVelocityChanged() {
        guard interactionConfig.selectedInteraction == .joystick3D else { return }
        let isActive = input.velocityX != 0
            || input.velocityY != 0
            || input.angularVelocity != 0

        if isActive {
            guard sendTimer == nil else { return }
            sendVelocity()
            sendTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
                Task { @MainActor in
                    self.sendVelocity()
                }
            }
        } else {
            sendTimer?.invalidate()
            sendTimer = nil
            sendVelocity()
        }
    }

    private func sendVelocity() {
        client.sendVelocity(
            velocityX: input.velocityX,
            velocityY: input.velocityY,
            omega: input.angularVelocity
        )
    }
}

#Preview {
    TeleoperationView()
}
