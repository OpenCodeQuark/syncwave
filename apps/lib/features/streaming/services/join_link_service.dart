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
  final _roomCodePattern = RegExp(
    r'^(LAN-[A-Z0-9]{5}|WAN-[A-Z0-9]{5}|SW-[A-Z0-9]{4}-[A-Z0-9]{2})$',
  );

  String buildPrimaryQrPayload(
    HostedSession session, {
    bool includeRoomPin = false,
  }) {
    return buildSyncWaveJoinDeepLink(
      RoomJoinTarget(
        mode: session.mode,
        roomId: session.roomId,
        hostAddress: session.hostAddress,
        hostPort: session.hostPort,
        serverUrl: session.serverUrl,
        pin: session.pin,
        roomPinProtected: session.roomPinProtected,
      ),
      includeRoomPin: includeRoomPin,
    );
  }

  String buildAppQrPayload(
    HostedSession session, {
    String? appVersion,
    bool includeRoomPin = false,
  }) {
    final joinTarget = RoomJoinTarget(
      mode: session.mode,
      roomId: session.roomId,
      hostAddress: session.hostAddress,
      hostPort: session.hostPort,
      serverUrl: session.serverUrl,
      pin: session.pin,
      roomPinProtected: session.roomPinProtected,
    );
    final joinUrl = buildJoinUri(joinTarget, includeRoomPin: includeRoomPin);
    final parsedJoinUrl = Uri.tryParse(joinUrl);
    final effectivePin = includeRoomPin ? session.pin : null;
    final host = session.mode == StreamingMode.local
        ? session.hostAddress
        : parsedJoinUrl?.host;
    final port = session.mode == StreamingMode.local
        ? session.hostPort
        : (parsedJoinUrl?.hasPort == true ? parsedJoinUrl?.port : null);

    final payload = JoinQrPayload(
      app: 'syncwave',
      version: 1,
      appVersion: appVersion,
      mode: session.mode,
      roomId: session.roomId,
      protocolVersion: AppConfig.fromEnvironment().protocolVersion,
      joinUrl: joinUrl,
      joinPath: '/stream/join',
      wsPath: session.mode == StreamingMode.internet ? '/ws' : '/stream/audio',
      host: host,
      port: port,
      hostAddress: session.hostAddress,
      hostPort: session.hostPort,
      serverUrl: session.serverUrl,
      pin: effectivePin,
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

  String buildSyncWaveJoinDeepLink(
    RoomJoinTarget target, {
    bool includeRoomPin = false,
  }) {
    if (target.mode == StreamingMode.local) {
      final host = target.hostAddress?.trim();
      if (host == null || host.isEmpty || _isRejectedLocalHost(host)) {
        throw const FormatException(
          'Local deep link requires a valid private host address.',
        );
      }

      return Uri(
        scheme: 'syncwave',
        host: 'join',
        queryParameters: {
          'host': host,
          if (target.hostPort != null) 'port': target.hostPort.toString(),
          'room': target.roomId,
          if (includeRoomPin && target.pin != null) 'pin': target.pin,
        },
      ).toString();
    }

    final serverUri = _resolveInternetBaseUri(target.serverUrl);
    return Uri(
      scheme: 'syncwave',
      host: 'join',
      queryParameters: {
        'host': serverUri.host,
        if (serverUri.hasPort) 'port': serverUri.port.toString(),
        'room': target.roomId,
        if (includeRoomPin && target.pin != null) 'pin': target.pin,
      },
    ).toString();
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
      hostAddress: payload.host ?? payload.hostAddress ?? joinUri?.host,
      hostPort:
          payload.port ??
          payload.hostPort ??
          (joinUri?.hasPort == true ? joinUri?.port : null),
      serverUrl:
          payload.serverUrl ??
          (payload.mode == StreamingMode.internet ? payload.joinUrl : null),
      pin: parsedPin,
      roomPinProtected: payload.roomPinProtected,
    );
  }

  String buildJoinUri(RoomJoinTarget target, {bool includeRoomPin = false}) {
    if (target.mode == StreamingMode.local) {
      final host = target.hostAddress?.trim();
      if (host == null || host.isEmpty || _isRejectedLocalHost(host)) {
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
        queryParameters: {'room': roomId},
      ).toString(),
      protocolVersion: AppConfig.fromEnvironment().protocolVersion,
      joinPath: '/stream/join',
      wsPath: '/stream/audio',
      host: hostAddress,
      port: hostPort,
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
            queryParameters: {'room': roomId},
          )
          .toString(),
      protocolVersion: AppConfig.fromEnvironment().protocolVersion,
      joinPath: '/stream/join',
      wsPath: '/ws',
      host: serverUri.host,
      port: serverUri.hasPort ? serverUri.port : null,
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
    final host = parsed.host.trim().toLowerCase();
    if (host == 'localhost' || host == '127.0.0.1' || host == '0.0.0.0') {
      throw const FormatException('Internet server host is invalid.');
    }

    return parsed;
  }

  RoomJoinTarget _targetFromJoinUri(Uri uri) {
    final room = (uri.queryParameters['room'] ?? uri.queryParameters['roomId'])
        ?.trim();
    if (uri.scheme.toLowerCase() == 'syncwave') {
      final hostParameter = uri.queryParameters['host']?.trim();
      if (hostParameter == null || hostParameter.isEmpty) {
        throw const FormatException('syncwave:// join link is missing host.');
      }

      final split = hostParameter.split(':');
      final host = split.first.trim();
      final port = _parseSyncWavePort(uri, split);
      if (host.isEmpty ||
          host == 'localhost' ||
          host == '127.0.0.1' ||
          host == '0.0.0.0') {
        throw const FormatException('syncwave:// host is invalid.');
      }

      final effectiveRoom = (room == null || room.isEmpty)
          ? null
          : room.toUpperCase();
      if (effectiveRoom == null || effectiveRoom.isEmpty) {
        throw const FormatException('syncwave:// join link is missing room.');
      }
      if (!_roomCodePattern.hasMatch(effectiveRoom)) {
        throw const FormatException('syncwave:// room format is invalid.');
      }

      final pin = _pinValidationService.normalizeAndValidateOptional(
        uri.queryParameters['pin'],
      );

      final isLocal = _isPrivateIpv4(host);
      return RoomJoinTarget(
        mode: isLocal ? StreamingMode.local : StreamingMode.internet,
        roomId: effectiveRoom,
        hostAddress: isLocal ? host : null,
        hostPort: isLocal ? (port ?? 9000) : null,
        serverUrl: isLocal
            ? null
            : Uri(scheme: 'https', host: host, port: port).toString(),
        pin: pin,
        roomPinProtected:
            pin != null ||
            uri.queryParameters['roomPinProtected'] == 'true' ||
            uri.queryParameters['pinProtected'] == 'true',
      );
    }

    final hasStreamJoinPath = _isStreamJoinPath(uri.pathSegments);
    final effectiveRoom = (room == null || room.isEmpty)
        ? (hasStreamJoinPath ? 'LAN-UNKWN' : null)
        : room.toUpperCase();
    if (effectiveRoom == null) {
      throw const FormatException('Join URL is missing room or roomId query.');
    }
    if (effectiveRoom != 'LAN-UNKWN' &&
        !_roomCodePattern.hasMatch(effectiveRoom)) {
      throw const FormatException('Join URL room code format is invalid.');
    }

    final pin = _pinValidationService.normalizeAndValidateOptional(
      uri.queryParameters['pin'],
    );

    final normalizedHost = uri.host.trim().toLowerCase();
    if (normalizedHost == 'localhost' ||
        normalizedHost == '127.0.0.1' ||
        normalizedHost == '0.0.0.0') {
      throw const FormatException(
        'Join URL host cannot use localhost or loopback.',
      );
    }

    final isLocal =
        uri.scheme.toLowerCase() == 'http' && _isPrivateIpv4(uri.host);

    return RoomJoinTarget(
      mode: isLocal ? StreamingMode.local : StreamingMode.internet,
      roomId: effectiveRoom,
      hostAddress: isLocal ? uri.host : null,
      hostPort: uri.hasPort ? uri.port : null,
      serverUrl: isLocal ? null : uri.toString(),
      pin: pin,
      roomPinProtected:
          pin != null ||
          uri.queryParameters['roomPinProtected'] == 'true' ||
          uri.queryParameters['pinProtected'] == 'true',
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

  int? _parseSyncWavePort(Uri uri, List<String> hostParts) {
    final explicitPort = uri.queryParameters['port']?.trim();
    if (explicitPort != null && explicitPort.isNotEmpty) {
      final parsed = int.tryParse(explicitPort);
      if (parsed == null || parsed <= 0 || parsed > 65535) {
        throw const FormatException('syncwave:// port is invalid.');
      }
      return parsed;
    }

    if (hostParts.length <= 1) {
      return null;
    }

    final parsed = int.tryParse(hostParts.last.trim());
    if (parsed == null || parsed <= 0 || parsed > 65535) {
      throw const FormatException('syncwave:// port is invalid.');
    }
    return parsed;
  }

  bool _isRejectedLocalHost(String host) {
    final normalized = host.trim().toLowerCase();
    return normalized == 'localhost' ||
        normalized == '127.0.0.1' ||
        normalized == '0.0.0.0' ||
        !_isPrivateIpv4(host);
  }
}
