# SyncWave

SyncWave is a local-first synchronized live audio streaming app.

- Version: `1.1.0`
- Android package/application ID: `dev.rajujha.syncwave`
- Flutter app: `apps/`
- Optional FastAPI signaling/relay server: `server/`
- Source code: <https://github.com/rjrajujha/syncwave>

SyncWave lets an Android device host a live audio broadcast on a nearby Wi-Fi or hotspot network. Nearby devices can join from the mobile app or from a browser listener page. An optional internet server can provide WAN room creation, signaling, and WebSocket audio relay when configured.

## What SyncWave Does

- Captures Android system audio with MediaProjection and Android AudioPlaybackCapture.
- Starts a local HTTP/WebSocket stream on the host device.
- Lets nearby listeners open `/stream/join` in a browser and play live PCM audio with Web Audio API scheduling.
- Generates LAN room codes locally and WAN room codes through the optional server.
- Supports optional 6-digit room PINs.
- Provides QR/join-link payload generation with PIN excluded by default.
- Provides optional FastAPI server endpoints for status, rooms, browser join, and WebSocket signaling.

## Current Implementation Status

| Area | Status |
|---|---|
| Android host capture | Implemented for Android 10+ using MediaProjection + AudioPlaybackCapture. Permission denial is handled without crashing. |
| Local LAN broadcast | Implemented with a local HTTP server and `/stream/audio` WebSocket route. |
| Local browser listener | Implemented at `/stream/join` with jitter buffering and scheduled Web Audio playback. |
| Optional internet server | Implemented in `server/` with `/health`, `/status`, `/rooms`, `/stream/join`, and `/ws`. |
| WAN room codes | Implemented server-side as unique active `WAN-XXXXX` codes in single-instance memory. |
| Redis | Optional. The current server works without Redis, but Redis is not yet used for shared multi-instance room state. |
| In-app listener playback | Not implemented in v1.1.0. The mobile listener flow opens or copies a browser listener link. |
| `syncwave://` links | Generation and parsing exist in Dart services and manual/QR flows. Android OS intent-filter registration is still pending. |
| Server browser WAN listener | Implemented for `platform: web`, including optional Server Connection PIN entry on protected servers. |
| Protected server relay | Implemented. The host relay path now passes the saved Server Connection PIN to `/ws` handshakes. |

## Key Features

- Local-first default behavior.
- Optional internet streaming, disabled by default.
- Broadcast destination selection:
  - LAN only is used when only a private Wi-Fi/hotspot IP is available.
  - Internet only is used when only the optional server is connected and usable.
  - When LAN and internet are both available, the host chooses LAN only, Internet only, or LAN + Internet.
- One active host room/session per device.
- Active broadcasts persist across normal screen navigation, with Return to Room and explicit Stop Broadcast actions.
- Stop/rebroadcast lifecycle cleanup for capture, local server, relay, subscriptions, timers, and room state.
- LAN room code format: `LAN-XXXXX`.
- WAN room code format: `WAN-XXXXX`.
- Room PIN support: optional, exactly 6 digits.
- Server Connection PIN support: optional, 8 to 10 digits, separate from room PIN.
- QR include-PIN toggle: off by default.
- Refreshed Material 3 mobile UI with clearer availability states, active-room actions, Settings, About, and error recovery.
- Updated app icons, web manifest icons, and server favicon from `AppIcons/`.

## Architecture Overview

```txt
syncwave/
├── apps/                  # Flutter app and Android native host capture
├── server/                # Optional FastAPI signaling/relay server
├── docker-compose.yml     # Local development compose file
├── README.md
├── CHANGELOG.md
└── LICENSE
```

### Flutter App

The Flutter app uses Riverpod, GoRouter, Material 3, `phosphor_flutter` icons, QR scanning/generation, secure storage for the optional server PIN, and WebSocket/HTTP clients for server checks and relay setup.

Important app services live under `apps/lib/features/streaming/services/`:

- `LocalSessionServer`: creates one active LAN session and chooses a private local IP.
- `LiveAudioBroadcastService`: starts/stops capture, local stream server, internet relay, timers, and subscriptions.
- `LocalAudioBroadcastServer`: serves `/stream/join`, `/stream/audio`, and local stream metadata.
- `RemoteServerStatusService`: checks `/status` or `/health` and performs the optional WebSocket handshake.
- `WanRoomService`: creates WAN rooms through `POST /rooms`.
- `JoinLinkService` and `RoomDiscoveryService`: build and parse QR, URL, and deep-link targets.

### Android Native Capture

Android native code lives in:

- `apps/android/app/src/main/kotlin/dev/rajujha/syncwave/MainActivity.kt`
- `apps/android/app/src/main/kotlin/dev/rajujha/syncwave/AudioCaptureForegroundService.kt`
- `apps/android/app/src/main/kotlin/dev/rajujha/syncwave/AudioCaptureEventBus.kt`

The host path uses:

