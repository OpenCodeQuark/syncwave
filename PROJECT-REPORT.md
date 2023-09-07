# SyncWave Project Report

## Executive Summary

SyncWave is now prepared as a v1.1.0 update for local-first Android hosting, LAN browser listening, and optional single-instance WAN relay. The Flutter app lives in `apps/`, the optional FastAPI server lives in `server/`, and the Android package/application ID remains `dev.rajujha.syncwave`.

The strongest implemented path is Android host -> local HTTP/WebSocket stream -> browser listener at `/stream/join`. Android native capture uses MediaProjection and AudioPlaybackCapture, the local stream server emits PCM16 chunks with sequence/timestamp metadata, and the browser listener performs jitter buffering and scheduled playback through Web Audio API.

The optional internet server is structurally present and test-covered for room lifecycle, WebSocket handshake, room creation, stream event routing, status, health, root redirect, browser listener join, and protected Server Connection PIN handshakes. It is currently best described as single-instance ready. Redis is optional, but not yet used for distributed room state.

The v1.1.0 release closes the highest-risk WAN/browser and lifecycle gaps from the v1.0.0 baseline: `platform: web` is accepted, protected relay startup passes the saved Server Connection PIN, hosts explicitly choose the broadcast destination when LAN and internet are both available, and active broadcasts are no longer stopped by normal screen disposal. Remaining release risks are Android OS-level `syncwave://` launch handling, PCM/base64 transport efficiency, and lack of Redis-backed shared room state.

## Current Architecture

### Flutter App

The Flutter app is in `apps/` and uses:

- Riverpod for dependency injection/state.
- GoRouter for app routing.
- Material 3 UI.
- `phosphor_flutter` for app icons.
- `qr_flutter` and `mobile_scanner` for QR generation/scanning.
- `shared_preferences` and `flutter_secure_storage` for local settings and Server Connection PIN storage.
- `http` and `web_socket_channel` for optional server status, room creation, and relay WebSocket communication.

Important runtime services:

- `LocalSessionServer` creates one LAN room at a time and selects a private Wi-Fi/hotspot IPv4 address.
- `StreamingCoordinator` resolves LAN/WAN availability and creates LAN only, internet only, or LAN + internet sessions based on explicit host choice when both destinations are available.
- `LiveAudioBroadcastService` owns the runtime broadcast lifecycle, including Android capture, local stream server, internet relay, timers, subscriptions, mute state, active session state, explicit stop, and rebroadcast.
- `LocalAudioBroadcastServer` serves local browser listener HTML and the local audio WebSocket.
- `RemoteServerStatusService` normalizes server URLs, checks `/status` or `/health`, and performs server WebSocket handshakes.
- `WanRoomService` creates WAN rooms through `POST /rooms`.
- `JoinLinkService` and `RoomDiscoveryService` build and parse QR, browser URL, manual, and `syncwave://` payloads.

### Android Native Capture

Android native capture lives under `apps/android/app/src/main/kotlin/dev/rajujha/syncwave/`.

- `MainActivity.kt` exposes method and event channels.
- `AudioCaptureForegroundService.kt` starts a foreground service, builds an `AudioRecord`, and captures PCM16 audio.
- `AudioCaptureEventBus.kt` sends capture events and audio chunks to Flutter.

Capture behavior:

- Requires Android 10+ for system audio capture.
- Uses MediaProjection consent.
- Uses `AudioPlaybackCaptureConfiguration` for media/game/unknown usages.
- Emits mono 48 kHz PCM16 chunks accumulated to stable 40 ms frames.
- Emits sequence number, capture timestamp, host timestamp, duration, sample rate, channel count, and stream start metadata.
- Stops and releases `AudioRecord`, MediaProjection, foreground notification, and stored projection permission on stop.

### Local Streaming Server

`LocalAudioBroadcastServer` binds a local HTTP server to `InternetAddress.anyIPv4`, usually port `9000`.

Routes:

