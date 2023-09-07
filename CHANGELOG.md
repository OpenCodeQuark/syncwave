# Changelog

## 1.1.0 - Broadcast Control Refresh

### Added

- Explicit broadcast destination selection when LAN and internet are both available:
  - LAN only / Nearby Wi-Fi or Hotspot
  - Internet only / WebSocket server
  - LAN + Internet using the existing dual local + relay architecture
- Persistent active broadcast state with Home screen Return to Room and Stop Broadcast actions.
- Stop Broadcast confirmation from both Home and the live room screen.
- Server browser listener support for optional Server Connection PIN entry.
- Server favicon route and refreshed app/web/platform icons from `AppIcons/`.
- Tests for route selection, active session persistence, relay PIN pass-through, WAN browser `platform: web`, room PIN validation, URL normalization, and version `1.1.0`.

### Changed

- App, server, env defaults, docs, tests, and desktop fallback metadata now report version `1.1.0`.
- Android capture now accumulates stable 40 ms PCM16 frames on an audio-priority thread before sending chunks to Flutter.
- Browser listener buffering defaults now target `260 ms` with smoother sequence-gap rebuffering.
- Server URL normalization maps pasted `/stream/join`, `/status`, and `/health` URLs back to `/ws` for signaling.
- `syncwave://` parsing now supports a separate `port=` query parameter while keeping existing `host:port` compatibility.
- Full internet `/stream/join` URLs can be used from manual join without requiring the app to already be connected in Settings.
- UI theme, cards, spacing, active-room affordances, and web manifest metadata were refreshed for a cleaner Material 3 experience.
- Backend CI now invokes Ruff through `python -m ruff` after installing dependencies through `python -m pip`.

### Fixed

- WAN browser listeners can join rooms as `platform: web` instead of failing backend peer validation.
- Protected internet relay startup now passes the saved Server Connection PIN into `InternetAudioRelayService.connect`.
- Navigating away from the live room screen no longer stops an ongoing broadcast implicitly.
- Bare WAN room codes are parsed as internet targets instead of local targets.
- Server room creation now rejects invalid room PIN formats.

### Known Limitations

- Native in-app listener playback is still not implemented; listener flows still open/copy browser listener links.
- Android OS-level `syncwave://` intent-filter launch handling remains pending.
- Browser transport remains JSON/base64 PCM over WebSocket; binary frames, Opus, and WebRTC are still roadmap work.
- Redis is still not backing shared multi-instance room state.
- Microphone mixing/overlay controls remain marked as coming soon.
- Audio quality still requires physical Android validation across apps that opt in/out of AudioPlaybackCapture.

## 1.0.0 - Public Release Baseline

### Added

- Local-first SyncWave architecture with Flutter app in `apps/` and optional FastAPI server in `server/`.
- Android host broadcasting path using MediaProjection, AudioPlaybackCapture, and a foreground capture service.
- Local LAN stream server with:
  - `GET /stream/join`
  - `WS /stream/audio`
  - local `/status`
- Browser listener page with WebSocket playback, Web Audio API scheduling, jitter buffering, buffer/latency display, and play/volume controls.
- Optional FastAPI signaling/relay server with:
  - `GET /`
  - `GET /health`
  - `GET /status`
  - `POST /rooms`
  - `GET /rooms/{room_id}`
  - `GET /stream/join`
  - `WS /ws`
- Server root redirect via `GITHUB_REDIRECT`, with fallback to `https://github.com/rjrajujha/syncwave`.
- LAN room code generation as `LAN-XXXXX`.
- WAN room code generation as unique active `WAN-XXXXX` codes on the server.
- Optional room PIN support in app and local stream join flow.
- Separate Server Connection PIN settings and WebSocket handshake support.
- QR/join payload generation with explicit `Include PIN in QR` behavior, defaulting to PIN excluded.
- Manual and QR join parsing for room codes, browser URLs, structured QR payload JSON, and `syncwave://` link strings.
- Settings screen for optional internet streaming URL, Server Connection PIN, test/connect/disconnect, and copy status actions.
- About screen with project summary, platform note, roadmap, creator link, and GitHub link.
- Release signing template at `apps/android/key.properties.example`.
- CI workflow for Flutter analyze/test/debug APK build and backend lint/test.

### Changed

- Backend path is now `server/`; `services/signaling-server/` is no longer present.
- Docker Compose now targets `./server` and is intended for local development.
- Internet mode is gated by both settings and successful server handshake instead of being presented as a manual network-mode choice.
- Host lifecycle now blocks a second active broadcast on the same device.
- Stop flow now cleans up capture, local server, internet relay, timers, and subscriptions before allowing rebroadcast.
- Android audio chunking targets stable PCM16 mono frames around 40 ms at 48 kHz.
- Browser playback uses chunk metadata, sequence checks, jitter buffering, scheduled playback, and ping/pong RTT display.

### Fixed

- Configuration drift between documented backend path and current `server/` layout.
- Root server route now redirects to the configured GitHub/project URL.
- Local listener PIN enforcement rejects missing or invalid room PINs when a local stream is protected.
- Room creation now rejects duplicate active WAN room codes.
- Broadcast restart after stop is covered by tests.

### Tests And CI

- Flutter tests cover:
  - version default
  - LAN/WAN room code validation
  - room PIN and Server Connection PIN validation
  - server URL normalization
  - internet mode gate
  - QR/join-link behavior
  - local broadcast server routes and WebSocket events
  - live broadcast active-session and stop/rebroadcast behavior
  - streaming coordinator LAN/WAN fallback behavior
  - settings/status formatting behavior
- Backend tests cover:
  - root redirect and env override
  - health/status routes
  - stream join route
  - structured error handling
  - WAN room code generation, uniqueness, cleanup, and validation
  - WebSocket handshake/auth/version checks
  - room create/join/leave
  - stream ping and audio chunk routing
  - disconnect cleanup and listener count updates

### Known Limitations

- iOS remains listener-first; iOS host capture is not supported.
- Native in-app listener audio playback is not implemented yet; listener flow currently points to browser playback.
- Android OS-level `syncwave://` intent-filter registration is pending, although parsing/generation exists in Dart services.
- Current `syncwave://` parsing expects `host:port` inside the `host` query value and should be updated to also honor a separate `port=` query parameter.
- Server browser WAN listener needs a `platform: web` compatibility fix before it is production-ready.
- Server Connection PIN is used by settings/status WebSocket handshakes, but the host audio relay path still needs PIN pass-through for protected servers.
- Redis is optional and connected only as a service dependency; shared multi-instance room state is not implemented.
- Browser transport is PCM-over-WebSocket; Opus, binary frames, and WebRTC remain future optimizations.
