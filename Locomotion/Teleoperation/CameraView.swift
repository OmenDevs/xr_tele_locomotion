//
//  CameraView.swift
//  Locomotion
//
//  Created by Can Dindar on 23/02/26.
//

import SwiftUI

private enum ConnectionPhase {
    case enteringIP
    case connecting
}

struct CameraView: View {
    @Environment(RobotWebRTCClient.self) var client
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(InteractionConfig.self) private var interactionConfig

    @State private var phase: ConnectionPhase = .enteringIP
    @State private var showingIPAlert: Bool = true
    @State private var showingErrorAlert: Bool = false
    @State private var showingExitConfirm: Bool = false

    var body: some View {
        @Bindable var client = client
        NavigationStack {
        ZStack {
            Color.black.ignoresSafeArea()

            if let track = client.remoteVideoTrack {
                LKRTCVideoViewRepresentable(videoTrack: track)
                    .ignoresSafeArea()
            }

            if phase == .connecting && client.remoteVideoTrack == nil {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.4)
                    Text("Connecting...")
                        .foregroundStyle(.white)
                        .bold()
                }
                .padding(32)
            }
        }
        /// IP connection alert
        .alert("IP Address", isPresented: $showingIPAlert) {
            TextField("e.g. https:" + "//192.168.1.10:8000/offer)", text: $client.serverURL)
            Button("Connect") {
                phase = .connecting
                client.connect()
            }
            Button("Cancel", role: .cancel) {
                dismissWindow(id: "camera")
            }
        } message: {
            Text("Insert the IP Address to connect to the Robot")
        }

        .alert("Connection Failed", isPresented: $showingErrorAlert) {
            Button("Cancel", role: .cancel) {
                phase = .enteringIP
                showingIPAlert = true
            }
        } message: {
            Text(client.connectionState)
        }

        .onChange(of: client.connectionState) { _, newState in
            let isError = newState.contains("Failed") || newState.contains("Invalid") || newState.contains("error")
            if phase == .connecting && isError {
                showingErrorAlert = true
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Exit") { showingExitConfirm = true }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(white: 0.5))
                    .foregroundStyle(.white)
            }
        }
        .alert("Exit", isPresented: $showingExitConfirm) {
            Button("Exit", role: .destructive) {
                dismissWindow(id: "camera")
            }
            Button("Cancel", role: .cancel) { showingExitConfirm = false }
        } message: {
            Text("Do you want to exit this view?")
        }
        .uniformWindowResize()
        .onDisappear {
            client.disconnect()
            dismissWindow(id: "joystick")
            openWindow(id: "landing")
            Task { await dismissImmersiveSpace() }
        }
        }
    }
}
