# SyncWave

SyncWave is a local-first live audio streaming app. Android can host system audio with MediaProjection and AudioPlaybackCapture, and listeners can join from a browser on the same Wi-Fi/hotspot. Optional internet mode uses a self-hosted FastAPI WebSocket server.

- Version: `1.1.4`
- Android package/application ID: `io.github.opencodequark.syncwave`
- Source: <https://github.com/OpenCodeQuark/syncwave>

## Features

- LAN browser listening through `GET /stream/join` and `WS /stream/audio`.
- Optional WAN rooms through the FastAPI signaling/relay server.
- Explicit LAN, Internet, or LAN + Internet broadcast choice when both are ready.
- Active broadcast banner with Return and Stop actions.
- Room PIN: optional, exactly 6 digits.
- Server Connection PIN: optional, exactly 8 digits for protected host/relay actions.
- Mobile-first Material 3 app UI and refreshed browser listener page.

## App Setup

```sh
cd apps
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter build apk --debug
```

Release validation:

```sh
cd apps
flutter build apk --release
```

Android hosting needs a physical Android 10+ device. Emulators do not fully validate system-audio capture.

## Server Setup

```sh
cd server
python -m venv .venv
.venv/bin/python -m pip install --upgrade pip
.venv/bin/python -m pip install -r requirements.txt
.venv/bin/python -m pip install ruff
.venv/bin/python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Main server routes: `GET /`, `GET /health`, `GET /status`, `POST /rooms`, `GET /stream/join`, and `WS /ws`.

For GitHub Releases, the workflow uses `GITHUB_TOKEN` with `contents: write`. Also verify: Repo -> Settings -> Actions -> General -> Workflow permissions -> Read and write permissions.

## Usage

For LAN, connect the host and listener to the same Wi-Fi or Android hotspot, start a broadcast, choose LAN, approve Android capture prompts, then open the shown `/stream/join` URL on another device.

For internet mode, deploy the server over HTTPS/WSS, enable Internet Streaming in app Settings, test/connect the server, then choose Internet or LAN + Internet when starting a broadcast.

## PINs

- Room PIN protects a room. Normal listeners only need this 6-digit PIN when the room is protected.
- Server Connection PIN protects host/server actions such as WAN room creation and relay startup.
- `/stream/join` never asks normal listeners for the Server Connection PIN.

## Tests

```sh
cd apps
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug

cd ../server
.venv/bin/python -m ruff check app tests
.venv/bin/python -m pytest
```

## Known Limitations

- Audio transport is still PCM16 mono JSON/base64 over WebSocket. Opus/WebRTC remains future work.
- Android is the supported host platform; other platforms are listener/control surfaces for now.
- In-app listener playback is not implemented; listener flows open or copy the browser listener link.
- Android OS-level `syncwave://` intent-filter launch handling is pending.
- Redis is optional but not yet shared room state across multiple server instances.

Made with love by [R. Jha](https://rjrajujha.github.io)
