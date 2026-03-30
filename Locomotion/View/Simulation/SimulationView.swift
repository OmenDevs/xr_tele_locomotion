//
//  SimulationView.swift
//  Locomotion
//
//  Created by Julio Enrique Sanchez Guajardo on 25/03/26.
//

import SwiftUI
import RealityKit
import Combine

struct SimulationView: View {
    @Environment(\.openWindow) private var openWindow
    @State private var frameSubscription: EventSubscription?

    var body: some View {
        RealityView { content in
            frameSubscription = content.subscribe(to: SceneEvents.Update.self) { event in
                let deltaTime = event.deltaTime
                simulationTick(deltaTime: deltaTime)
            }
        }
        .onAppear {
            openWindow(id: "joystick")
        }
    }
    func simulationTick(deltaTime: TimeInterval) {
        // TODO: Get normalize value x,y,w from protocol
        let velocityX = InputViewModel.shared.velocityX
        let velocityY = InputViewModel.shared.velocityY
        let angularVelocity = InputViewModel.shared.angularVelocity
        
        // TODO: Save value x,y,w
        // TODO: Give value to the simulator
    }
}

#Preview {
    SimulationView()
}