- MediaProjection consent.
- Android AudioPlaybackCapture.
- Foreground service type `mediaProjection|microphone`.
- PCM16 mono chunks at 48 kHz, accumulated into stable 40 ms frames before crossing into Flutter.
- Sequence and timestamp metadata sent through a Flutter `EventChannel`.

Android may show a screen-share style permission prompt. SyncWave uses it only for audio capture. If the user cancels or denies it, hosting is rejected cleanly.

### Local Streaming

The Android host starts a local HTTP server, normally on port `9000`, and exposes:

- `GET /` redirects to `/stream/join?room=<room>`
- `GET /status` returns local stream JSON
- `GET /stream/join` serves the browser listener page
- `WS /stream/audio` sends stream metadata, audio chunks, sync events, pongs, and host-stop events

The browser listener uses a slightly deeper default jitter target (`260 ms`), scheduled Web Audio playback, sequence gap detection, and rebuffering recovery to reduce crackling/dropouts while staying low-latency for LAN listening.

### Optional Internet Server

The optional server is a FastAPI app under `server/`.

Server behavior:

- `GET /` redirects to `GITHUB_REDIRECT`, or falls back to `https://github.com/rjrajujha/syncwave`.
- `GET /health` returns basic JSON health.
- `GET /status` returns server status, active rooms, active WebSocket connections, Redis status, protocol version, and auth requirement.
- `POST /rooms` creates a WAN room.
- `GET /rooms/{room_id}` returns room details.
- `GET /stream/join` serves the internet browser listener page with room PIN and optional Server Connection PIN inputs.
- `WS /ws` handles handshake, room lifecycle, sync ping, and stream audio events.

Redis is optional. Without `REDIS_URL`, the server uses in-memory room state and is suitable for single-instance deployments.

## Flutter App Setup

```bash
cd apps
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

Useful validation commands:

```bash
cd apps
flutter pub get
dart run build_runner build
flutter analyze
flutter test
flutter build apk --debug
flutter build apk --release
```

## Server Setup

```bash
cd server
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

Environment template:

```bash
cp server/.env.example server/.env
```

Important env vars:

- `APP_VERSION=1.1.0`
- `WEBSOCKET_PATH=/ws`
- `PROTOCOL_VERSION=1`
- `REQUIRE_SERVER_CONNECTION_PIN=false`
- `SERVER_CONNECTION_PIN=`
- `REDIS_URL=`
- `PIN_HASH_SECRET=change-this-in-production`
- `GITHUB_REDIRECT=https://github.com/rjrajujha/syncwave`

Server validation:

```bash
cd server
source .venv/bin/activate
python -m pytest
ruff check app tests
```

## Docker And Deployment

The root `docker-compose.yml` is for local development.

```bash
docker compose up signaling-server
```

Optional local Redis:

```bash
docker compose --profile redis up -d redis
```

The `server/Dockerfile` is enough for Render-like single-instance deployment. Set production env vars in the hosting platform instead of committing secrets.

For multi-instance deployment, add shared room and connection state before scaling horizontally. The current Redis integration only reports/maintains connectivity and does not yet back room state.

## Local Browser Listener Usage

When hosting on LAN, open one of these from another device on the same Wi-Fi/hotspot:

```txt
http://192.168.1.20:9000/stream/join
http://192.168.1.20:9000/stream/join?room=LAN-R12B9
http://192.168.1.20:9000/stream/join?room=LAN-R12B9&pin=123456
```

The browser page connects to `/stream/audio` by WebSocket and schedules PCM chunks with Web Audio API.

## Optional Internet Signaling Usage

Internet mode stays optional and is disabled by default.

In the app:

1. Open Settings.
2. Enable Internet Streaming.
3. Enter a server URL such as `https://your-server.example.com`.
4. Enter Server Connection PIN only if the server requires it.
5. Save.
6. Test Connection.
7. Connect.
8. Start Broadcast.

If both LAN and internet are available, SyncWave asks where to broadcast: LAN only, Internet only, or LAN + Internet. It does not silently choose a destination in that case.

Supported server URL inputs:

```txt
https://your-server.example.com
http://your-server.example.com
wss://your-server.example.com/ws
ws://your-server.example.com/ws
```

Production deployments should prefer HTTPS/WSS.

## Server Endpoints

| Route | Purpose |
|---|---|
| `GET /` | Redirects to `GITHUB_REDIRECT` or the GitHub source URL. |
| `GET /health` | Basic health JSON. |
| `GET /status` | Detailed SyncWave server status JSON. |
| `POST /rooms` | Create a WAN room. |
| `GET /rooms/{room_id}` | Read WAN room state. |
| `GET /stream/join` | Browser listener page. |
| `WS /ws` | WebSocket handshake, room lifecycle, sync, and stream relay events. |

## Room Naming Rules

- LAN rooms: `LAN-XXXXX`
- WAN rooms: `WAN-XXXXX`
- `XXXXX` is exactly 5 uppercase alphanumeric characters: `A-Z`, `0-9`
- LAN codes are generated locally.
- WAN codes are generated server-side and are unique among active in-memory server rooms.

