//
//  CameraView.swift
//  Locomotion
//
//  Created by Can Dindar on 23/02/26.
//

import SwiftUI

struct CameraView: View {
    @Environment(RobotWebRTCClient.self) var client
    @Environment(\.openWindow) private var openWindow
    @Environment(InteractionConfig.self) private var interactionConfig

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let track = client.remoteVideoTrack {
                LKRTCVideoViewRepresentable(videoTrack: track)
                    .ignoresSafeArea()
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("Waiting for robot camera...")
                        .foregroundColor(.white)
                        .font(.title2)
                    Text(client.connectionState)
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }

            // Status + controls overlay
            VStack {
                // ── Top bar: connection status ──
                HStack {
                    Circle()
                        .fill(client.connectionState.contains("✅") ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text(client.connectionState)
                        .font(.caption)
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding()
                .background(Color.black.opacity(0.5))

                Spacer()

                // ── Connect / Disconnect ──
                Button {
                    client.connectionState == "Disconnected"
                    ? client.connect()
                    : client.disconnect()
                } label: {
                    Text(client.connectionState == "Disconnected" ? "Connect to Robot" : "Disconnect")
                        .bold()
                        .padding()
                        .background(client.connectionState == "Disconnected" ? Color.blue : Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding()
            }
        }
        .task {
            client.connect()
        }
        .uniformWindowResize()
        .onDisappear { client.disconnect() }
    }
}
