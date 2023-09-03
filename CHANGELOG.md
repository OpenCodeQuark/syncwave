# Changelog

## 1.0.0 - Public Release Hardening

### Added
- Local-first Android host broadcasting foundation with live capture lifecycle.
- LAN/WAN room code model:
  - `LAN-XXXXX`
  - `WAN-XXXXX`
- QR and join architecture updates:
  - structured app QR payload support
  - explicit `Include PIN in QR` host toggle (default OFF)
  - copy link defaults that keep PIN excluded unless explicitly requested
- Host live controls:
  - sound mute/unmute control for active broadcast
  - microphone control marked honestly as coming soon
- Browser listener polish for local and internet routes:
  - clean mobile-first page
  - status, play/pause, volume, buffer/latency hints
  - branded footer with creator and GitHub link
- Server root redirect configurability via `GITHUB_REDIRECT`.
- Additional lifecycle and protocol tests for broadcast/session behavior.

### Changed
- Moved backend from `services/signaling-server/` to `server/`.
- Updated CI and project path references to use `server/` and `apps/`.
- Updated Docker Compose to build from `./server` and use `./server/.env.example`.
- CI Flutter pipeline now runs:
  - `flutter pub get`
  - `dart run build_runner build --delete-conflicting-outputs`
  - `flutter analyze`
  - `flutter test`
  - `flutter build apk --debug`
- CI backend pipeline now runs from `server/`.
- Broadcast lifecycle hardening:
  - single active broadcast guard
  - safer stop/restart cleanup
  - session/resource cleanup consistency
  - local/internet transport health handling
- Audio chunk framing tuned for more stable scheduling (targeted ~40ms frames at 48kHz mono PCM16).
- Settings status actions split into compact copy controls:
  - Copy WebSocket URL
  - Copy Status URL
  - Copy Status Details

### Fixed
- Configuration drift between docs and runtime paths after backend relocation.
- Root redirect endpoint now supports env override and fallback default URL.
- Local listener websocket now enforces room PIN when room protection is enabled.
- Start-while-active edge case now surfaces a clear user-facing error.
- Stop flow now performs stronger cleanup of timers/subscriptions/transport resources.
- Browser stream pages now avoid raw debug-heavy presentation and use cleaner state messaging.

### Testing
- Added/updated Flutter tests for:
  - broadcast active-session guard
  - stop/rebroadcast lifecycle behavior
  - local listener stop-notification behavior
  - QR PIN inclusion behavior
  - host validation + join parser edge cases
- Added/updated backend tests for:
  - root redirect behavior
  - root redirect env override behavior
  - status/health/system route expectations
  - websocket lifecycle and room cleanup behavior

### Notes
- Release remains `1.0.0`.
- iOS remains listener-first.
- Redis remains optional for current single-instance deployments.
