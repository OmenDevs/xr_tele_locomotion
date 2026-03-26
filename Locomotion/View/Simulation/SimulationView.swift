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
    @State private var frameSubscription: EventSubscription?
    var body: some View {
        RealityView { content in
            frameSubscription = content.subscribe(to: SceneEvents.Update.self) { event in
                let deltaTime = event.deltaTime
                simulationTick(deltaTime: deltaTime)
            }
        }
    }
    func simulationTick(deltaTime: TimeInterval) {
        print(deltaTime)
        // TODO: Get normalize value x,y,w from protocol
        // TODO: Save value x,y,w
        // TODO: Give value to the simulator
    }
}

#Preview {
    SimulationView()
}