- `GET /` redirects to `/stream/join?room=<room>`.
- `GET /status` returns local stream metadata.
- `GET /stream/join` serves a self-contained browser listener.
- `WS /stream/audio` validates room and PIN, accepts browser listeners, sends `stream.meta`, `stream.audio`, `stream.sync`, `stream.pong`, listener count, and host-stop events.

The local browser listener decodes base64 PCM16, converts it to Float32, queues buffers, and schedules playback ahead of the current audio clock.

### Optional Internet Server

The optional server is under `server/` and uses FastAPI.

Implemented services:

- `RoomService`: in-memory WAN room lifecycle, PIN hash/verify, TTL, participant list, uniqueness among active rooms.
- `SignalingService`: room create/join/leave, sync ping, stream host start/stop, listener join, audio chunk routing, stream ping.
- `ConnectionManager`: active WebSocket connections and room membership routing.
- `RedisService`: optional Redis connectivity, currently not room-state backing.
- `WebSocketEventHandler`: connection readiness, `server.hello` handshake, optional Server Connection PIN, protocol version checks, typed error responses.

Server routes:

- `GET /`
- `GET /health`
- `GET /status`
- `POST /rooms`
- `GET /rooms/{room_id}`
- `GET /stream/join`
- `WS /ws`

### Browser Listener

Two browser listener implementations exist:

- Local listener generated by the Android-hosted local server.
- Server listener served from FastAPI at `/stream/join`.

Both use WebSocket + Web Audio API and include room input, optional PIN input, connect/play controls, volume, buffer, and RTT display.

The local listener path remains the strongest path. The server listener sends `platform: web` during `room.join`, and the backend `Peer` model now accepts `web`. Protected servers can require a Server Connection PIN; the browser listener includes an optional Server Connection PIN field before `server.hello`.

### WebSocket Protocol

Server WebSocket flow:

1. Client connects to `/ws`.
2. Server sends `connection.ready`.
3. Client sends `server.hello`.
4. Server validates protocol version and optional Server Connection PIN.
5. Server sends `server.ready`, `server.auth_required`, `server.auth_failed`, or `server.unsupported_version`.
6. Accepted clients can send room, sync, and stream events.

Stream event examples:

- `stream.host_start`
- `stream.host_stop`
- `stream.listener_join`
- `stream.audio_chunk`
- `stream.ping`
- `stream.pong`

Local stream WebSocket flow:

1. Browser connects to `/stream/audio?room=<room>&pin=<pin>`.
2. Server validates room/PIN.
3. Server sends `stream.meta`.
4. Host capture chunks are forwarded as `stream.audio`.
5. Periodic sync metadata is sent as `stream.sync`.
6. Host stop sends `stream.host_stopped`.

### Room, PIN, And Deep-Link System

Room codes:

- LAN: `LAN-XXXXX`
- WAN: `WAN-XXXXX`
- Five-character suffix is uppercase alphanumeric.

Room PIN:

- Optional.
- Exactly 6 digits in the app/local flow.
- Server hashes room PINs with `PIN_HASH_SECRET`.

Server Connection PIN:

- Separate from room PIN.
- Flutter settings validation requires 8 to 10 digits.
- Server can require it during `server.hello`.

QR/link behavior:

- PIN is excluded by default.
- Host can explicitly enable `Include PIN in QR`.
- QR payloads include room, host/server, stream paths, version/protocol metadata, and optional PIN.

Deep-link status:

- Dart generation/parsing exists.
- Manual join and QR flows can parse `syncwave://` strings.
- Android manifest does not currently register a `syncwave://` intent filter.
- Parser accepts both `host:port` in the `host` query parameter and a separate `port=` query parameter.

## Implemented Features

### Mobile App

- Onboarding, home, host, join, room, settings, about, and debug screens.
- Local-first host flow.
- Optional internet server settings.
- Server test/connect/disconnect UI.
- Server URL normalization from HTTP(S) to WS(S).
- Server status display and copy actions.
- LAN/WAN host session coordination.
- Room PIN entry and validation.
- QR generation and scanning.
- Manual join parsing.
- Browser listener link copy/open flow.
- Host status, listener count, mute control, active room return, and confirmed stop control.

### Android Native

