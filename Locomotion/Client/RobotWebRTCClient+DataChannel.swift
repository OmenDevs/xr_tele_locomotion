//
//  RobotWebRTCClient+DataChannel.swift
//  TestWebRTC
//
//  Handles the WebRTC data channel delegate and command sending.
//

import LiveKitWebRTC

extension RobotWebRTCClient: LKRTCDataChannelDelegate {

    /// Called when the data channel's state changes (e.g., open, closed).
    func dataChannelDidChangeState(_ dataChannel: LKRTCDataChannel) {
        let state: String
        switch dataChannel.readyState {
        case .open:       state = "open"
        case .closed:     state = "closed"
        case .connecting: state = "connecting"
        case .closing:    state = "closing"
        @unknown default: state = "unknown"
        }
        print("📡 Data channel state: \(state)")
    }

    /// Called when a message is received from the server on the data channel.
    func dataChannel(_ dataChannel: LKRTCDataChannel, didReceiveMessageWith buffer: LKRTCDataBuffer) {
        if let message = String(data: buffer.data, encoding: .utf8) {
            Task { @MainActor in
                self.lastServerMessage = message
            }
            print("📩 Server: \(message)")
        }
    }

    /// Sends a command string to the server via the data channel.
    /// - Parameter command: The command to send (e.g., "forward", "stop").
    func sendCommand(_ command: String) {
        guard let dataChannel,
              dataChannel.readyState == .open,
              let data = command.data(using: .utf8)
        else { return }

        let buffer = LKRTCDataBuffer(data: data, isBinary: false)
        dataChannel.sendData(buffer)
    }
}
