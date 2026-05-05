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
                Task {
                    await dismissImmersiveSpace()
                    await openRobotControl()
                }
            }
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
