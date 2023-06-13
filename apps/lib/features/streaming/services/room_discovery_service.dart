import 'dart:convert';

import '../models/join_qr_payload.dart';
import '../models/room_join_target.dart';
import '../models/streaming_mode.dart';
import 'network_interface_selector.dart';
import 'pin_validation_service.dart';

class RoomDiscoveryService {
  RoomDiscoveryService({
    required PinValidationService pinValidationService,
    NetworkInterfaceSelector? networkInterfaceSelector,
  }) : _pinValidationService = pinValidationService,
       _networkInterfaceSelector =
           networkInterfaceSelector ?? NetworkInterfaceSelector();

  final PinValidationService _pinValidationService;
  final NetworkInterfaceSelector _networkInterfaceSelector;

  final _roomCodePattern = RegExp(r'^SW-[A-Z0-9]{4}-[A-Z0-9]{2}$');

  RoomJoinTarget parseManualJoinInput(String input) {
    final trimmedInput = input.trim();
    if (trimmedInput.isEmpty) {
      throw const FormatException('Room code or join link is required.');
    }

    final jsonCandidate = _tryParseJson(trimmedInput);
    if (jsonCandidate != null) {
      final payload = JoinQrPayload.fromJson(jsonCandidate);
      _validateQrPayloadPin(payload.pin);

      if (payload.joinUrl != null && payload.joinUrl!.trim().isNotEmpty) {
        final urlTarget = _roomTargetFromUri(
          _parseRequiredUri(payload.joinUrl!),
        );
        return urlTarget.copyWith(
          pinProtected: payload.pinProtected,
          pin: payload.pin ?? urlTarget.pin,
        );
      }

      return RoomJoinTarget(
        mode: payload.mode,
        roomId: payload.roomId,
        hostAddress: payload.hostAddress,
        hostPort: payload.hostPort,
        serverUrl: payload.serverUrl,
        pin: payload.pin,
        pinProtected: payload.pinProtected,
      );
    }

    final parsedUri = _tryParseJoinUri(trimmedInput);
    if (parsedUri != null) {
      return _roomTargetFromUri(parsedUri);
    }

    final normalizedCode = trimmedInput.toUpperCase();
    if (_roomCodePattern.hasMatch(normalizedCode)) {
      return RoomJoinTarget(mode: StreamingMode.local, roomId: normalizedCode);
    }

    throw const FormatException(
      'Unsupported join format. Use room code, local/internet join URL, or QR payload.',
    );
  }

  Uri _parseRequiredUri(String rawValue) {
    final parsed = Uri.tryParse(rawValue.trim());
    if (parsed == null) {
      throw const FormatException('Invalid join URL in QR payload.');
    }

    return parsed;
  }

  void _validateQrPayloadPin(String? pin) {
    _pinValidationService.normalizeAndValidateOptional(pin);
  }

  Map<String, dynamic>? _tryParseJson(String input) {
    try {
      final decoded = jsonDecode(input);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  Uri? _tryParseJoinUri(String input) {
    final directUri = Uri.tryParse(input);
    if (directUri != null && directUri.scheme.isNotEmpty) {
      final malformedHostShortcut =
          directUri.host.isEmpty &&
          (directUri.scheme.contains('.') ||
              int.tryParse(directUri.scheme) != null);
      if (malformedHostShortcut) {
        return Uri.tryParse('http://$input');
      }
      return directUri;
    }

    final looksLikeHostInput =
        input.contains(':') || input.contains('.') || input.contains('/');
    if (!looksLikeHostInput) {
      return null;
    }

    return Uri.tryParse('http://$input');
  }

  RoomJoinTarget _roomTargetFromUri(Uri uri) {
    if (uri.scheme.toLowerCase() == 'syncwave') {
      final mode = StreamingMode.fromWireValue(
        uri.queryParameters['mode'] ?? 'local',
      );
      final roomId = uri.queryParameters['roomId'];

      if (roomId == null || roomId.trim().isEmpty) {
        throw const FormatException('Join URI is missing roomId.');
      }

      final parsedPin = _pinValidationService.normalizeAndValidateOptional(
        uri.queryParameters['pin'],
      );

      return RoomJoinTarget(
        mode: mode,
        roomId: roomId,
        hostAddress: uri.queryParameters['hostAddress'],
        hostPort: int.tryParse(uri.queryParameters['hostPort'] ?? ''),
        serverUrl: uri.queryParameters['serverUrl'],
        pin: parsedPin,
        pinProtected: uri.queryParameters['pinProtected'] == 'true',
      );
    }

    final scheme = uri.scheme.toLowerCase();
    if (!{'http', 'https', 'ws', 'wss'}.contains(scheme)) {
      throw const FormatException('Unsupported join URL scheme.');
    }

    final roomFromQuery =
        uri.queryParameters['room'] ?? uri.queryParameters['roomId'];
    final roomFromPath = _extractRoomCodeFromPath(uri.pathSegments);
    final hasStreamJoinPath = _isStreamJoinPath(uri.pathSegments);
    final resolvedRoomId = (roomFromQuery ?? roomFromPath)?.toUpperCase();
    final roomId = resolvedRoomId ?? (hasStreamJoinPath ? 'SW-UNKNOWN' : null);

    if (roomId == null ||
        (roomId != 'SW-UNKNOWN' && !_roomCodePattern.hasMatch(roomId))) {
      throw const FormatException('Room ID is missing or invalid in join URL.');
    }

    final pin = _pinValidationService.normalizeAndValidateOptional(
      uri.queryParameters['pin'],
    );

    final hostAddress = uri.host.isEmpty ? null : uri.host;
    final isPrivateHost = hostAddress != null && _isPrivateIpv4(hostAddress);

    final mode = isPrivateHost ? StreamingMode.local : StreamingMode.internet;

    return RoomJoinTarget(
      mode: mode,
      roomId: roomId,
      hostAddress: hostAddress,
      hostPort: uri.hasPort ? uri.port : null,
      serverUrl: mode == StreamingMode.internet ? uri.toString() : null,
      pin: pin,
      pinProtected: pin != null,
    );
  }

  bool _isPrivateIpv4(String host) {
    final candidates = _networkInterfaceSelector.buildCandidates([
      NetworkAddressDescriptor(interfaceName: 'host', address: host),
    ]);
    return candidates.isNotEmpty;
  }

  String? _extractRoomCodeFromPath(List<String> pathSegments) {
    for (final segment in pathSegments.reversed) {
      final upper = segment.toUpperCase();
      if (_roomCodePattern.hasMatch(upper)) {
        return upper;
      }
    }

    return null;
  }

  bool _isStreamJoinPath(List<String> segments) {
    if (segments.length < 2) {
      return false;
    }

    final lastTwo = segments
        .sublist(segments.length - 2)
        .map((e) => e.toLowerCase())
        .toList();
    return lastTwo[0] == 'stream' && lastTwo[1] == 'join';
  }
}
