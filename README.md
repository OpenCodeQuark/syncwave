# SyncWave

Local-first synchronized music streaming platform.

## Overview

SyncWave is designed to work **without any external backend for normal local usage**.

- Local mode is default.
- Android host creates local rooms over Wi-Fi/hotspot.
- Nearby Android/iOS listeners join via QR or manual join info.
- External FastAPI signaling is optional and only used for internet mode.

Package/application ID: `dev.rajujha.syncwave`

## Local-First Architecture

### Modes

1. `Local Mode` (default)
- No external backend required.
- Host creates local room inside the app.
- Local QR contains join metadata (room + host LAN/hotspot address).

2. `Internet Mode` (optional)
- Disabled/hidden by default.
- Appears only when:
  - `Enable Internet Streaming` is ON
  - Server URL is valid after normalization
- Uses optional FastAPI signaling backend.

### Coordination Layer

Current app architecture includes:

- `StreamingCoordinator`
- `LocalSessionServer`
- `RemoteSignalingClient`
- `LocalNetworkInfoService`
- `NetworkInterfaceSelector`
- `RoomDiscoveryService`
- `JoinLinkService`

Routing logic:

- `mode == local` -> use `LocalSessionServer`
- `mode == internet && settings.internetModeReady` -> use `RemoteSignalingClient`
- otherwise -> configuration error

## Local Network Rules

Before local host broadcast starts, SyncWave must find a usable private IPv4 endpoint.

### Selection Priority

1. Wi-Fi private IPv4
2. Hotspot/tethering private IPv4
3. Other valid private IPv4
4. Reject if none found

### Host Blocking Rule

If no usable local LAN/hotspot IP is available, broadcast is blocked with:

`Connect to Wi-Fi or enable hotspot to start a local broadcast.`

### Additional Restrictions

- Local host mode is not allowed on mobile-data-only interfaces.
- `localhost` / `127.0.0.1` is never used for join QR payloads.
- Link-local/invalid addresses are rejected.

## PIN Rules

PIN protection is optional.

If enabled, PIN must be:

- exactly 6 digits
- numeric only (`0-9`)

Valid examples:
- `123456`
- `000001`
- `987654`

Invalid examples:
- `12345`
- `1234567`
- `abc123`
- `12 3456`
- `123-456`

Validation is applied on:

- host room creation
- join screen manual PIN entry
- join URL parser (`pin` query parameter)
- QR payload parser

PIN is kept in active in-memory session flow only for now (not persisted in long-term app settings storage).

## Settings: Internet Streaming URL Handling

Users can enter:

- `https://example.com`
- `http://example.com`
- `wss://example.com/ws`
- `ws://example.com/ws`

Normalization behavior:

- `https://example.com` -> `wss://example.com/ws`
- `http://example.com` -> `ws://example.com/ws`
- `wss://example.com` -> `wss://example.com/ws`
- `ws://example.com` -> `ws://example.com/ws`
- existing explicit path is preserved

Internet mode stays hidden until both toggle + valid normalized URL are present.

## Join URL Contract

### Local Join URLs

- `http://192.168.1.20:9000/stream/join`
- `http://192.168.1.20:9000/stream/join?room=SW-8FD2-KQ`
- `http://192.168.1.20:9000/stream/join?room=SW-8FD2-KQ&pin=123456`

### Internet Join URLs

- `https://server.example.com/stream/join`
- `https://server.example.com/stream/join?room=SW-8FD2-KQ`
- `https://server.example.com/stream/join?room=SW-8FD2-KQ&pin=123456`

### Parser Support

- supports `room` and `roomId` query parameter
- supports `pin` query parameter with strict 6-digit validation
- supports structured JSON QR payloads
- supports QR payloads containing browser-style join URL
- if room is protected and PIN not present, app prompts user (manual entry flow)

## QR Payload

Structured local payload example:

```json
{
  "app": "syncwave",
  "version": 1,
  "mode": "local",
  "roomId": "SW-8FD2-KQ",
  "hostAddress": "192.168.x.x",
  "hostPort": 9000,
  "pinProtected": true
}
```

Structured internet payload example:

```json
{
  "app": "syncwave",
  "version": 1,
  "mode": "internet",
  "roomId": "SW-8FD2-KQ",
  "serverUrl": "wss://example.com/ws",
  "pinProtected": true
}
```

## Onboarding and Permissions

Onboarding now explicitly explains:

- local streaming works without external server
- Android host + iOS listener-first limitation
- internet mode is optional/manual
- local mode requires same Wi-Fi/hotspot

Permission introduction behavior:

- notification permission is requested when starting host broadcast (foreground-service readiness)
- microphone/system-audio capture permission is **not requested yet**

Planned UI copy remains visible:

`Microphone broadcast and system audio capture will be enabled in later phases.`

## Future Audio Source Model (Planned)

Prepared source model (not active yet):

- `systemAudio` (planned for Phase 5)
- `microphone` (planned for Phase 4)
- `systemAudioWithMic` (planned later)

No audio capture/mixing implementation has started in this phase.

## Optional Backend (FastAPI)

Backend location: `services/signaling-server/`

This backend is optional and used only for internet mode signaling.

### Deployment Readiness

- environment-driven config (`APP_HOST`, `APP_PORT`, `ALLOWED_ORIGINS`, etc.)
- CORS origins configurable
- Dockerfile supports dynamic `$PORT`
- Procfile included for platform deployment

### Preferred Hosts for WebSocket Signaling

For long-running WebSocket signaling, prefer:

- Render
- Railway
- Fly.io

Vercel note:

- Vercel is not recommended as primary long-running WebSocket host for this FastAPI signaling server.
- Vercel can be used later for static landing/web frontends.

### Production Run Command

```bash
uvicorn app.main:app --host 0.0.0.0 --port $PORT
```

### WebSocket URL Examples

- Local dev: `ws://localhost:8000/ws`
- LAN dev: `ws://192.168.1.20:8000/ws`
- Production: `wss://your-server.example.com/ws`

## Repo Structure

```txt
syncwave/
├── apps/                          # Flutter app root
│   ├── android/
│   ├── ios/
│   ├── web/
│   ├── linux/
│   ├── macos/
│   ├── windows/
│   ├── lib/
│   ├── test/
│   └── pubspec.yaml
├── services/
│   └── signaling-server/          # Optional FastAPI signaling backend
│       ├── app/
│       ├── tests/
│       ├── requirements.txt
│       ├── Dockerfile
│       └── Procfile
├── docker-compose.yml
├── CHANGELOG.md
├── README.md
└── LICENSE
```

## Setup

### Flutter App

```bash
cd apps
flutter pub get
flutter run
```

### Optional Backend

```bash
cd services/signaling-server
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

## Validation Commands

### Flutter

```bash
cd apps
flutter pub get
dart run build_runner build
flutter analyze
flutter test
flutter build apk --debug
```

### Backend

```bash
cd services/signaling-server
source .venv/bin/activate
python -m pytest
ruff check app tests
```

## Roadmap (Next)

- Continue Phase 2 room and participant lifecycle UX with local-first constraints
- Keep FastAPI optional; do not couple local mode to external server
- Implement WebRTC signaling/data plane in later phases
