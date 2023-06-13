import 'dart:convert';

import '../models/hosted_session.dart';
import '../models/join_qr_payload.dart';
import '../models/room_join_target.dart';
import '../models/streaming_mode.dart';
import 'pin_validation_service.dart';

class JoinLinkService {
  JoinLinkService({required PinValidationService pinValidationService})
    : _pinValidationService = pinValidationService;

  final PinValidationService _pinValidationService;

  String buildQrPayload(HostedSession session) {
    final joinTarget = RoomJoinTarget(
      mode: session.mode,
      roomId: session.roomId,
      hostAddress: session.hostAddress,
      hostPort: session.hostPort,
      serverUrl: session.serverUrl,
      pin: session.pin,
      pinProtected: session.pinProtected,
    );

    final payload = JoinQrPayload(
      mode: session.mode,
      roomId: session.roomId,
      joinUrl: buildJoinUri(joinTarget),
      hostAddress: session.hostAddress,
      hostPort: session.hostPort,
      serverUrl: session.serverUrl,
      pin: session.pin,
      pinProtected: session.pinProtected,
    );

    return jsonEncode(payload.toJson());
  }

  RoomJoinTarget parseQrPayload(String rawPayload) {
    final decoded = jsonDecode(rawPayload);
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
      pinProtected: payload.pinProtected,
    );
  }

  String buildJoinUri(RoomJoinTarget target) {
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
          if (target.pin != null) 'pin': target.pin,
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
            if (target.pin != null) 'pin': target.pin,
          },
        )
        .toString();
  }

  JoinQrPayload localQrPayloadTemplate({
    required String roomId,
    required String hostAddress,
    required int hostPort,
    required bool pinProtected,
    String? pin,
  }) {
    final normalizedPin = _pinValidationService.normalizeAndValidateOptional(
      pin,
    );
    return JoinQrPayload(
      mode: StreamingMode.local,
      roomId: roomId,
      joinUrl: Uri(
        scheme: 'http',
        host: hostAddress,
        port: hostPort,
        path: '/stream/join',
        queryParameters: {
          'room': roomId,
          ...?normalizedPin == null ? null : {'pin': normalizedPin},
        },
      ).toString(),
      hostAddress: hostAddress,
      hostPort: hostPort,
      pin: normalizedPin,
      pinProtected: pinProtected,
    );
  }

  JoinQrPayload internetQrPayloadTemplate({
    required String roomId,
    required String serverUrl,
    required bool pinProtected,
    String? pin,
  }) {
    final normalizedPin = _pinValidationService.normalizeAndValidateOptional(
      pin,
    );
    final serverUri = _resolveInternetBaseUri(serverUrl);
    return JoinQrPayload(
      mode: StreamingMode.internet,
      roomId: roomId,
      joinUrl: serverUri
          .replace(
            scheme: serverUri.scheme == 'wss' ? 'https' : 'http',
            path: '/stream/join',
            queryParameters: {
              'room': roomId,
              ...?normalizedPin == null ? null : {'pin': normalizedPin},
            },
          )
          .toString(),
      serverUrl: serverUrl,
      pin: normalizedPin,
      pinProtected: pinProtected,
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
}
