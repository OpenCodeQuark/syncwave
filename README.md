# SyncWave

SyncWave is a **local-first live audio broadcast app** built with Flutter and FastAPI.

- Package/application ID: `dev.rajujha.syncwave`
- Current version: **1.0.0**
- Flutter app root: `apps/`
- Optional signaling backend: `services/signaling-server/`

## What SyncWave Does

SyncWave lets an Android host broadcast live audio to nearby listeners on the same Wi-Fi/hotspot network.

- No external backend is required for normal local usage.
- Internet signaling is optional and disabled by default.
- iOS is listener-first in v1.0.0.

## Version Scope

### v1.0.0 (current)

- Local-first hosting and joining flow
- Android live capture host pipeline (system audio + optional microphone)
- Foreground broadcast service and MediaProjection permission flow
- Automatic local/private IP selection for LAN/hotspot hosting
- Single QR join strategy with `syncwave://` deep links
- Manual join via room code / join URL / QR payload
- Optional internet signaling setup (status probe + websocket handshake)
- Optional FastAPI signaling backend with deploy-ready Dockerfile

### v2.0.0 (planned)

- Advanced WebRTC media optimization
- Adaptive bitrate and deeper sync correction
- Improved microphone mixing/routing controls
- TURN/STUN scaling and production relay enhancements
- Expanded desktop broadcast tooling

## Local-First Networking Rules

Host start behavior is automatic (no local/internet mode switch in host UI):

1. If usable local private IP exists (Wi-Fi/hotspot), local broadcasting is enabled.
2. If optional internet signaling is configured + connected, internet-assisted sessions are available.
3. If neither local IP nor connected signaling server exists, broadcast is blocked with:

`Connect to Wi-Fi, enable hotspot, or connect an internet signaling server to start broadcasting.`

Local host/IP constraints:

- Priority: Wi-Fi private IPv4 -> hotspot/tethering private IPv4 -> other private IPv4
- Mobile-data-only hosting is rejected
- `localhost` and `127.0.0.1` are rejected for join targets
- Link-local/invalid addresses are rejected

## Audio in v1.0.0

### Host (Android)

- Live system audio capture via Android `MediaProjection` + `AudioPlaybackCapture`
- Foreground service for active broadcast lifecycle
- Optional microphone overlay path
- Host UI uses two user-facing toggles:
  - `Audio Source` (default ON)
  - `Microphone` (optional)
- At least one audio source must be enabled to start

### Listener

- Listener join flow is available in app
- Browser listener endpoint is available via `/stream/join` for live local playback
- iOS remains listener-first

## PIN Model

### Room PIN

- Optional
- Exactly 6 digits (`0-9`)
- Used for room join protection

### Server Connection PIN

- Optional (unless server requires it)
- 8 to 10 digits (`0-9`)
- Used for optional internet signaling server handshake auth
- Distinct from Room PIN

## Deep Links, Join URLs, and QR

SyncWave uses a **single QR** strategy in host flow.

- QR payload: `syncwave://join?...`
- Host also provides copy actions for join link and room code

### `syncwave://` examples

- `syncwave://join?host=192.168.1.20:9000&room=SW-8FD2-KQ`
- `syncwave://join?host=your-server.example.com&room=SW-8FD2-KQ`
- `syncwave://join?host=192.168.1.20:9000&room=SW-8FD2-KQ&pin=123456`

Rules:

- `host` is required
- `room`/`roomId` is supported
- optional `pin` must pass 6-digit Room PIN validation
- loopback/localhost targets are rejected

### HTTP/HTTPS join URL examples

Local:

- `http://192.168.1.20:9000/stream/join`
- `http://192.168.1.20:9000/stream/join?room=SW-8FD2-KQ`
- `http://192.168.1.20:9000/stream/join?room=SW-8FD2-KQ&pin=123456`

Internet:

- `https://your-server.example.com/stream/join`
- `https://your-server.example.com/stream/join?room=SW-8FD2-KQ`
- `https://your-server.example.com/stream/join?room=SW-8FD2-KQ&pin=123456`

## Optional Internet Signaling

Internet signaling remains optional and disabled by default.

Settings supports:

- Enable Internet Streaming
- Server URL
- Server Connection PIN
- Test Connection
- Connect / Disconnect
- Connection status panel

Server URL input examples:

- `https://your-server.example.com`
- `http://192.168.1.20:9000`
- `wss://your-server.example.com/ws`
- `ws://your-server.example.com/ws`

Internal normalization:

- `https://...` -> `wss://.../ws`
- `http://...` -> `ws://.../ws`
- `/status` URL is derived automatically from normalized websocket URL

## Optional Backend (FastAPI)

Location: `services/signaling-server/`

### Endpoints

- `GET /`
- `GET /health`
- `GET /status`
- `WS /ws`

`/status` includes:

- app/version/environment/status
- server time
- redis connection state
- active rooms/connections
- websocket path
- supported protocol version
- authentication-required flag

### Handshake Events

- `server.hello`
- `server.ready`
- `server.auth_required`
- `server.auth_failed`
- `server.unsupported_version`
- `error`

### Redis

Redis is optional in v1.0.0.

- Server runs without Redis (in-memory room/session state)
- `/status` reports `redisConnected`

## Deployment Notes

Recommended for long-running websocket workloads:

- Render
- Railway
- Fly.io

Vercel note:

- Not recommended as the primary host for this long-running websocket FastAPI service
- Suitable later for static landing pages/web assets

Production run command:

```bash
uvicorn app.main:app --host 0.0.0.0 --port $PORT
```

## Architecture Overview

### Flutter (`apps/lib`)

- `features/host`: host setup + live room
- `features/join`: scan/manual join flows
- `features/settings`: optional internet signaling configuration/state
- `features/streaming`: models/services/coordinator, deep links, validation, server status
- `core/audio`: Android native audio capture bridge

### Backend (`services/signaling-server/app`)

- `api/`: HTTP routes (`/`, `/health`, `/status`)
- `websocket/`: connection manager + websocket handlers/routes
- `services/`: room/signaling/sync/redis services
- `core/`: env/config/logging/security

## Monorepo Structure

```txt
syncwave/
├── apps/
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
│   └── signaling-server/
│       ├── app/
│       ├── tests/
│       ├── Dockerfile
│       ├── Procfile
│       └── .env.example
├── docker-compose.yml
├── CHANGELOG.md
├── README.md
└── LICENSE
```

## Setup

### Flutter app

```bash
cd apps
flutter pub get
flutter run
```

### Optional signaling backend

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

## Platform Support

| Platform | Host | Listener |
|---|---|---|
| Android | Yes (v1.0.0) | Yes |
| iOS | Not yet (host) | Yes (listener-first) |
| Web/Desktop | Not host-target in v1 | Browser listener path available via join endpoint |

## Screenshots / Demo Placeholders

- Host setup screen
- Live broadcast room with QR + join link actions
- Join (scan/manual) flow
- Internet streaming settings with connection state
- About page

## Resume-Ready Summary

Built **SyncWave (v1.0.0)** as a production-oriented Flutter + FastAPI monorepo implementing local-first live audio broadcasting architecture, Android native capture integration (MediaProjection + foreground service), typed join/deep-link workflows, optional internet signaling with handshake/auth states, and deploy-ready backend runtime status/lifecycle hardening.
