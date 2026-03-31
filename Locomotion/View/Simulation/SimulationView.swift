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
    @State private var robotSimulator = RobotSimulatorViewModel()
    var recording: RecordingViewModel
    var body: some View {
        RealityView { content in
            let mesh = MeshResource.generateBox(size: 0.3)
            let material = SimpleMaterial(color: .cyan, roughness: 0.5, isMetallic: false)
            let robot = ModelEntity(mesh: mesh, materials: [material])
            robot.name = "robot"
            content.add(robot)

            frameSubscription = content.subscribe(to: SceneEvents.Update.self) { event in
                let deltaTime = event.deltaTime
                simulationTick(deltaTime: deltaTime)

                guard let robot = event.scene.findEntity(named: "robot") else { return }
                                robot.position = SIMD3<Float>(
                                    Float(robotSimulator.robotX),
                                    0,
                                    Float(robotSimulator.robotY)
                                )
                                robot.orientation = simd_quatf(
                                    angle: Float(-robotSimulator.robotHeading),
                                    axis: SIMD3<Float>(0, 1, 0)
                                )
            }

        }
    }
    func simulationTick(deltaTime: TimeInterval) {
        // TODO: Get normalize value x,y,w from protocol
        let xxx = 0.5
        let yyy = 0.2
        let www = -0.8
        recording.addTelemetryEntry(
            deltaTime: deltaTime,
            normalizedVelocityX: xxx,
            normalizedVelocityY: yyy,
            normalizedAngularVelocity: www)
        robotSimulator.updateInputs(
            normalizedVelocityX: xxx,
            normalizedVelocityY: yyy,
            normalizedAngularVelocity: www)
        robotSimulator.update(deltaTime: deltaTime)
    }
}

#Preview {
    SimulationView(recording: RecordingViewModel())
}