## PIN Behavior

Room PIN:

- Optional.
- Exactly 6 digits.
- Used to protect a room.
- If enabled, joiners must provide it unless the QR/link explicitly includes it.

Server Connection PIN:

- Separate from room PIN.
- Optional unless the server requires it.
- Must be 8 to 10 digits in the Flutter settings flow.
- Used for server handshake/auth, not room join.

## QR And Deep-Link Behavior

QR/link PIN behavior:

- `Include PIN in QR` defaults to off.
- Normal QR/join links exclude the room PIN.
- If the host explicitly enables PIN inclusion, the room PIN is embedded in the QR/link.

Browser join URLs support:

```txt
/stream/join
/stream/join?room=LAN-R12B9
/stream/join?room=WAN-RM01P&pin=123456
```

Deep-link target format:

```txt
syncwave://join?host=192.168.1.20&port=9000&room=LAN-R12B9
syncwave://join?host=your-server.example.com&port=443&room=WAN-RM01P
```

The Dart parser accepts both `host:port` inside `host=` and the separate `port=` query parameter. Android OS-level intent-filter launch handling is still pending, so `syncwave://` links are production-ready inside manual/QR parsing but not yet as OS app links.

Rejected join targets include:

- `localhost`
- `127.0.0.1`
- `0.0.0.0`
- invalid loopback/link-local targets

## Stop And Re-broadcast Behavior

SyncWave enforces one active broadcast/session per host device.

In v1.1.0, leaving the live room screen or backgrounding/foregrounding the app does not intentionally stop a valid broadcast. Home shows an active broadcast card with Return to Room and Stop Broadcast actions. Stop Broadcast asks for confirmation.

Stop broadcast is intended to clean up:

- Android audio capture.
- Foreground service.
- Local HTTP/WebSocket stream server.
- Optional internet relay WebSocket.
- Listener count subscriptions.
- Capture event/chunk subscriptions.
- Network watchdog timer.
- Local session state.

Tests cover the active-session guard and stop/rebroadcast lifecycle.

## Release APK Signing

Template:

```txt
apps/android/key.properties.example
```

Create a local signing file:

```bash
cp apps/android/key.properties.example apps/android/key.properties
```

Fill:

- `storeFile`
- `storePassword`
- `keyAlias`
- `keyPassword`

Example keystore generation:

```bash
cd apps/android
keytool -genkeypair \
  -v \
  -keystore release-keystore.jks \
  -storetype PKCS12 \
  -keyalg RSA \
  -keysize 4096 \
  -sigalg SHA256withRSA \
  -validity 20000 \
  -alias upload
```

Build:

```bash
cd apps
flutter build apk --release
```

`apps/android/key.properties`, `*.jks`, and `*.keystore` are ignored and must not be committed. If `key.properties` is missing, the current Gradle config falls back to debug signing so local release builds can complete; production releases must use a real upload/release keystore.

## CI And Testing

GitHub Actions runs:

Flutter job in `apps/`:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

Backend job in `server/`:

```bash
python -m pip install --upgrade pip
pip install -r requirements.txt
pip install ruff
ruff check app tests
python -m pytest
```

Current v1.1.0 validation in this workspace:

- Backend Ruff and Pytest passed.
- Flutter analyze and Flutter tests passed.
- Debug and release APK builds passed locally.
- Physical Android audio validation and production signing verification are still required before public distribution.

## Security And Privacy Notes

- LAN mode does not require an external server.
- Android capture requires explicit OS consent.
- Room PIN and Server Connection PIN have separate purposes.
- Room PINs are not included in QR/link payloads by default.
- Server room PINs are hashed with `PIN_HASH_SECRET`.
- Production servers must override `PIN_HASH_SECRET`.
- Production servers should use HTTPS/WSS.
- No production secrets should be committed.
- The optional server currently keeps active room state in memory unless future shared state is added.

## Known Limitations

- iOS is listener-first; iOS hosting is not supported in v1.1.0.
- Native in-app listener playback is not implemented yet; listener flow relies on browser playback.
- Android OS-level `syncwave://` intent filters are not yet registered.
- Browser audio uses PCM-over-WebSocket, which is bandwidth-heavy compared with Opus/WebRTC.
- Browser listener transport is still JSON/base64 PCM; binary frames, Opus, and WebRTC remain future transport work.
- Large multi-instance server deployments need shared state and routing work.
- Some Android apps do not allow their audio to be captured by AudioPlaybackCapture.
- Microphone overlay controls are currently marked as coming soon.

## Roadmap

- Opus/WebRTC transport optimization.
- Binary streaming frames.
- Improved drift and delay synchronization.
- Native in-app listener playback.
- iOS listener polish.
- Microphone mixing and controls.
- Redis-backed multi-instance server state.
- TURN/STUN or WebRTC deployment path for broader networks.
- Play Store and App Store release preparation.

## Credits

Made with love by [R. Jha](https://rjrajujha.github.io)

Source code: [GitHub](https://github.com/rjrajujha/syncwave)
