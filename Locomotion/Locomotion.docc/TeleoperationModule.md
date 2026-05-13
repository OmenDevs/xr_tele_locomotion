# Teleoperation Module

Control the locomotion of a real robot over WebRTC: open a peer-to-peer session, render the
robot's camera feed, and send motion commands down a data channel.

## Overview

The Teleoperation module is the live-robot path through Locomotion.
It assumes there is a robot somewhere on the network that exposes an
`/offer` endpoint, and turns the operator's input into commands that
travel over a WebRTC data channel while the robot's camera comes back as
a video track.

The module breaks into two cooperating parts that live in sibling folders:

- **Client** (`Teleoperation/Client/`), the networking layer. A single
  ``RobotWebRTCClient`` owns the peer connection, video track, and data
  channel, and acts as its own delegate so all state transitions land on
  one observable instance. The full lifecycle, from signaling through ICE
  to streaming, is documented in <doc:ClientModule>.
- **VideoRenderer** (`Teleoperation/VideoRenderer/`), the display layer.
  ``LKRTCDisplayView`` is an `LKRTCVideoRenderer` backed by an
  `AVSampleBufferDisplayLayer`, and ``LKRTCVideoViewRepresentable`` wraps
  it for SwiftUI. Attach a ``RobotWebRTCClient/remoteVideoTrack`` to the
  representable to display incoming frames.

### How input becomes a command

The operator's chosen interaction protocol (see <doc:InputModule>) writes
a normalized triplet onto ``InputViewModel``. ``TeleoperationView`` reads
that triplet on every RealityKit scene tick, throttles it to one send
every 0.2 s, and pushes it through
``RobotWebRTCClient/sendVelocity(velocityX:velocityY:angularVelocity:)``,
which serializes it as `{"vx": …, "vy": …, "omega": …}` on the data
channel labelled `commands`. The Swift names and the wire keys differ on
purpose: `velocityX/Y` and `angularVelocity` read naturally in Swift,
while `vx/vy/omega` matches the format the robot server expects.

A final zero is sent on release, so the robot stops the moment the
operator lets go even if the next periodic send has not fired.

### Camera window

``CameraView`` is a separate window that renders the robot's video track
full-bleed when one is available, and a "Waiting for robot camera..."
placeholder showing ``RobotWebRTCClient/connectionState`` otherwise.
Because the client is shared via the SwiftUI environment, the camera
window and the teleoperation window observe the same connection state
without any extra plumbing.

### Server URL

> Important: ``RobotWebRTCClient/serverURL`` is empty by default and must
> be set on the landing screen before the app can do anything useful. It
> should point at the robot's `/offer` endpoint, for example
> `https://192.168.1.10:8000/offer`. Both devices typically need to share
> the same local network.

## Topics

### Sub-Modules

- <doc:ClientModule>

### Operator Surfaces

- ``TeleoperationView``
- ``CameraView``

### Video Rendering

- ``LKRTCVideoViewRepresentable``
- ``LKRTCDisplayView``
