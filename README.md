# SyncWave

SyncWave is a local-first live audio broadcasting app.

- App package ID: `dev.rajujha.syncwave`
- Current release: `1.0.0`
- Flutter app: `apps/`
- Optional signaling server: `server/`

SyncWave focuses on simple local broadcasting first:

- Android host captures and broadcasts live audio
- Nearby listeners join over Wi-Fi/hotspot
- Browser listeners can join with `/stream/join`
- Internet signaling is optional and disabled by default

## v1.0.0 Scope

### Included in v1.0.0
- Local-first host/listener architecture
- Android system audio capture (MediaProjection + AudioPlaybackCapture)
- Foreground broadcast lifecycle on Android
- LAN room creation and join flows
- Optional WAN room/session support through signaling server
- `syncwave://` deep link + join URL + QR parser support
- Browser listener pages (local server + optional internet server)
- Server status/health routes and typed WebSocket handshake
- QR include-PIN toggle (default off)
- Stop/rebroadcast lifecycle hardening

### Planned after v1.0.0
- Advanced media transport optimization
- Adaptive bitrate and deeper sync correction
- Rich microphone mixing controls
- TURN/STUN scaling for large deployments

## Core Features

- Local-first by default, no external backend required for LAN use
- Optional internet signaling server when configured in Settings
- LAN rooms: `LAN-XXXXX`
- WAN rooms: `WAN-XXXXX`
- Room PIN (exactly 6 digits) support
- Server Connection PIN (8-10 digits) support for optional server auth
- Host controls for sound mute/unmute during active broadcast
- Browser listener with playback controls and buffering indicators

## Platform Support

| Platform | Host | Listener |
|---|---|---|
| Android | Yes | Yes |
| iOS | Not yet (host) | Yes |
| Browser | No host | Yes (`/stream/join`) |

## Important Android Note (System Audio Permission)

Android system audio capture uses MediaProjection.
The system prompt can look like a screen-share permission dialog.

SyncWave uses this permission only to capture audio for broadcasting.
If permission is denied/cancelled, SyncWave fails gracefully and does not crash.

## Local-First Networking Rules

Host broadcast start is automatic and does not require selecting a mode.

Broadcast can start when at least one is available:

1. Local private IP (Wi-Fi/hotspot)
2. Connected optional internet signaling session

If neither exists, host start is blocked with a clear message.

Local IP selection priority:

1. Wi-Fi private IPv4
2. Hotspot/tethering private IPv4
3. Other valid private IPv4

Rejected targets:
- `localhost`
- `127.0.0.1`
- `0.0.0.0`
- invalid/loopback/link-local addresses

## Room and PIN Rules

### Room formats
- `LAN-XXXXX`
- `WAN-XXXXX`
- `X` = uppercase alphanumeric (`A-Z`, `0-9`)

### Room PIN
- Optional
- Exactly 6 digits
- Required for join when room is PIN-protected

### Server Connection PIN
- Optional unless server requires it
- 8 to 10 digits
- Used only for server handshake/auth (not room join)

## QR and Join Behavior

SyncWave uses one host QR for join sharing.

Host includes an explicit toggle:
- `Include PIN in QR` (default `OFF`)

When OFF:
- QR/join link excludes room PIN
- joiner is prompted for PIN when required

When ON (PIN-protected room only):
- QR payload includes PIN

Join URL examples:

Local:
- `http://192.168.1.20:9000/stream/join`
- `http://192.168.1.20:9000/stream/join?room=LAN-R12B9`
- `http://192.168.1.20:9000/stream/join?room=LAN-R12B9&pin=123456`

Internet:
- `https://your-server.example.com/stream/join`
- `https://your-server.example.com/stream/join?room=WAN-RM01P`
- `https://your-server.example.com/stream/join?room=WAN-RM01P&pin=123456`

Deep link example:
- `syncwave://join?host=192.168.1.20:9000&room=LAN-R12B9`

## Broadcast Lifecycle Hardening

SyncWave enforces one active broadcast/session per host device.

