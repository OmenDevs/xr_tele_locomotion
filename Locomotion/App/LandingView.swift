//
//  LandingView.swift
//  Locomotion
//
//  Created by Julio Enrique Sanchez Guajardo on 25/03/26.
//

import SwiftUI

struct LandingView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(InteractionConfig.self) private var interactionConfig
    @Environment(RobotWebRTCClient.self) private var client

    @State private var immersiveSpaceIsShown = false

    var body: some View {
        @Bindable var interactionConfig = interactionConfig
        @Bindable var client = client

        // Server address input for connecting to the robot
        TextField("Server address (e.g. https:" + "//192.168.1.10:8000/offer)", text: $client.serverURL)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .frame(width: 500)
                    .glassBackgroundEffect()
                    .padding()

        Picker("Interaction", selection: $interactionConfig.selectedInteraction) {
            ForEach(InteractionProtocol.allCases) { interaction in
                Text(interaction.rawValue)
                    .tag(interaction)
            }
        }.padding(.bottom)

        HStack {
            Button("Start RobotControl") {
                Task {
                    await dismissImmersiveSpace()
                    await openRobotControl()
                }
            }
            .disabled(client.serverURL.isEmpty)

            Button("Start Simulation") {
                Task {
                    await dismissImmersiveSpace()
                    await openSimulation()
                }
            }
        }
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
    }

    private func openSimulation() async {
        openWindow(id: "dashboard")
        if immersiveSpaceIsShown {
            await dismissImmersiveSpace()
            immersiveSpaceIsShown = false
        }
        switch await openImmersiveSpace(id: "simulation") {
        case .opened: immersiveSpaceIsShown = true
        default: break
        }
        openWindow(id: "portal")
        openWindow(id: "dashboard")
        if interactionConfig.selectedInteraction == InteractionProtocol.joystick2D {
            openWindow(id: "joystick")
        }
    }
}
