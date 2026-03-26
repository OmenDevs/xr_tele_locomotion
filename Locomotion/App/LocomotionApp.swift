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
    @State private var recording = RecordingViewModel()

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
            SimulationView(recording: recording)
        }
        .windowStyle(.plain)

        WindowGroup(id: "dashboard") {
            DashboardView(recording: recording)
        }
        .windowStyle(.plain)

        WindowGroup(id: "log") {
            LogView(recording: recording)
        }
        .windowStyle(.plain)
    }
}
