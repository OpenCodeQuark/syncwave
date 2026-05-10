# Changelog

## 1.1.4 - Release, Listener, and UI Polish

- Fixed GitHub Release creation permissions for tag/manual release workflows.
- Synced app/server version metadata and Flutter build number to `1.1.4+4`.
- Changed Server Connection PIN validation to exactly 8 digits while keeping Room PINs exactly 6 digits.
- Redesigned `/stream/join` for mobile-first listening and fixed retry after failed connections.
- Improved listener stability with safer retry cleanup, cached stream metadata for late WAN listeners, duplicate join guards, larger listener buffers, and lighter Android capture transfer.
- Polished app info, broadcast destination, home, and status/navigation UI.
- Kept README and release notes short and public-facing.

## 1.1.2 - Identity, Listener Stability, and Polish

- Renamed Android package/application ID to `io.github.opencodequark.syncwave`.
- Updated official project links to `https://github.com/OpenCodeQuark/syncwave`.
- Improved listener playback stability with larger jitter buffers, silence fill for small sequence gaps, safer queue limits, and clearer rebuffer status.
- Separated Server Connection PIN from Room PIN: listeners using `/stream/join` need only the Room PIN, while protected host/relay actions require the Server Connection PIN.
- Hardened protected WAN room creation and removed PIN hashes from public room payloads.
- Polished Material 3 app shell styling, status/navigation bar readability, and release workflow paths.
- Shortened README and removed the old project report.

## 1.1.0 - Broadcast Control Refresh

- Added explicit LAN, Internet, and LAN + Internet broadcast route selection.
- Added active broadcast persistence with Return to Room and Stop Broadcast actions.
- Fixed WAN browser listener compatibility for `platform: web`.
- Passed saved Server Connection PIN through protected internet relay startup.
- Improved browser playback buffering and documented remaining PCM/base64 limitations.
- Replaced launcher icons, app icons, and favicons from `AppIcons/`.
- Bumped app and server metadata to `1.1.0`.

## 1.0.0 - Initial Local-First Release

- Flutter app scaffold with Android hosting flow and browser listener links.
- Android foreground service for MediaProjection audio capture.
- Local LAN routes: `GET /stream/join`, `WS /stream/audio`, and `GET /status`.
- Optional FastAPI server routes for health, status, room creation, and WebSocket signaling.
- Room code and Room PIN validation.
