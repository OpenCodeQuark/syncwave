# SyncWave

Local-first synchronized session platform for nearby listening, built with Flutter + FastAPI.

- Mobile package/application ID: `dev.rajujha.syncwave`
- Current release: **v1.0.0**
- Local mode is default
- External signaling server is optional

## Version Scope

### v1.0.0 (current)
- Local-first room/session foundation
- Local network interface/IP selection and validation
- Room join architecture (room code, join URL, structured QR)
- Two-QR host strategy (App QR + Browser URL QR)
- Optional internet signaling setup with server status/handshake checks
- Optional FastAPI signaling backend with deployment scaffolding

### v2.0.0 (planned)
- Live audio capture and transport
- Microphone/system audio broadcasting
- WebRTC audio media pipeline
- Realtime playback/mixing

v2.0.0 features are intentionally **not implemented** in this release.

## Local-First Product Behavior

### Local Mode (default)
- No external backend required
- Android host creates local session endpoint
- Listeners join on same Wi-Fi/hotspot
- Local IP is selected from valid private interfaces only

### Internet Mode (optional)
- Disabled/hidden until configured
- Requires valid server URL + successful server connection/handshake
- Uses optional FastAPI signaling server
- User enters their own server URL in Settings

## Local Network Rules

Before local hosting starts, SyncWave selects a usable private IPv4 endpoint:
1. Wi-Fi private IPv4
2. Hotspot/tethering private IPv4
3. Other valid private IPv4
4. Reject if none found

If no usable local IP is available, hosting is blocked with:

`Connect to Wi-Fi or enable hotspot to start a local broadcast.`

Additional constraints:
- Local hosting is blocked on mobile-data-only scenarios
- `localhost` / `127.0.0.1` never used in join payloads
- Link-local and invalid addresses are rejected

## PIN Types

### Room PIN
- Purpose: room access control
- Optional
- Must be exactly 6 digits
- Used by join flows and room protection

### Server Connection PIN
- Purpose: optional server handshake/authentication
- Optional unless server requires it
- Must be 8 to 10 digits (numeric only)
- Distinct from Room PIN
- Stored through a dedicated repository boundary (secure-storage ready)

## Optional Internet Server URL Handling

Accepted user input:
- `https://your-server.example.com`
- `http://your-server.example.com`
- `wss://your-server.example.com/ws`
- `ws://your-server.example.com/ws`

Normalized internally:
- `https://your-server.example.com` -> `wss://your-server.example.com/ws`
- `http://your-server.example.com` -> `ws://your-server.example.com/ws`
- `wss://your-server.example.com` -> `wss://your-server.example.com/ws`
- `ws://your-server.example.com` -> `ws://your-server.example.com/ws`
- Existing explicit path is preserved

Derived status URL:
- `wss://your-server.example.com/ws` -> `https://your-server.example.com/status`
- `ws://your-server.example.com/ws` -> `http://your-server.example.com/status`

## Server Connection Status (Settings)

Settings > Advanced / Internet Streaming shows:
- Normalized WebSocket URL
- Derived HTTP status URL
- Connection state
- Last checked time
- Server/protocol version (if available)
- Redis/active rooms/active connections (if available)
- Error code/message (if failed)

Supported UI states:
- Not configured
- Invalid URL
- Checking...
- Server reachable
- Server online, not connected
- Connected
- Disconnected
- Authentication required
- Authentication failed
- WebSocket failed
- Not a SyncWave server

Actions:
- `Test Connection`: probes `/status` (fallback `/health`) and optional websocket handshake check
- `Connect`: keeps websocket open only after explicit connect
- `Disconnect`: closes active optional signaling connection

Internet broadcast availability requires:
- Internet streaming enabled
- Valid server URL
- Server reachable
- WebSocket connected
- Handshake/authentication accepted

## Server Handshake Protocol (v1.0.0)

Client hello event:
- `server.hello`
- includes app name/version, protocol version, platform, optional Server Connection PIN

Server responses:
- `server.ready`
- `server.auth_required`
- `server.auth_failed`
- `server.unsupported_version`
- `error`

## Join Contract and URL Formats

### Local examples
- `http://192.168.1.20:9000/stream/join`
- `http://192.168.1.20:9000/stream/join?room=SW-8FD2-KQ`
- `http://192.168.1.20:9000/stream/join?room=SW-8FD2-KQ&pin=123456`

### Internet examples
- `https://your-server.example.com/stream/join`
- `https://your-server.example.com/stream/join?room=SW-8FD2-KQ`
- `https://your-server.example.com/stream/join?room=SW-8FD2-KQ&pin=123456`

Parser support:
- `room`
- `roomId`
- `pin` (validated as Room PIN: exactly 6 digits)
- structured JSON app payloads
- plain URL QR payloads

## Two QR Strategy (Host)

### 1) App QR (for SyncWave app)
Structured JSON payload, including:
- app metadata
- mode
- room id
- host/server endpoint info
- `roomPinProtected`
- join URL

### 2) Browser URL QR (for browser-capable clients)
Plain URL payload only:
- Local: `http://192.168.1.20:9000/stream/join?room=...`
- Internet: `https://your-server.example.com/stream/join?room=...`

By default, Room PIN is **not** embedded in Browser URL QR.

Browser listener playback is future-scope; full browser listener is not implemented in v1.0.0.

## Backend API (Optional FastAPI)

Location: `services/signaling-server/`

Public status routes:
- `GET /`
- `GET /health`
- `GET /status`

`GET /` returns JSON metadata (not 404), including websocket/health/status paths.

`GET /status` includes:
- app name/version/environment
- server time
- Redis connection status
- active room count
- active connection count
- websocket path
- supported protocol version
- authentication-required flag

### WebSocket endpoint
- Path: `/ws`

Note: opening `/ws` in a browser tab usually does not render a normal HTML page. It is a WebSocket endpoint intended for WebSocket clients.

## Deployment Notes (Optional Backend)

Recommended for long-running websocket signaling:
- Render
- Railway
- Fly.io

Vercel note:
- Not recommended as the primary long-running FastAPI websocket host in this setup
- Can be used for future static landing/web assets

Production command:

```bash
uvicorn app.main:app --host 0.0.0.0 --port $PORT
```

## Monorepo Structure

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

### Optional backend

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

## Platform Notes

- Android: host + listener architecture is supported in v1 foundation flow
- iOS: listener-first path is prioritized
- Unrestricted iOS system audio capture is not implemented
- Live audio capture/transport is intentionally deferred to v2.0.0
