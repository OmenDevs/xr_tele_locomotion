//
//  RobotWebRTCClient.swift
//  TestWebRTC
//
//  Created by Can Dindar on 25/02/26.
//

import LiveKitWebRTC

extension RobotWebRTCClient: LKRTCPeerConnectionDelegate {

    /// Called when the ICE connection state changes (e.g., connected, failed).
    func peerConnection(_ peerConnection: LKRTCPeerConnection, didChange newState: LKRTCIceConnectionState) {
        DispatchQueue.main.async {
            switch newState {
            case .connected:    self.connectionState = "Connected ✅"
            case .checking:     self.connectionState = "Checking..."
            case .failed:       self.connectionState = "ICE Failed ❌"
            case .disconnected: self.connectionState = "Disconnected"
            default:            break
            }
        }
    }

    /// Called when a new media track (video/audio) is received from the remote peer.
    func peerConnection(_ peerConnection: LKRTCPeerConnection,
                        didAdd rtpReceiver: LKRTCRtpReceiver,
                        streams mediaStreams: [LKRTCMediaStream]) {
        if let videoTrack = rtpReceiver.track as? LKRTCVideoTrack {
            DispatchQueue.main.async {
                self.remoteVideoTrack = videoTrack
            }
        }
    }

    func peerConnection(_ peerConnection: LKRTCPeerConnection, didChange stateChanged: LKRTCSignalingState) {}
    func peerConnection(_ peerConnection: LKRTCPeerConnection, didAdd stream: LKRTCMediaStream) {}
    func peerConnection(_ peerConnection: LKRTCPeerConnection, didRemove stream: LKRTCMediaStream) {}
    func peerConnectionShouldNegotiate(_ LKpeerConnection: LKRTCPeerConnection) {}
    func peerConnection(_ peerConnection: LKRTCPeerConnection, didChange newState: LKRTCIceGatheringState) {}
    func peerConnection(_ peerConnection: LKRTCPeerConnection, didGenerate candidate: LKRTCIceCandidate) {}
    func peerConnection(_ peerConnection: LKRTCPeerConnection, didRemove candidates: [LKRTCIceCandidate]) {}
    func peerConnection(_ peerConnection: LKRTCPeerConnection, didOpen dataChannel: LKRTCDataChannel) {}
}
