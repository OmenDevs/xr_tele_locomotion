
<div align="center">

# xr_tele_locomotion

**Teleoperate a humanoid robot from Apple Vision Pro using hand gestures and WebRTC.**

[![Platform](https://img.shields.io/badge/platform-visionOS-blue)](https://developer.apple.com/visionos/)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange?logo=swift)](https://swift.org)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen)](CONTRIBUTING.md)
[![License](https://img.shields.io/github/license/OmenDevs/xr_tele_locomotion)](LICENSE)

</div>

> An open-source telepresence project using Apple Vision Pro that delivers first-person robot embodiment, allowing users to see through the robot’s camera while manually controlling its locomotion.

xr_tele_locomotion pairs a **visionOS app** with a **Python WebRTC server** so an operator wearing a Vision Pro can see what the robot sees and control the locomotion in real time. The visionOS app renders the robot's camera feed, captures operator intent through custom hand gestures. A built-in simulation mode runs the same input stack against a virtual scene, so users can practice the gestures.

## Features

- **WebRTC peer-to-peer link** — sub-second video from the robot, sub-second commands back. STUN-assisted ICE for NAT traversal during development.
- **Two input protocols, one shared output** — Joystick and Astrolabium protocol both write into a single `(velocityX, velocityY, angularVelocity)` triplet, normalized to `-1…+1`. Switching protocols is a one-line config change.
- **Simulation mode** — drive a RealityKit portal scene with the same input stack when no robot is available to practice input protocols.
- **RealSense D435i support on the server** with depth/color/infrared stream switching over the data channel. Graceful fallback to a regular webcam, and finally to a test pattern.
- **Robot integration via CycloneDDS** — incoming velocity commands are republished as `VelocityCommand` (`vx`, `vy`, `omega`) on a DDS topic, so any DDS-capable robot stack can subscribe.
- **Session recording** — optional server-side `.mp4` capture of each peer connection.

## Installation

### Clone the Repository

```bash
git clone https://github.com/OmenDevs/xr_tele_locomotion.git
```
## Requirements

**Xcode with visionOS SDK**
**visionOS 26+**

- Apple Vision Pro device, or the visionOS simulator (hand tracking requires a device)
- Swift package dependencies resolve automatically on first build, including:
  - [LiveKitWebRTC](https://github.com/livekit/webrtc-xcframework) — WebRTC binaries that target visionOS
  - [SwiftLintPlugins](https://github.com/SimplyDanny/SwiftLintPlugins) — enforced at build time

**Server**

- Python 3.9+
- Intel RealSense D435i (optional — falls back to media player of the server)
- A CycloneDDS-capable network interface if a real robot is in the loop
- Full setup: see [`Server/README.md`](Server/README.md)

## Quick Start

### 1. Run the server

```bash
cd Server
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python app.py
```

See [`Server/README.md`](Server/README.md) for the full hardware-specific setup, including building `librealsense` on macOS and the udev rules on Ubuntu.

The server prints its local and network URLs on startup. Note the **Network URL** — you'll paste it into the app.

> **Tip:** Open the Network URL in any browser to use the bundled **browser test client** — a quick way to verify the camera pipeline and data channel without a Vision Pro. See [Browser test client](Server/README.md#browser-test-client) in the server README.

### 2. Run the app

1. Open `Locomotion.xcodeproj` in Xcode and let Swift packages resolve.
2. Build & run the app on device or in the Xcode visionOS simulator.
3. On the landing screen:
   - Pick an [interaction protocol](#interaction-protocols).
   - Tap **Connect the Robot** to teleoperate, then paste the server's `/offer` URL (for example `https://192.168.1.10:8000/offer`) into the field in the camera view.
   - Or tap **Simulator** to try the offline scene and practice the interaction protocols.

The server and the client both typically need to share the same local network for the development setup.

## Interaction Protocols

Both protocols write into the same `InputViewModel` and produce the same `(velocityX, velocityY, angularVelocity)` triplet, so the server, the WebRTC client, and the simulation read input the same way regardless of which mode is active.

**Joystick**: A split gesture scheme where the left hand controls linear motion and the right hand controls angular motion.

**Astrolabium**: A custom one handed gesture that combines joystick style drag and rotation, letting users translate and turn the robot simultaneously with a single hand.

Hand and head tracking are powered by ARKit `HandTrackingProvider` and `WorldTrackingProvider`.

For implementation detail, see the module guide in [`Locomotion/Locomotion.docc/InputModule.md`](Locomotion/Locomotion.docc/InputModule.md).

## Wire Protocol

The data channel labelled `commands` carries JSON messages from the headset to the server. The shape is fixed:

```json
{ "vx": 0.0, "vy": 0.0, "omega": 0.0 }
```

- `vx`, `vy` — normalized linear velocity, `-1…+1`
- `omega` — normalized angular velocity, `-1…+1`
- The app throttles sends to one every 0.2 s, and sends a continuous zero on release so the robot stops immediately when the operator lets go.
- The server forwards these as a CycloneDDS `VelocityCommand` on topic `VelocityTopic` (domain 0).

**Note:** the Swift-side names are `velocityX`, `velocityY`, `angularVelocity` for readability, but the *wire keys are fixed* — the server expects `vx`, `vy`, `omega`. Do not rename them on the wire.

## Simulation Mode

`Start Simulation` opens a RealityKit immersive space showing a portal into a scene. The exact same input stack drives a `POVSimulatorViewModel` that translates and rotates the scenario based on the normalized velocities — useful for:

- Practicing the interaction protocols.
- Demoing the app standalone.

## Contributing

PRs are welcome. Please read [`CONTRIBUTING.md`](CONTRIBUTING.md) for the workflow — branch strategy (`Development` is the integration branch, `main` is release), Conventional Commits, the pre-submission checklist, and the SwiftLint policy.

## Acknowledgments

xr_tele_locomotion stands on the shoulders of several open-source projects. Please visit the URLs to see the respective LICENSES:

- **[LiveKitWebRTC](https://github.com/livekit/webrtc-xcframework)**
- **[Intel RealSense / librealsense](https://github.com/IntelRealSense/librealsense)**
- **[aiortc](https://github.com/aiortc/aiortc)** and **[aiohttp](https://github.com/aio-libs/aiohttp)**
- **[Eclipse CycloneDDS](https://github.com/eclipse-cyclonedds/cyclonedds)**
- **[SwiftLintPlugins](https://github.com/SimplyDanny/SwiftLintPlugins)**

## Special Thanks

Special thanks to Michele Avagnale, Federico Esposito, and Fabio Ruggiero from PRISMA Lab, University of Naples Federico II, for their technical support and collaboration in using the humanoid robot.

## License

xr_tele_locomotion is released under the [MIT License](LICENSE).
