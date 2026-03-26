//
//  SimulationView.swift
//  Locomotion
//
//  Created by Julio Enrique Sanchez Guajardo on 25/03/26.
//

import SwiftUI
import RealityKit

struct SimulationView: View {
    @State private var frameSubscription: EventSubscription?
    @State private var recording = RecordingViewModel()
    var body: some View {
        RealityView { content in
            frameSubscription = content.subscribe(to: SceneEvents.Update.self) { event in
                let deltaTime = event.deltaTime
                simulationTick(deltaTime: deltaTime)
            }
        }
    }
    func simulationTick(deltaTime: TimeInterval) {
        // TODO: Get normalize value x,y,w from protocol
        let xxx = 0.0
        let yyy = 0.0
        let www = 0.0
        recording.addTelemetryEntry(
            deltaTime: deltaTime,
            normalizedVelocityX: xxx,
            normalizedVelocityY: yyy,
            normalizedAngularVelocity: www)
        // TODO: Give value to the simulator
    }
}

#Preview {
    SimulationView()
}
