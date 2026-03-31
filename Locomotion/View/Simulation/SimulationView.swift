//
//  SimulationView.swift
//  Locomotion
//
//  Created by Julio Enrique Sanchez Guajardo on 25/03/26.
//

import SwiftUI
import RealityKit

struct SimulationView: View {
    @Environment(\.openWindow) private var openWindow
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
        recording.addTelemetryEntry(
            deltaTime: deltaTime,
            normalizedVelocityX: velocityX,
            normalizedVelocityY: velocityY,
            normalizedAngularVelocity: angularVelocity)
        robotSimulator.updateInputs(
            normalizedVelocityX: velocityX,
            normalizedVelocityY: velocityY,
            normalizedAngularVelocity: angularVelocity)
        robotSimulator.update(deltaTime: deltaTime)
    }
}

#Preview {
    SimulationView(recording: RecordingViewModel())
}
