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
    @State private var povSimulator = POVSimulatorViewModel()

    var body: some Scene {
        WindowGroup(id: "landing") {
            LandingView()
                .environment(client)
                .environment(interactionConfig)
        }
        .defaultSize(width: 1000, height: 700)

        WindowGroup(id: "camera") {
            CameraView()
                .environment(client)
                .environment(interactionConfig)
        }
        .defaultSize(width: 1280, height: 720)

        ImmersiveSpace(id: "teleoperation") {
            TeleoperationView()
                .environment(client)
                .environment(interactionConfig)
                .environment(skeletonData)
        }

        ImmersiveSpace(id: "simulation") {
            SimulationView(recording: recording)
                .environment(interactionConfig)
                .environment(skeletonData)
                .environment(povSimulator)
        }

        WindowGroup(id: "portal") {
            PortalWindowView()
                .environment(povSimulator)
                .environment(interactionConfig)
        }
        .windowStyle(.plain)
        .defaultSize(width: 1280, height: 720)

        WindowGroup(id: "dashboard") {
            DashboardView(recording: recording)
        }
        .windowStyle(.plain)
        .defaultWindowPlacement { _, context in
            if let mainWindow = context.windows.first {
                return WindowPlacement(.leading(mainWindow))
            }
            return WindowPlacement(.none)
        }

        WindowGroup(id: "joystick") {
            ControlPanelView(client: client)
                .environment(input)
        }
        .windowStyle(.plain)
        .defaultSize(width: 620, height: 400)
        .defaultWindowPlacement { _, _ in
            return WindowPlacement(.utilityPanel)
        }
    }
}
