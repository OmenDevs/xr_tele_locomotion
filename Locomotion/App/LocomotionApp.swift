//
//  LocomotionApp.swift
//  Locomotion
//
//  Created by Can Dindar on 18/02/26.
//

import SwiftUI

@main
struct LocomotionApp: App {
    @State private var client = RobotWebRTCClient()
    @State private var input = InputViewModel.shared

    var body: some Scene {
        WindowGroup(id: "landing") {
            LandingView()
        }
        .windowStyle(.plain)

        WindowGroup(id: "camera") {
            CameraView()
                .environment(client)
        }
        .defaultSize(width: 1280, height: 720)

        WindowGroup(id: "controls") {
            PanelView()
                .environment(client)
        }
        .defaultSize(width: 250, height: 280)

        WindowGroup(id: "simulation") {
            SimulationView()
        }
        .windowStyle(.plain)

        WindowGroup(id: "joystick") {
            ControlPanelView()
                .environment(input)
        }
        .windowStyle(.plain)
        .defaultSize(width: 620, height: 400)
    }
}