- Starting a second broadcast while one is active is blocked
- Stop broadcast cleans up capture, local server, relay, timers, and subscriptions
- Re-broadcast works after clean stop
- Host live state reflects:
  - Starting
  - Broadcasting
  - Muted
  - Stopping
  - Stopped
  - Error
- Local network loss / relay disconnection are handled with safe fallback or stop

## Real-time Audio Quality (Current)

Current transport uses PCM16 chunks with metadata and jitter-buffer playback scheduling.

Implemented quality measures:
- stable Android chunk duration target (~40ms @ 48kHz mono)
- sequence/timestamp metadata per chunk
- browser-side jitter buffering and scheduled Web Audio playback
- rebuffer/catch-up behavior for underrun/overrun
- ping/pong RTT status updates

## Optional Internet Signaling

Internet mode remains optional and is off by default.

Settings includes:
- Enable Internet Streaming
- Server URL
- Server Connection PIN
- Save
- Test Connection
- Connect/Disconnect
- Server status card
- Copy WebSocket URL
- Copy Status URL
- Copy Status Details

Supported input forms:
- `https://your-server.example.com`
- `http://your-server.example.com`
- `wss://your-server.example.com/ws`
- `ws://your-server.example.com/ws`

Normalization is internal (not exposed as UX complexity).

## Server (`server/`)

FastAPI server is optional for internet-assisted sessions.

### Endpoints
- `GET /` (redirects to GitHub URL)
- `GET /health`
- `GET /status`
- `GET /stream/join` (browser listener page)
- `WS /ws` (signaling + stream routing)

### Root redirect behavior
- Uses `GITHUB_REDIRECT` if set
- Fallback: `https://github.com/rjrajujha/syncwave`

### Redis
Redis is optional.

- Server runs with in-memory state when Redis is not configured
- `/status` reports `redisConnected`

## Monorepo Structure

```txt
syncwave/
├── apps/
├── server/
├── docker-compose.yml
├── README.md
├── CHANGELOG.md
└── LICENSE
```

## Setup

### Flutter app

```bash
cd apps
flutter pub get
flutter run
```

### Optional signaling server (local)

```bash
cd server
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### Optional Docker local server

```bash
docker compose up signaling-server
```

Optional Redis for local testing:

```bash
docker compose --profile redis up -d redis
```

## Release APK Signing

Template file:
- `apps/android/key.properties.example`

Create local signing file:

```bash
cp apps/android/key.properties.example apps/android/key.properties
```

Fill:
- `storeFile`
- `storePassword`
- `keyAlias`
- `keyPassword`

Build:

```bash
cd apps
flutter build apk --release
```

`key.properties` is ignored and must never be committed.

## CI

GitHub Actions pipeline:

- Flutter job (runs in `apps/`):
  - `flutter pub get`
  - `dart run build_runner build --delete-conflicting-outputs`
  - `flutter analyze`
  - `flutter test`
  - `flutter build apk --debug`

- Backend job (runs in `server/`):
  - `ruff check app tests`
  - `python -m pytest`

CI does not require release signing secrets.

## Validation Commands

### App

```bash
cd apps
flutter pub get
dart run build_runner build
flutter analyze
flutter test
flutter build apk --debug
flutter build apk --release
```

### Server

```bash
cd server
source .venv/bin/activate
python -m pytest
ruff check app tests
```

## Security and Privacy Notes

- No hardcoded production secrets in app code
- Room PIN and Server Connection PIN are separated by purpose
- Server Connection PIN is stored behind a dedicated repository abstraction
- Local join links reject loopback/invalid targets
- PIN inclusion in QR is opt-in (default off)

## Known Limitations

- iOS host broadcasting is not supported in v1.0.0
- Microphone overlay controls are currently marked as coming soon
- Browser listener currently uses PCM-over-WebSocket (works well for local-first use, can be optimized further)
- Large-scale distributed relay requires future infra scaling work

## Roadmap

- transport-level optimization and adaptive bitrate
- deeper synchronization correction
- richer microphone routing/mixing
- desktop host expansion
- larger-scale server deployment patterns

## Credits

Made with ♥ by [R. Jha](https://rjrajujha.github.io)

Source code: [GitHub](https://github.com/rjrajujha/syncwave)
