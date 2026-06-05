# xr_tele_locomotion — Robot Camera Server 🤖

WebRTC server that streams a RealSense D435i camera to an iOS/visionOS client, with real-time depth, color, and infrared stream switching.

## Requirements

- Python 3.9+
- Intel RealSense D435i camera
- [librealsense](https://github.com/IntelRealSense/librealsense) built locally **or** `pyrealsense2` installed via pip (Ubuntu)

---

## Setup

### 1. Configure the RealSense backend

**macOS** — Install prerequisites and build `librealsense` locally:

1. Install prerequisites:
   ```bash
   xcode-select --install
   brew install cmake libusb pkg-config openssl
   ```

2. Clone and build `librealsense` inside the project folder:
   ```bash
   cd xr_tele_locomotion
   git clone https://github.com/realsenseai/librealsense.git
   cd librealsense
   mkdir build && cd build
   cmake .. \
     -DBUILD_EXAMPLES=true \
     -DBUILD_GRAPHICAL_EXAMPLES=true \
     -DFORCE_RSUSB_BACKEND=ON \
     -DBUILD_PYTHON_BINDINGS=ON \
     -DPYTHON_EXECUTABLE=$(which python3)
   make -j2
   ```

**Ubuntu** — Install via pip (no local build needed):
```bash
pip install pyrealsense2
# Install udev rules (one-time):
sudo cp librealsense/config/99-realsense-libusb.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules && sudo udevadm trigger
```

### 2. Install Python Server dependencies

```bash
cd xr_tele_locomotion/Server
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### 3. Generate SSL certificates

WebRTC requires HTTPS. Generate self-signed certs (development only):

```bash
cd Server
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes -subj "/CN=localhost"
```

### 4. Configure the environment

Copy the example file and edit as needed:

```bash
cp .env.example .env
```

| Variable | Default | Description |
|---|---|---|
| `SERVER_HOST` | `0.0.0.0` | Bind address. Set to the robot's Ethernet IP when testing over cable |
| `SERVER_PORT` | `8000` | Port the server listens on |
| `CAMERA_SOURCE` | `0` | Camera device index |
| `CAMERA_FRAMERATE` | `30` | Stream frame rate |
| `CAMERA_RESOLUTION` | `1280x720` | Stream resolution |
| `ENABLE_RECORDING` | `false` | Set to `true` to save sessions to `recordings/` |

---

### 5. Run the server

```bash
sudo python Server/app.py   # macOS
python Server/app.py        # Ubuntu (after udev rules)
```

The server prints its local and network URLs on startup. Use the **Network URL** in the visionOS app.

---

## Browser test client

The server hosts a minimal web browser. After running the server go to your local host or search your ip address(for example `https://192.168.1.10:8000/`) from the browser. You'll get a *Start connection* button that opens the same WebRTC session the visionOS app uses, plus a text channel for sending messages.

Useful for:

- Verifying the camera pipeline and signaling are working **without a Vision Pro or visionOS SDK**.
- Smoke-testing a new server build before pairing it with the app.
- Debugging the data channel: messages typed in the chat box are echoed by the server.

The browser will warn about the self-signed certificate — accept it once to proceed.

> Note: The browser client also does send velocity commands if json format followed. 

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
| `static/` | Browser test client
| `requirements.txt` | Python dependencies |
