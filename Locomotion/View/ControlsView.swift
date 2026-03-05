//
//  ControlsView.swift
//  TestWebRTC
//
//  Created by Bekhruz Hakmirzaev on 03/03/26.
//

import SwiftUI

struct ControlsView: View {
    @Environment(RobotWebRTCClient.self) var client
    @State private var activeCommand: String?
    @State private var commandTimer: Timer?

    var body: some View {
        VStack(spacing: 12) {
            // Forward
            directionButton(symbol: "arrow.up", command: "forward")

            // Left / Right row
            HStack(spacing: 40) {
                directionButton(symbol: "arrow.left", command: "left")
                directionButton(symbol: "arrow.right", command: "right")
            }

            // Backward
            directionButton(symbol: "arrow.down", command: "backward")

            CameraSwitchView()
                .padding()
        }
        .padding()
        .onDisappear {
            stopSendingCommand()
        }
    }

    // MARK: - Direction Button

    @ViewBuilder
    private func directionButton(symbol: String, command: String) -> some View {
        Image(systemName: symbol)
            .font(.title2)
            .frame(width: 70, height: 55)
            .background(activeCommand == command ? Color.blue : Color.white.opacity(0.15))
            .cornerRadius(12)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        startSendingCommand(command)
                    }
                    .onEnded { _ in
                        stopSendingCommand()
                    }
            )
    }

    // MARK: - Command Timer

    private func startSendingCommand(_ command: String) {
        guard activeCommand != command else { return }
        stopSendingCommand()

        activeCommand = command
        client.sendCommand(command)

        commandTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            client.sendCommand(command)
        }
    }

    private func stopSendingCommand() {
        commandTimer?.invalidate()
        commandTimer = nil

        if activeCommand != nil {
            client.sendCommand("stop")
            activeCommand = nil
        }
    }
}
