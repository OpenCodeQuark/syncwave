# Changelog

## 1.0.0 - Local-First Foundation Release

### Added
- Local-first session foundation with default offline/local operation.
- Host network preflight and local IPv4 selection priority:
  - Wi-Fi private IPv4
  - Hotspot/tethering private IPv4
  - Other valid private IPv4
- Local hosting block when no usable LAN/hotspot endpoint is available.
- Room PIN validation (`6` digits, numeric) across host/join/URL/QR flows.
- Server Connection PIN model (`8-10` digits, numeric) for optional internet server handshake.
- Optional internet server status probing service:
  - URL normalization (`http/https/ws/wss` -> normalized websocket URL)
  - Derived `/status` URL generation
  - `/status` + `/health` HTTP checks
  - Optional websocket handshake check
- Internet connection controller/state for:
  - Not configured
  - Invalid URL
  - Checking
  - Reachable
  - Connected/disconnected
  - Auth required/auth failed
  - WebSocket failed
  - Not SyncWave server
- Backend public status routes:
  - `GET /`
  - `GET /health`
  - `GET /status`
- Backend handshake protocol events:
  - `server.hello`
  - `server.ready`
  - `server.auth_required`
  - `server.auth_failed`
  - `server.unsupported_version`
- Two QR strategy in host flow:
  - App QR (structured JSON for SyncWave app)
  - Browser URL QR (plain URL, no Room PIN included by default)
- Real QR scanner ingestion flow using camera scanner (replacing simulation-only path).

### Changed
- App/project version set to `1.0.0`.
- Internet broadcast availability now requires:
  - internet mode enabled
  - valid server URL
  - reachable server
  - websocket connected
  - successful handshake/authentication
- Backend websocket lifecycle hardened:
  - disconnect cleanup removes participant state
  - participant-left and room-closed broadcasts emitted on disconnect paths
- Backend error typing hardened:
  - `room.create_failed`
  - `room.join_failed`
  - `room.leave_failed`
  - `sync.failed`
  - generic `error`
- Replaced hardcoded route strings with route-path helpers.
- Updated onboarding/host/room copy to keep v1 scope honest (no live audio claim).

### Tests
- Added/updated Flutter tests for:
  - app version constant
  - Room PIN and Server Connection PIN validation
  - server URL normalization and status URL derivation
  - remote server status parsing and handshake/auth states
  - internet broadcast availability gating
  - app/browser QR generation behavior
  - join URL parser edge cases
  - settings controller validation and persistence flow
- Expanded backend tests for:
  - `GET /`, `GET /health`, `GET /status`
  - websocket handshake success/auth-required/auth-failed/unsupported-version
  - room create/join/leave success flows
  - sync ping/pong
  - invalid event schema handling
  - disconnect cleanup broadcasts

## Planned - 2.0.0

- Live audio capture and real broadcasting
- Microphone/system audio source pipeline
- WebRTC audio media transport and playback path