- Package/application ID: `dev.rajujha.syncwave`.
- MediaProjection permission request.
- Foreground capture service.
- AudioPlaybackCapture for system audio.
- PCM16 chunk metadata.
- Foreground notification.
- Stop/release cleanup.
- Permission denial/cancel path.

### Local Streaming

- Local HTTP server.
- `/stream/join` browser page.
- `/stream/audio` WebSocket stream.
- `/status` local status JSON.
- Room mismatch rejection.
- PIN format validation and protected room enforcement.
- Listener count stream.
- Host-stop notification.
- Sync and ping/pong metadata.

### Browser Listener

- Mobile-friendly HTML/CSS.
- Room/PIN inputs.
- WebSocket connect/reconnect behavior.
- Web Audio API playback.
- PCM16 decoding.
- Jitter buffer and scheduled playback.
- Buffer and RTT display.
- Volume control.

### Optional Server

- FastAPI app factory and global error handlers.
- CORS middleware.
- Health and status routes.
- GitHub/project redirect.
- WAN room creation and room lookup.
- Unique active WAN room code generation.
- Optional Server Connection PIN handshake.
- Protocol version check.
- WebSocket room lifecycle and stream routing.
- Single-instance in-memory state.
- Dockerfile and Procfile.

### UI/UX

- Clean Material 3 mobile-first screens.
- Consistent `phosphor_flutter` icon use in Flutter screens.
- About page includes project purpose, platform note, roadmap, creator link, and GitHub link.
- Settings keeps internet streaming framed as optional.
- PIN inclusion in QR is explicit and off by default.

### Tests/CI

- Flutter unit/widget tests exist under `apps/test`.
- Backend tests exist under `server/tests`.
- CI runs Flutter dependency restore, codegen, format check, analyze, tests, and debug APK build.
- CI runs backend dependency install, Ruff, and Pytest.

### Docs/Deployment

- Root `README.md` updated for public release accuracy.
- Root `CHANGELOG.md` updated for v1.1.0.
- `PROJECT-REPORT.md` created.
- `server/Dockerfile` supports Render-like deployment.
- `docker-compose.yml` supports local server and optional Redis.
- `.gitignore` now allows `.env.example` templates to be tracked.

## Configuration Alignment

| Item | Current State | Alignment |
|---|---|---|
| App version | `apps/pubspec.yaml` has `version: 1.1.0`; `AppConfig` default is `1.1.0`; server env default is `1.1.0`. | Aligned. |
| Android package ID | `namespace` and `applicationId` are `dev.rajujha.syncwave`. | Aligned. |
| Folder structure | Flutter app is `apps/`; server is `server/`; no `services/signaling-server/` directory exists. | Aligned with intended current structure. |
| CI paths | `.github/workflows/ci.yml` runs Flutter in `apps/` and backend in `server/`. | Aligned. |
| Server path | `server/` contains FastAPI app, tests, Dockerfile, Procfile, requirements, pyproject. | Aligned. |
| Docker | Root compose builds `./server`; `server/Dockerfile` runs `uvicorn app.main:app`. | Aligned for local/single-instance deployment. |
| Env vars | `server/.env.example` exists with expected values. Previous ignore pattern hid it; `.gitignore` now permits examples. | Mostly aligned; ensure `server/.env.example` is committed. |
| Release signing | `apps/android/key.properties.example` exists; Gradle reads `apps/android/key.properties`; secrets ignored. | Aligned. Production must not rely on debug fallback. |
| Room naming | Dart validates/generates LAN; server validates/generates WAN. Legacy `SW-XXXX-XX` parsing still exists. | Mostly aligned; decide whether to keep or remove legacy support. |
| PIN rules | App validates room PIN as exactly 6 digits and Server Connection PIN as 8 to 10 digits. Local stream and server room creation enforce 6-digit room PINs. | Aligned. |
| Join routes | Local `/stream/join`, local `/stream/audio`, server `/stream/join`, server `/ws`. | Aligned. |
| Root redirect | Server `/` uses `GITHUB_REDIRECT` fallback. | Aligned. |
| Redis | Optional and non-fatal when absent. | Aligned for single instance, not yet for horizontal scaling. |

