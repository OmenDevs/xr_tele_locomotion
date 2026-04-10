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
                openWindow(id: "camera")
            }
            Button("Start Simulation") {
                Task {
                    await openImmersiveSpace(id: "simulation")
                    openWindow(id: "dashboard")
                    // openWindow(id: "log")
                }
            }
        }
    }
}

#Preview {
    LandingView()
}
