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

    @State private var immersiveSpaceIsShown = false

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
            if immersiveSpaceIsShown {
                await dismissImmersiveSpace()
                immersiveSpaceIsShown = false
            }
            switch await openImmersiveSpace(id: "teleoperation") {
            case .opened: immersiveSpaceIsShown = true
            default: break
            }
        }
    }
    // NOTE: don't add new interaction protocols thought here, only if are WindowsGroups,
    // Inmersive protocolos need to be added inside simulationView(). For more information: Julio
    private func openSimulation() async {
        if immersiveSpaceIsShown {
            await dismissImmersiveSpace()
            immersiveSpaceIsShown = false
        }
        switch await openImmersiveSpace(id: "simulation") {
        case .opened: immersiveSpaceIsShown = true
        default: break
        }
        openWindow(id: "dashboard")
        if interactionConfig.selectedInteraction == InteractionProtocol.joystick2D {
            openWindow(id: "joystick")
        }
    }
}

#Preview {
    LandingView()
}