## Quality And Production Readiness Review

### Error Handling

Strengths:

- FastAPI has global handlers for HTTP, validation, and unhandled exceptions.
- WebSocket handler returns typed errors for invalid schemas and room failures.
- Android MediaProjection cancel/deny returns user-facing app errors.
- Broadcast start failures call cleanup before surfacing the error.

Risks:

- Server `POST /rooms` catches every exception and returns HTTP 409, including validation-like and unexpected errors.
- Server room PIN format is not enforced at API/service level.
- WAN browser listener is now covered for `platform: web`; protected servers still require the listener to enter the Server Connection PIN when configured.

### Lifecycle Cleanup

Strengths:

- Stop flow cancels watchdog, relay subscription, capture events, chunk subscription, listener count subscription.
- Stop flow calls Android stop capture, local server stop, and internet relay disconnect.
- Local server notifies listeners with `stream.host_stopped`.
- Tests cover stop/rebroadcast.

Risks:

- The live room screen no longer stops hosting from `dispose()`. Active session state remains in the broadcast service until explicit stop.
- Settings server WebSocket connection and relay WebSocket are separate; lifecycle semantics should be clarified when hosting with internet enabled.

### Security/Privacy

Strengths:

- Local-first operation avoids mandatory cloud dependency.
- Android capture requires explicit OS consent.
- Room PIN inclusion in QR is opt-in.
- Room PIN and Server Connection PIN are separate in the app.
- Server room PINs are hashed with a configurable secret.

Risks:

- Production `PIN_HASH_SECRET` must be changed.
- Server room creation endpoint is unauthenticated over HTTP API.
- Server room PIN format is not enforced.
- Server Connection PIN does not protect `POST /rooms`.
- Local `.vscode/cmd.txt` contains signing/password-like material and must remain ignored/untracked.

### Scalability

Current server is suitable for a single instance. Active rooms and connection routing are process-local. Redis connectivity is optional, but Redis is not yet used for shared rooms, peer routing, pub/sub, or stream fanout.

### Audio Quality

Current audio path is reasonable for local-first validation:

- PCM16 mono.
- 48 kHz.
- Stable 40 ms chunks accumulated on the native capture thread.
- Sequence/timestamp metadata.
- Browser jitter buffer.
- Scheduled playback.
- Basic RTT display.

Limitations:

- PCM-over-JSON/base64 WebSocket is bandwidth-heavy.
- No Opus compression.
- No binary frames.
- No WebRTC jitter/packet-loss machinery.
- No adaptive bitrate.
- Drift correction is still basic, but sequence-gap handling and browser rebuffering are smoother in v1.1.0.

### Browser Support

Modern Chromium/Safari/Firefox-style browsers with Web Audio API should work for the local listener. Autoplay restrictions require user interaction or audio context resume, which the page attempts during connect/play.

WAN browser listener is compatible with `platform: web` and can connect to protected servers when the Server Connection PIN is entered on the listener page.

### Server Readiness

The server is deployment-ready for a single instance with a process-local room map. Dockerfile and Procfile are straightforward. Health and status are present. Root redirect is configurable.

Before public internet use, add:

- Production env settings.
- HTTPS/WSS deployment.
- Room PIN validation.
- Server-auth story for room creation and relay.
- Multi-instance design if scaling beyond one process.

### Release Readiness

Debug APK build is CI-covered. Release signing config exists, but local production signing secrets are not committed. Android release builds may fall back to debug signing when no key exists, so production release validation must explicitly confirm a real keystore is used.

## Known Issues / Risks

