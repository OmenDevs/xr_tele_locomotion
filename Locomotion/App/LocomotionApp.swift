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
    @State private var recording = RecordingViewModel()
    @State private var interactionConfig = InteractionConfig()
    @State private var skeletonData = HandSkeletonData()

    var body: some Scene {
        WindowGroup(id: "landing") {
            LandingView()
                .environment(interactionConfig)
        }
        .windowStyle(.plain)

        WindowGroup(id: "camera") {
            CameraView()
                .environment(client)
                .environment(interactionConfig)
        }
        .defaultSize(width: 1280, height: 720)

        WindowGroup(id: "controls") {
            PanelView()
                .environment(client)
        }
        .defaultSize(width: 250, height: 280)

        ImmersiveSpace(id: "teleoperation") {
            TeleoperationView()
                .environment(interactionConfig)
                .environment(skeletonData)
        }

        ImmersiveSpace(id: "simulation") {
            SimulationView(recording: recording)
                .environment(interactionConfig)
                .environment(skeletonData)
        }

        WindowGroup(id: "dashboard") {
            DashboardView(recording: recording)
        }
        .windowStyle(.plain)

        WindowGroup(id: "log") {
            LogView(recording: recording)
        }
        .windowStyle(.plain)

        WindowGroup(id: "joystick") {
            ControlPanelView(client: client)
                .environment(input)
        }
        .windowStyle(.plain)
        .defaultSize(width: 620, height: 400)

        ImmersiveSpace(id: "pinchTest") {
            PinchTestView()
        }
    }
}
