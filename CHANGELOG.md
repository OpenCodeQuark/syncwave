# Changelog

## 1.0.0 - Local-First Live Broadcast Release

### Added
- Android live host capture pipeline:
  - MediaProjection permission flow
  - AudioPlaybackCapture-based system audio capture
  - foreground broadcast service lifecycle
  - optional microphone overlay path
- Local audio broadcast server for LAN/hotspot sessions with browser listener endpoint (`/stream/join`, `/stream/audio`).
- Automatic host networking behavior:
  - private IPv4 interface selection priority (Wi-Fi -> hotspot -> other private)
  - host-block messaging when no valid local IP and no connected internet signaling server.
- Single QR strategy with `syncwave://join` deep links.
- Copy actions in live room for join link and room code.
- `syncwave://` parser support with host/room/pin validation and loopback rejection.
- About/Info screen with project scope, roadmap, and credits.
- Optional backend status routes:
  - `GET /`
  - `GET /health`
  - `GET /status`
- Optional internet signaling handshake protocol events:
  - `server.hello`
  - `server.ready`
  - `server.auth_required`
  - `server.auth_failed`
  - `server.unsupported_version`
  - `error`
- Server/browser integration dependency additions:
  - `url_launcher`
  - `phosphor_flutter`

### Changed
- App version standardized at `1.0.0` for the local-first live foundation release.
- Host create flow simplified:
  - removed manual local/internet mode selector
  - replaced source selection UI with two user toggles (`Audio Source`, `Microphone`)
  - enforced at-least-one-source validation before start.
- Host live screen upgraded from placeholder state to active broadcast runtime status.
- Join flow updated for single-QR/deep-link architecture and improved parser coverage.
- Settings UI simplified (clean URL input, internal normalization retained).
- Optional server connection handling hardened for user-friendly failures and websocket lifecycle safety.
- Optional signaling backend now supports Redis-off operation by default (in-memory fallback with status reporting).
- Docker compose signaling service decoupled from hard Redis dependency.

### Fixed
- Resolved websocket lifecycle issue that could trigger `Bad state: Stream has already been listened to` during connection checks/connect flow.
- Improved backend disconnect cleanup and typed error emission paths for room/sync/handshake flows.

### Tests
- Added/updated Flutter tests for:
  - deep link parsing (`syncwave://`) and localhost rejection
  - join URL parsing edge cases
  - room PIN and server connection PIN validation
  - server URL normalization + status URL derivation
  - server handshake/auth state handling
  - broadcast source validation guard
  - internet availability gating
- Backend tests cover:
  - root/health/status routes
  - websocket connect/handshake variants
  - room create/join/leave lifecycle
  - sync ping/pong
  - invalid event schema handling
  - disconnect cleanup broadcasts

## Planned - 2.0.0

- Advanced WebRTC transport optimizations
- Adaptive bitrate and sync correction improvements
- Enhanced microphone mixing/routing controls
- TURN/STUN scaling and distributed relay hardening
- Expanded desktop broadcasting support
