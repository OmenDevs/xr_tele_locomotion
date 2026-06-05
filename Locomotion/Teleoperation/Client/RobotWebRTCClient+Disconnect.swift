import LiveKitWebRTC

extension RobotWebRTCClient {

    /// Closes the active peer connection and resets the client state.
    func disconnect() {
        dataChannel?.close()
        dataChannel = nil
        peerConnection?.close()
        peerConnection = nil
        connectionState = "Disconnected"
        remoteVideoTrack = nil
        lastServerMessage = ""
    }
}
