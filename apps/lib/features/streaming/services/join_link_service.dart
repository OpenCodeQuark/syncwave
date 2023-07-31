import 'dart:convert';

import '../../../core/config/app_config.dart';
import '../models/hosted_session.dart';
import '../models/join_qr_payload.dart';
import '../models/room_join_target.dart';
import '../models/streaming_mode.dart';
import 'pin_validation_service.dart';

class JoinLinkService {
  JoinLinkService({required PinValidationService pinValidationService})
    : _pinValidationService = pinValidationService;

  final PinValidationService _pinValidationService;

  String buildAppQrPayload(HostedSession session, {String? appVersion}) {
    final joinTarget = RoomJoinTarget(
      mode: session.mode,
      roomId: session.roomId,
      hostAddress: session.hostAddress,
      hostPort: session.hostPort,
      serverUrl: session.serverUrl,
      pin: session.pin,
      roomPinProtected: session.roomPinProtected,
    );

    final payload = JoinQrPayload(
      app: 'syncwave',
      version: 1,
      appVersion: appVersion,
      mode: session.mode,
      roomId: session.roomId,
      joinUrl: buildJoinUri(joinTarget, includeRoomPin: false),
      hostAddress: session.hostAddress,
      hostPort: session.hostPort,
      serverUrl: session.serverUrl,
      pin: session.pin,
      roomPinProtected: session.roomPinProtected,
    );

    return jsonEncode(payload.toJson());
  }

  String buildBrowserUrlQr(
    RoomJoinTarget target, {
    bool includeRoomPin = false,
  }) {
    return buildJoinUri(target, includeRoomPin: includeRoomPin);
  }

  RoomJoinTarget parseQrPayload(String rawPayload) {
    final trimmed = rawPayload.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.scheme.isNotEmpty) {
      return _targetFromJoinUri(uri);
    }

