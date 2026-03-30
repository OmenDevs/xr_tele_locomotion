//
//  LandingView.swift
//  Locomotion
//
//  Created by Julio Enrique Sanchez Guajardo on 25/03/26.
//

import SwiftUI

struct LandingView: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Text("Hello, World!")
        HStack {
            Button("Start RobotControl") {
                openWindow(id: "camera")
            }
            Button("Start Simulation") {
                openWindow(id: "simulation")
                openWindow(id: "dashboard")
                openWindow(id: "log")
            }
        }
    }
}

#Preview {
    LandingView()
}
