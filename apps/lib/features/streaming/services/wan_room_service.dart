import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../../../core/errors/app_exception.dart';
import 'room_code_service.dart';
import 'server_url_service.dart';

class WanRoomService {
  WanRoomService({
    required ServerUrlService serverUrlService,
    http.Client? httpClient,
  }) : _serverUrlService = serverUrlService,
       _httpClient = httpClient ?? http.Client();

  final ServerUrlService _serverUrlService;
  final http.Client _httpClient;

  static const _chars = 'abcdefghijklmnopqrstuvwxyz0123456789';

  Future<String> createWanRoom({
    required String serverWebSocketUrl,
    required String roomName,
    String? pin,
  }) async {
    final normalized = _serverUrlService.normalize(serverWebSocketUrl);
    final statusUrl = _serverUrlService.deriveStatusUrl(normalized);
    final endpoint = Uri.parse(statusUrl).replace(path: '/rooms');

    final response = await _httpClient
        .post(
          endpoint,
          headers: {'content-type': 'application/json'},
          body: jsonEncode({
            'roomName': roomName,
            'hostPeerId': _randomHostPeerId(),
            'hostDeviceName': 'SyncWave Host',
            'hostPlatform': 'android',
            if (pin != null && pin.trim().isNotEmpty) 'pin': pin.trim(),
          }),
        )
        .timeout(const Duration(seconds: 6));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AppException(
        'Internet room creation failed (${response.statusCode}).',
        code: 'wan_room_create_failed',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw AppException(
        'Internet room creation returned invalid response.',
        code: 'wan_room_invalid_response',
      );
    }

    final roomId = decoded['roomId']?.toString().trim().toUpperCase();
    if (roomId == null || !RoomCodeService().isValidWanCode(roomId)) {
      throw AppException(
        'Internet room code format is invalid.',
        code: 'wan_room_invalid_code',
      );
    }

    return roomId;
  }

  String _randomHostPeerId() {
    final random = Random.secure();
    final suffix = List.generate(
      10,
      (_) => _chars[random.nextInt(_chars.length)],
    ).join();
    return 'host_$suffix';
  }
}
