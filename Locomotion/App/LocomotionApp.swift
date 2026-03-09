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
        WindowGroup(id: "camera") {
            CameraView()
                .environment(client)
        }

        WindowGroup(id: "controls") {
            PanelView()
                .environment(client)
        }
        .defaultSize(width: 250, height: 280)
    }
}
