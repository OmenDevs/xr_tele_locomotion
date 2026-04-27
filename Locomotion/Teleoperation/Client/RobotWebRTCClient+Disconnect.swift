//
//  RobotWebRTCClient+Disconnect.swift
//  Locomotion
//
//  Created by Can Dindar on 25/02/26.
//

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
