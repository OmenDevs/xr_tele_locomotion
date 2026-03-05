# Locomotion — Robot Camera Server 🤖

WebRTC server that streams a RealSense D435i camera to an iOS/visionOS client, with real-time depth, color, and infrared stream switching.

## Requirements

- Python 3.9+
- Intel RealSense D435i camera
- [librealsense](https://github.com/IntelRealSense/librealsense) built locally **or** `pyrealsense2` installed via pip (Ubuntu)

---

## Setup

### 1. Install dependencies

```bash
pip install -r requirements.txt
```

### 2. Set up pyrealsense2

**macOS** — build librealsense locally and place it at the repo root:
```
Locomotion/
└── librealsense/
    └── build/
        └── Release/      ← pyrealsense2.so lives here
```
Then run with `sudo` (required for USB access on macOS):
```bash
sudo python3 Server/app.py
```

**Ubuntu** — install via pip (no `sudo` needed after setting udev rules):
```bash
pip install pyrealsense2
# Install udev rules (one-time):
sudo cp librealsense/config/99-realsense-libusb.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules && sudo udevadm trigger
python3 Server/app.py
```

### 3. Generate SSL certificates

WebRTC requires HTTPS. Generate self-signed certs (development only):

```bash
cd Server
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes -subj "/CN=localhost"
```

### 4. Run the server

```bash
sudo python3 Server/app.py   # macOS
python3 Server/app.py        # Ubuntu (after udev rules)
```

The server prints its local and network URLs on startup. Use the **Network URL** in the iOS app.

---

## Stream Switching

The client can switch streams in real time over the WebRTC data channel:

| Command | Stream |
|---|---|
| `stream:color` | RGB color (default) |
| `stream:depth` | Colorized depth map |
| `stream:infrared` | Infrared (grayscale) |

---

## Fallback

If the RealSense camera is not connected, the server automatically falls back to a regular webcam via `MediaPlayer`. Stream switching commands will have no effect in fallback mode.

---

## Files

| File | Description |
|---|---|
| `app.py` | WebRTC signaling server, HTTP routes, startup |
| `realsense_track.py` | RealSense camera pipeline and stream switching |
| `viewer.py` | Local debug tool — preview streams without WebRTC |
| `requirements.txt` | Python dependencies |
