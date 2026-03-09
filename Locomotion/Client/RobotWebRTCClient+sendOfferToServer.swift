//
//  RobotWebRTCClient+sendOfferToServer.swift
//  TestWebRTC
//
//  Created by Can Dindar on 25/02/26.
//

import LiveKitWebRTC

extension RobotWebRTCClient {

    /// Sends the local SDP offer to the signaling server and applies the server's SDP answer.
    /// - Parameter sdp: The local session description created by the peer connection.
    func sendOfferToServer(sdp: LKRTCSessionDescription) {
        guard let url = URL(string: serverURL) else {
            connectionState = "Invalid server URL"
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Encode the SDP as JSON for the POST body
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "sdp": sdp.sdp,
            "type": sdp.type == .offer ? "offer" : "answer"
        ])

        guard let urlSession else { return }

        Task {
            do {
                let (data, _) = try await urlSession.data(for: request)

                // Parse the remote SDP answer from the server
                guard
                    let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
                    let remoteSdpString = json["sdp"],
                    let typeString = json["type"]
                else {
                    await MainActor.run { self.connectionState = "Invalid server response" }
                    return
                }

                let sdpType: LKRTCSdpType = typeString == "offer" ? .offer : .answer
                let remoteSdp = LKRTCSessionDescription(type: sdpType, sdp: remoteSdpString)

                // Apply the robot's SDP as the remote description to finalize the handshake
                self.peerConnection?.setRemoteDescription(remoteSdp) { error in
                    if let error {
                        Task { @MainActor in
                            self.connectionState = "SDP error: \(error.localizedDescription)"
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.connectionState = "Network error: \(error.localizedDescription)"
                }
            }
        }
    }
}
