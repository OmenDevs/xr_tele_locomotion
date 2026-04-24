# Client Module

Establish and maintain a WebRTC connection between the visionOS app and the robot.

## Overview

The Client module is the networking layer of Locomotion, a visionOS telepresence app.
It opens a peer-to-peer WebRTC session with an external robot server, receives a live
video stream from the robot when one is available, and sends teleoperation commands
back through a data channel.

The module is built around a single `@Observable` type, ``RobotWebRTCClient``, which owns
the peer connection, the video track, and the data channel. The client also acts as its
own `LKRTCPeerConnectionDelegate` and `LKRTCDataChannelDelegate`, so every state
transition flows back into the same observable instance and drives the UI with no
additional glue.

### Why LiveKitWebRTC

Locomotion imports **LiveKitWebRTC** rather than stock Google WebRTC. Upstream WebRTC
does not publish binaries that compile for visionOS, so the LiveKit fork is used as a
drop-in replacement — this is why every WebRTC type in the module is prefixed with
`LK` (for example `LKRTCPeerConnection`, `LKRTCVideoTrack`, `LKRTCDataChannel`).

### Relationship to Video Rendering

This module stops at producing an `LKRTCVideoTrack`. Turning that track into on-screen
frames is the responsibility of the sibling `VideoRenderer/` folder, which contains
`LKRTCDisplayView` (an `LKRTCVideoRenderer` backed by `AVSampleBufferDisplayLayer`) and
`LKRTCVideoViewRepresentable` (its SwiftUI wrapper). Attach a
``RobotWebRTCClient/remoteVideoTrack`` to an `LKRTCVideoViewRepresentable` to display it.

## Initialization

Creating a ``RobotWebRTCClient`` eagerly prepares the networking stack:

- `LKRTCInitializeSSL()` initializes the global WebRTC SSL environment.
- An `LKRTCPeerConnectionFactory` is built from the default hardware/software video
  encoder and decoder factories.
- A dedicated `URLSession` is configured with ``SelfSignedCertDelegate`` so signaling
  requests against a robot using a self-signed TLS certificate succeed during
  development.

No peer connection exists until ``RobotWebRTCClient/connect()`` is called.

## Connection Lifecycle

A session goes through three distinct phases.

### 1. Signaling

``RobotWebRTCClient/connect()`` creates an `LKRTCPeerConnection`, pre-negotiates a data
channel, adds a `recvOnly` video transceiver, and generates a local SDP *offer* with the
mandatory constraints `OfferToReceiveVideo: true` and `OfferToReceiveAudio: false`.

The offer is set as the local description and POSTed as JSON to the endpoint configured
in ``RobotWebRTCClient/serverURL`` by ``RobotWebRTCClient/sendOfferToServer(sdp:)``. The
robot replies with an SDP *answer*, which the client applies as the remote description
to finalize the handshake.

If the URL is malformed, the server replies with something that does not parse, or the
request fails, ``RobotWebRTCClient/connectionState`` is set to `Invalid server URL`,
`Invalid server response`, or `Network error: …` respectively.

### 2. ICE and Media Negotiation

A single STUN server (`stun.l.google.com:19302`) is configured for NAT traversal, and
unified-plan SDP semantics are used. Because the transceiver is `recvOnly`, the client
consumes media only — it never publishes a camera or microphone.

As ICE progresses, the peer connection delegate updates
``RobotWebRTCClient/connectionState`` on the main actor. Possible values include:

- `Disconnected` — initial state and the state after ``RobotWebRTCClient/disconnect()``.
- `Connecting...` — set synchronously when ``RobotWebRTCClient/connect()`` starts.
- `Checking...` — ICE is gathering and probing candidates.
- `Connected ✅` — ICE connection established.
- `ICE Failed ❌` — ICE could not find a working path.
- `Failed to create offer` — the local peer connection did not produce an SDP.

### 3. Streaming and Commands

Once the connection is up:

- The robot's video track arrives through `peerConnection(_:didAdd:streams:)` and is
  published on ``RobotWebRTCClient/remoteVideoTrack`` for rendering.
- The pre-negotiated data channel labelled `commands` is used for low-latency control
  messages. It must be created *before* the offer is generated so it appears in the
  signaling exchange.

Use ``RobotWebRTCClient/sendCommand(_:)`` for arbitrary UTF-8 string payloads, or
``RobotWebRTCClient/sendVelocity(velocityX:velocityY:omega:)`` to send joystick values
in the `{"vx": …, "vy": …, "omega": …}` format the robot expects. Sends are silently
dropped while the channel is not `.open`.

Incoming server messages are decoded as UTF-8 and surfaced on
``RobotWebRTCClient/lastServerMessage`` (updated on the main actor); data channel state
transitions are logged to the console.

``RobotWebRTCClient/disconnect()`` closes the data channel and peer connection and
clears all observable state, returning the client to its initial condition and allowing
``RobotWebRTCClient/connect()`` to be called again.

## Configuring the Server URL

> Important: `RobotWebRTCClient/serverURL` is **empty by default and must be set** before the app can function. Point it at the `/offer` endpoint of the robot you want to control, for example:
`https://192.168.1.10:8000/offer` The URL must be reachable from the device running the app — typically this means both devices share the same local network.

## Topics

### Client

- ``RobotWebRTCClient``

### Connection Management

- ``RobotWebRTCClient/connect()``
- ``RobotWebRTCClient/disconnect()``
- ``RobotWebRTCClient/connectionState``

### Signaling

- ``RobotWebRTCClient/serverURL``
- ``RobotWebRTCClient/sendOfferToServer(sdp:)``
- ``SelfSignedCertDelegate``

### Media and Commands

- ``RobotWebRTCClient/remoteVideoTrack``
- ``RobotWebRTCClient/dataChannel``
- ``RobotWebRTCClient/sendCommand(_:)``
- ``RobotWebRTCClient/sendVelocity(velocityX:velocityY:omega:)``
- ``RobotWebRTCClient/lastServerMessage``