- Android OS-level `syncwave://` deep links are not registered in `apps/android/app/src/main/AndroidManifest.xml`; only the launcher intent filter exists.
- `POST /rooms` is not protected by Server Connection PIN.
- Redis is optional but not backing shared room state, so multi-instance deployments will split room state by process.
- Browser audio transport is PCM/base64/JSON over WebSocket and may glitch or consume high bandwidth on weak networks.
- Native in-app listener playback is not implemented.
- iOS hosting is not supported.
- Some Android apps opt out of AudioPlaybackCapture and will not be captured.
- Microphone overlay controls are marked coming soon.
- Generated/ephemeral Flutter artifacts appear in tracked files, including Linux/Windows plugin symlink paths and Android `GeneratedPluginRegistrant.java`; review repo hygiene before release.
- `server/.venv/` exists locally and is ignored, as expected.
- The current local `server/.venv` console scripts are stale from the old `services/signaling-server` path; validation used `.venv/bin/python -m pytest` and `.venv/bin/ruff` successfully.
- `AppIcons/` is currently untracked.

## Recommended Fixes Before Public Release

### Critical

- Add Android `syncwave://` intent filter and app launch handling, or clearly remove OS deep-link claims.
- Ensure `server/.env.example` is tracked after the `.gitignore` change.

### Important

- Decide whether legacy `SW-XXXX-XX` room code parsing should remain public.
- Protect or rate-limit `POST /rooms` for public internet deployments.
- Add a release-signing CI/manual verification step that fails if debug signing is used for production.
- Remove tracked generated/ephemeral Flutter artifacts from git in a separate cleanup commit.
- Add cleartext/network-security guidance if supporting `http://` or `ws://` Android server URLs outside local development.

### Nice To Have

- Add native in-app listener playback.
- Add richer host/listener telemetry.
- Improve UI density and reduce repeated explanatory text after first-run onboarding.
- Add browser compatibility smoke tests.
- Add load tests for server room fanout.
- Add structured protocol docs.

## Testing And Validation Plan

Flutter app:

```bash
cd apps
flutter pub get
dart run build_runner build
flutter analyze
flutter test
flutter build apk --debug
flutter build apk --release
```

Server:

```bash
cd server
source .venv/bin/activate
python -m pytest
ruff check app tests
```

The server is currently under `server/`. The old `services/signaling-server/` path is not present and should not be used in current docs or CI.

Local note from this workspace: if `python` or `pytest` fails after activating `server/.venv`, recreate the venv because the existing ignored venv may still contain console scripts from the old backend path.

Additional manual validation:

- Host from a physical Android 10+ device.
- Deny MediaProjection and verify the app does not crash.
- Host over Wi-Fi and join from another device browser at `/stream/join`.
- Host over hotspot and join from another device browser.
- Test protected room with PIN excluded from QR and verify joiner prompt.
- Test protected room with PIN included in QR.
- Configure optional server and verify `/health`, `/status`, `/stream/join`, and `/ws`.
- Test WAN room creation and browser listener join with `platform: web`.
- Test protected WAN listener and host relay with Server Connection PIN.
- Use Back/Home/background/foreground during an active broadcast, then Return to Room and Stop Broadcast explicitly.
- Stop broadcast and immediately rebroadcast.
- Background/foreground the app during hosting.

## Release Checklist

- README accurate.
- CHANGELOG accurate.
- CI passing.
- Flutter analyze passing.
- Flutter tests passing.
- Backend Ruff passing.
- Backend Pytest passing.
- Debug APK builds.
- Release APK builds.
- Release signing configured with real keystore.
- Server deploy tested.
- Browser listener tested on LAN.
- Browser listener tested on WAN after web platform fix.
- Android capture tested on physical Android 10+.
- MediaProjection denied/cancelled path tested.
- Stop/rebroadcast tested on device.
- Room PIN behavior tested.
- Server Connection PIN behavior tested for status and relay.
- No secrets committed.
- `server/.env.example` committed.
- Only one root README and one root `.gitignore` in public docs.
- Generated/ephemeral artifacts reviewed.

## Roadmap

- Opus/WebRTC optimization.
- Binary streaming frames.
- Improved sync, drift correction, and delay calibration.
- Native in-app listener playback.
- iOS listener polish.
- Microphone routing, mixing, and controls.
- Redis-backed multi-instance room state.
- Pub/sub or media relay scaling for multi-instance server deployments.
- Better browser compatibility testing.
- Play Store/App Store release preparation.
