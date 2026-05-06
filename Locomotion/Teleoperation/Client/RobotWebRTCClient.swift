//
//  RobotWebRTCClient.swift
//  Locomotion
//
//  Created by Can Dindar on 25/02/26
//

import LiveKitWebRTC

/// A client that manages a WebRTC connection to a robot, handling video streaming and signaling.

@Observable
 class RobotWebRTCClient: NSObject {

    /// The URL of the signaling server used to exchange WebRTC offers and answers.
    /// - Note: Change this to your server's specific IP/hostname (e.g., `https://192.168.1.10:8000/offer`).
    let serverURL: String = "https://10.20.60.14:8000/offer"

    /// The factory used to create peer connections and media tracks.
    let factory: LKRTCPeerConnectionFactory

    /// The current active WebRTC peer connection.
    var peerConnection: LKRTCPeerConnection?

    var urlSession: URLSession?

    var connectionState: String = "Disconnected"

    /// The incoming video track received from the robot.
    ///
    /// Observe this property to update your video view when a stream becomes available.
    var remoteVideoTrack: LKRTCVideoTrack?

    /// The WebRTC data channel used to send commands to the server.
    var dataChannel: LKRTCDataChannel?

    /// The last message received from the server via the data channel.
    var lastServerMessage: String = ""

    /// Initializes a new client, sets up SSL, and configures the WebRTC factory.
    override init() {
        // Initialize the global SSL environment for WebRTC
        LKRTCInitializeSSL()

        // Setup hardware/software encoders and decoders
        let encoderFactory = LKRTCDefaultVideoEncoderFactory()
        let decoderFactory = LKRTCDefaultVideoDecoderFactory()

        self.factory = LKRTCPeerConnectionFactory(
            encoderFactory: encoderFactory,
            decoderFactory: decoderFactory
        )

        super.init()

        // Setup a custom URLSession to allow self-signed certificates during development
        self.urlSession = URLSession(
            configuration: .default,
            delegate: SelfSignedCertDelegate(),
            delegateQueue: nil
        )
    }
}
