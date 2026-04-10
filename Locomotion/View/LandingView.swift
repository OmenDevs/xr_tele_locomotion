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
    @Environment(InteractionConfig.self) private var interactionConfig

    var body: some View {
        @Bindable var interactionConfig = interactionConfig
        Picker("Interaction", selection: $interactionConfig.selectedInteraction) {
            ForEach(InteractionProtocol.allCases) { interaction in
                       Text(interaction.rawValue)
                           .tag(interaction)
                   }
               }
        HStack {
            Button("Start RobotControl") {
                Task { await openRobotControl() }
            }
            Button("Start Simulation") {
                Task { await openSimulation() }
            }
        }
    }
    // NOTE: don't add new interaction protocols thought here, only if are WindowsGroups,
    // Inmersive protocolos need to be added inside TeleoperationView(). For more information: Julio
    private func openRobotControl() async {
        openWindow(id: "camera")
        if interactionConfig.selectedInteraction == InteractionProtocol.joystick2D {
            openWindow(id: "joystick")
        } else {
            await openImmersiveSpace(id: "teleoperation")
        }
    }
    // NOTE: don't add new interaction protocols thought here, only if are WindowsGroups,
    // Inmersive protocolos need to be added inside simulationView(). For more information: Julio
    private func openSimulation() async {
        await openImmersiveSpace(id: "simulation")
        openWindow(id: "dashboard")
        if interactionConfig.selectedInteraction == InteractionProtocol.joystick2D {
            openWindow(id: "joystick")
        }
    }
}

#Preview {
    LandingView()
}
