import LiveKitWebRTC

extension RobotWebRTCClient {

    /// Initiates a connection to the robot by creating an SDP offer.
    ///
    /// This method configures ICE servers, initializes the peer connection,
    /// adds a video-only transceiver, and sends the resulting local SDP offer to the server.
    func connect() {
        guard peerConnection == nil else { return }
        connectionState = "Connecting..."

        let config = LKRTCConfiguration()
        // Use Google's public STUN server for NAT traversal
        config.iceServers = [
            LKRTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])
        ]
        config.sdpSemantics = .unifiedPlan

        config.tcpCandidatePolicy = .disabled

        peerConnection = factory.peerConnection(
            with: config,
            constraints: LKRTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil),
            delegate: self
        )

        // Create a data channel for sending commands to the server.
        // This must be done BEFORE the SDP offer so the channel is
        // included in the signaling exchange.
        let dcConfig = LKRTCDataChannelConfiguration()
        dataChannel = peerConnection?.dataChannel(forLabel: "commands", configuration: dcConfig)
        dataChannel?.delegate = self

        // Configure the client to only receive video
        let transceiverInit = LKRTCRtpTransceiverInit()
        transceiverInit.direction = .recvOnly
        peerConnection?.addTransceiver(of: .video, init: transceiverInit)

        // Create the session description offer
        peerConnection?.offer(
            for: LKRTCMediaConstraints(
                mandatoryConstraints: [
                    "OfferToReceiveVideo": "true",
                    "OfferToReceiveAudio": "false"
                ],
                optionalConstraints: nil
            )
        ) { [weak self] sdp, _ in
            guard let self, let sdp else {
                self?.connectionState = "Failed to create offer"
                return
            }

            // Set the local description and share it with the robot server
            self.peerConnection?.setLocalDescription(sdp) { _ in
                self.sendOfferToServer(sdp: sdp)
            }
        }
    }
}
