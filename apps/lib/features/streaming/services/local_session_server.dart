import 'dart:math';

import '../models/hosted_session.dart';
import '../models/streaming_mode.dart';
import 'local_network_info_service.dart';

class LocalSessionServer {
  LocalSessionServer({
    required LocalNetworkInfoService localNetworkInfoService,
    this.defaultPort = 9000,
  }) : _localNetworkInfoService = localNetworkInfoService;

  final LocalNetworkInfoService _localNetworkInfoService;
  final int defaultPort;

  HostedSession? _activeSession;

  HostedSession? get activeSession => _activeSession;

  Future<HostedSession> createRoom({
    required String roomName,
    required bool pinProtected,
    String? pin,
  }) async {
    final network = await _localNetworkInfoService.selectBestLocalNetwork();

    final room = HostedSession(
      roomId: _generateRoomId(),
      roomName: roomName,
      mode: StreamingMode.local,
      hostAddress: network.address,
      hostPort: defaultPort,
      roomPinProtected: pinProtected,
      pin: pin,
    );

    _activeSession = room;
    return room;
  }

  Future<void> stopRoom() async {
    _activeSession = null;
  }

  String _generateRoomId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();

    String randomChunk(int length) {
      return List.generate(
        length,
        (_) => chars[random.nextInt(chars.length)],
      ).join();
    }

    return 'SW-${randomChunk(4)}-${randomChunk(2)}';
  }
}
