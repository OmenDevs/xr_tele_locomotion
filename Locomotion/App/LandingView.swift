//
//  LandingView.swift
//  Locomotion
//
//  Created by Julio Enrique Sanchez Guajardo on 25/03/26.
//

import SwiftUI

struct LandingView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(InteractionConfig.self) private var interactionConfig
    @Environment(RobotWebRTCClient.self) private var client

    @State private var immersiveSpaceIsShown = false

    var body: some View {
        @Bindable var interactionConfig = interactionConfig
        @Bindable var client = client
        VStack(spacing: 32) {
            Text("What would you like to do?")
                .font(.system(size: 43, weight: .bold))
                .foregroundStyle(.white)
                .padding(.top, 48)
            HStack(spacing: 24) {
                Button {
                    Task {
                        await dismissImmersiveSpace()
                        await openSimulation()
                    }
                } label: {
                    ZStack(alignment: .bottomLeading) {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.regularMaterial)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Simulator")
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                            Text("Test the interaction protocol in a simulation environment")
                                .font(.body)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .padding(24)
                    }
                    .frame(width: 400, height: 320)
                    .contentShape(.hoverEffect, RoundedRectangle(cornerRadius: 20))
                    .hoverEffect()
                }
                .buttonStyle(.plain)

                Button {
                    Task {
                        await dismissImmersiveSpace()
                        await openRobotControl()
                    }
                } label: {
                    ZStack(alignment: .bottomLeading) {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.regularMaterial)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Connect the Robot")
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                            Text("Connect your robot to control its locomotion")
                                .font(.body)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .padding(24)
                    }
                    .frame(width: 400, height: 320)
                    .contentShape(.hoverEffect, .rect(cornerRadius: 20))
                    .hoverEffect()
                }
                .buttonStyle(.plain)
            }
            Picker("Interaction", selection: $interactionConfig.selectedInteraction) {
                ForEach(InteractionProtocol.allCases) { interaction in
                    Text(interaction.rawValue).tag(interaction)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 480)
        }
        .padding(.horizontal, 60)
    }

    private func openRobotControl() async {
        openWindow(id: "camera")
        if immersiveSpaceIsShown {
            await dismissImmersiveSpace()
            immersiveSpaceIsShown = false
        }
        switch await openImmersiveSpace(id: "teleoperation") {
        case .opened: immersiveSpaceIsShown = true
        default: break
        }
        if interactionConfig.selectedInteraction == .joystick2D {
            openWindow(id: "joystick")
        }
        dismissWindow(id: "landing")
    }

    private func openSimulation() async {
        openWindow(id: "dashboard")
        openWindow(id: "portal")
        if immersiveSpaceIsShown {
            await dismissImmersiveSpace()
            immersiveSpaceIsShown = false
        }
        switch await openImmersiveSpace(id: "simulation") {
        case .opened: immersiveSpaceIsShown = true
        default: break
        }
        if interactionConfig.selectedInteraction == .joystick2D {
            openWindow(id: "joystick")
        }
        dismissWindow(id: "landing")
    }
}