    final decoded = jsonDecode(trimmed);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid QR payload.');
    }

    final payload = JoinQrPayload.fromJson(decoded);
    if (payload.app.toLowerCase() != 'syncwave') {
      throw const FormatException('Unsupported QR payload app identifier.');
    }

    final parsedPin = _pinValidationService.normalizeAndValidateOptional(
      payload.pin,
    );
    final joinUri = payload.joinUrl == null
        ? null
        : Uri.tryParse(payload.joinUrl!.trim());

    return RoomJoinTarget(
      mode: payload.mode,
      roomId: payload.roomId,
      hostAddress: payload.hostAddress ?? joinUri?.host,
      hostPort:
          payload.hostPort ?? (joinUri?.hasPort == true ? joinUri?.port : null),
      serverUrl:
          payload.serverUrl ??
          (payload.mode == StreamingMode.internet ? payload.joinUrl : null),
      pin: parsedPin,
      roomPinProtected: payload.roomPinProtected,
    );
  }

  String buildJoinUri(
    RoomJoinTarget target, {
    bool includeRoomPin = false,
  }) {
    if (target.mode == StreamingMode.local) {
      final host = target.hostAddress?.trim();
      if (host == null ||
          host.isEmpty ||
          host == '127.0.0.1' ||
          host == 'localhost') {
        throw const FormatException(
          'Local join URL requires a LAN/hotspot host address.',
        );
      }
      final port = target.hostPort ?? 9000;

      return Uri(
        scheme: 'http',
        host: host,
        port: port,
        path: '/stream/join',
        queryParameters: {
          'room': target.roomId,
          if (includeRoomPin && target.pin != null) 'pin': target.pin,
        },
      ).toString();
    }

    final serverUri = _resolveInternetBaseUri(target.serverUrl);
    return serverUri
        .replace(
          scheme: serverUri.scheme == 'wss' ? 'https' : 'http',
          path: '/stream/join',
          queryParameters: {
            'room': target.roomId,
            if (includeRoomPin && target.pin != null) 'pin': target.pin,
          },
        )
        .toString();
  }

  JoinQrPayload localQrPayloadTemplate({
    required String roomId,
    required String hostAddress,
    required int hostPort,
    required bool roomPinProtected,
    String? pin,
  }) {
    final normalizedPin = _pinValidationService.normalizeAndValidateOptional(
      pin,
    );
    return JoinQrPayload(
      app: 'syncwave',
      version: 1,
      appVersion: AppConfig.fromEnvironment().appVersion,
      mode: StreamingMode.local,
      roomId: roomId,
      joinUrl: Uri(
        scheme: 'http',
        host: hostAddress,
        port: hostPort,
        path: '/stream/join',
        queryParameters: {
          'room': roomId,
        },
      ).toString(),
      hostAddress: hostAddress,
      hostPort: hostPort,
      pin: normalizedPin,
      roomPinProtected: roomPinProtected,
    );
  }

  JoinQrPayload internetQrPayloadTemplate({
    required String roomId,
    required String serverUrl,
    required bool roomPinProtected,
    String? pin,
  }) {
    final normalizedPin = _pinValidationService.normalizeAndValidateOptional(
      pin,
    );
    final serverUri = _resolveInternetBaseUri(serverUrl);
    return JoinQrPayload(
      app: 'syncwave',
      version: 1,
      appVersion: AppConfig.fromEnvironment().appVersion,
      mode: StreamingMode.internet,
      roomId: roomId,
      joinUrl: serverUri
          .replace(
            scheme: serverUri.scheme == 'wss' ? 'https' : 'http',
            path: '/stream/join',
            queryParameters: {
              'room': roomId,
            },
          )
          .toString(),
      serverUrl: serverUrl,
      pin: normalizedPin,
      roomPinProtected: roomPinProtected,
    );
  }

  Uri _resolveInternetBaseUri(String? rawServerUrl) {
    if (rawServerUrl == null || rawServerUrl.trim().isEmpty) {
      throw const FormatException('Internet mode requires a server URL.');
    }

    final parsed = Uri.tryParse(rawServerUrl.trim());
    if (parsed == null || parsed.host.isEmpty || parsed.scheme.isEmpty) {
      throw const FormatException('Invalid internet server URL.');
    }

    return parsed;
  }

  RoomJoinTarget _targetFromJoinUri(Uri uri) {
    final room = (uri.queryParameters['room'] ?? uri.queryParameters['roomId'])
        ?.trim();
    final hasStreamJoinPath = _isStreamJoinPath(uri.pathSegments);
    final effectiveRoom = (room == null || room.isEmpty)
        ? (hasStreamJoinPath ? 'SW-UNKNOWN' : null)
        : room.toUpperCase();
    if (effectiveRoom == null) {
      throw const FormatException('Join URL is missing room or roomId query.');
    }

    final pin = _pinValidationService.normalizeAndValidateOptional(
      uri.queryParameters['pin'],
    );

    final isLocal = uri.scheme.toLowerCase() == 'http' && _isPrivateIpv4(uri.host);

    return RoomJoinTarget(
      mode: isLocal ? StreamingMode.local : StreamingMode.internet,
      roomId: effectiveRoom,
      hostAddress: isLocal ? uri.host : null,
      hostPort: uri.hasPort ? uri.port : null,
      serverUrl: isLocal ? null : uri.toString(),
      pin: pin,
      roomPinProtected: pin != null,
    );
  }

  bool _isStreamJoinPath(List<String> segments) {
    if (segments.length < 2) {
      return false;
    }
    final normalized = segments.map((part) => part.toLowerCase()).toList();
    return normalized[normalized.length - 2] == 'stream' &&
        normalized[normalized.length - 1] == 'join';
  }

  bool _isPrivateIpv4(String host) {
    final parts = host.split('.');
    if (parts.length != 4) {
      return false;
    }

    final octets = <int>[];
    for (final part in parts) {
      final value = int.tryParse(part);
      if (value == null || value < 0 || value > 255) {
        return false;
      }
      octets.add(value);
    }

    final first = octets[0];
    final second = octets[1];

    if (first == 10) {
      return true;
    }
    if (first == 172 && second >= 16 && second <= 31) {
      return true;
    }
    if (first == 192 && second == 168) {
      return true;
    }

    return false;
  }
}
