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

    var body: some Scene {
        #if os(visionOS)
        // visionOS: two separate, independently movable windows
        WindowGroup(id: "camera") {
            CameraView()
                .environment(client)
        }

        WindowGroup(id: "controls") {
            ControlsView()
                .environment(client)
        }
        .defaultSize(width: 250, height: 280)
        #else
        // iOS / macOS: single window with inline controls
        WindowGroup {
            CameraView()
                .environment(client)
        }
        #endif
    }
}
