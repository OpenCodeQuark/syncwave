import '../models/hosted_session.dart';
import '../models/streaming_mode.dart';
import '../../../core/errors/app_exception.dart';
import 'local_network_info_service.dart';
import 'room_code_service.dart';

class LocalSessionServer {
  LocalSessionServer({
    required LocalNetworkInfoService localNetworkInfoService,
    required RoomCodeService roomCodeService,
    this.defaultPort = 9000,
  }) : _localNetworkInfoService = localNetworkInfoService,
       _roomCodeService = roomCodeService;

  final LocalNetworkInfoService _localNetworkInfoService;
  final RoomCodeService _roomCodeService;
  final int defaultPort;

  HostedSession? _activeSession;

  HostedSession? get activeSession => _activeSession;

  Future<HostedSession> createRoom({
    required String roomName,
    required bool pinProtected,
    String? pin,
  }) async {
    if (_activeSession != null) {
      throw AppException(
        'A local room is already active. Stop the current broadcast before creating a new room.',
        code: 'local_room_already_active',
      );
    }

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
    final activeCodes = <String>{};
    final existing = _activeSession?.roomId;
    if (existing != null && existing.trim().isNotEmpty) {
      activeCodes.add(existing.trim().toUpperCase());
    }
    return _roomCodeService.generateLanCode(activeCodes: activeCodes);
  }
}
