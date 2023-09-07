import 'package:flutter_test/flutter_test.dart';
import 'package:syncwave/core/errors/app_exception.dart';
import 'package:syncwave/features/streaming/models/broadcast_destination.dart';
import 'package:syncwave/features/streaming/models/hosted_session.dart';
import 'package:syncwave/features/streaming/models/remote_server_connection_state.dart';
import 'package:syncwave/features/streaming/models/remote_server_status.dart';
import 'package:syncwave/features/streaming/models/streaming_mode.dart';
import 'package:syncwave/features/streaming/models/streaming_settings.dart';
import 'package:syncwave/features/streaming/services/join_link_service.dart';
import 'package:syncwave/features/streaming/services/local_network_info_service.dart';
import 'package:syncwave/features/streaming/services/local_session_server.dart';
import 'package:syncwave/features/streaming/services/pin_validation_service.dart';
import 'package:syncwave/features/streaming/services/room_code_service.dart';
import 'package:syncwave/features/streaming/services/streaming_coordinator.dart';
import 'package:syncwave/features/streaming/services/wan_room_service.dart';
import 'package:syncwave/features/streaming/services/server_url_service.dart';

class _FakeLocalSessionServer extends LocalSessionServer {
  _FakeLocalSessionServer()
    : super(
        localNetworkInfoService: LocalNetworkInfoService(),
        roomCodeService: RoomCodeService(),
      );

  HostedSession? nextSession;
  AppException? nextError;
  bool localAvailable = true;

  @override
  Future<bool> hasAvailableLocalNetwork() async => localAvailable;

  @override
  Future<HostedSession> createRoom({
    required String roomName,
    required bool pinProtected,
    String? pin,
  }) async {
    if (nextError != null) {
      throw nextError!;
    }
    if (nextSession != null) {
      return nextSession!;
    }
    throw AppException('no session', code: 'no_session');
  }
}

class _FakeWanRoomService extends WanRoomService {
  _FakeWanRoomService() : super(serverUrlService: ServerUrlService());

  String? nextRoomId;
  AppException? nextError;

  @override
  Future<String> createWanRoom({
    required String serverWebSocketUrl,
    required String roomName,
    String? pin,
  }) async {
    if (nextError != null) {
      throw nextError!;
    }
    if (nextRoomId != null) {
      return nextRoomId!;
    }
    throw AppException('wan unavailable', code: 'wan_unavailable');
  }
}

void main() {
  final remoteReady = const RemoteServerStatus(
    reachable: true,
    isSyncWaveServer: true,
    websocketConnected: true,
    handshakeAccepted: true,
    state: RemoteServerConnectionState.connected,
  );

  test('host session with LAN only', () async {
    final localServer = _FakeLocalSessionServer()
      ..nextSession = const HostedSession(
        roomId: 'LAN-R12B9',
        roomName: 'Room',
        mode: StreamingMode.local,
        hostAddress: '192.168.1.20',
        hostPort: 9000,
      );
    final coordinator = StreamingCoordinator(
      localSessionServer: localServer,
      joinLinkService: JoinLinkService(
        pinValidationService: PinValidationService(),
      ),
      wanRoomService: _FakeWanRoomService(),
    );

    final session = await coordinator.createHostSession(
      roomName: 'Room',
      pinProtected: false,
      settings: const StreamingSettings(),
      remoteServerStatus: null,
      audioSourceEnabled: true,
      microphoneEnabled: false,
    );

    expect(session.mode, StreamingMode.local);
    expect(session.roomId, 'LAN-R12B9');
    expect(session.wanRoomId, isNull);
  });

  test('host session with WAN only fallback', () async {
    final localServer = _FakeLocalSessionServer()
      ..nextError = AppException(
        'Connect to Wi-Fi or enable hotspot to start a local broadcast.',
        code: 'local_network_unavailable',
      );
    final wanService = _FakeWanRoomService()..nextRoomId = 'WAN-RM01P';
    final coordinator = StreamingCoordinator(
      localSessionServer: localServer,
      joinLinkService: JoinLinkService(
        pinValidationService: PinValidationService(),
      ),
      wanRoomService: wanService,
    );

    final session = await coordinator.createHostSession(
      roomName: 'Room',
      pinProtected: false,
      settings: const StreamingSettings(
        internetStreamingEnabled: true,
        signalingServerUrl: 'wss://your-server.example.com/ws',
      ),
      remoteServerStatus: remoteReady,
      destination: BroadcastDestination.automatic,
      audioSourceEnabled: true,
      microphoneEnabled: false,
    );

    expect(session.mode, StreamingMode.internet);
    expect(session.roomId, 'WAN-RM01P');
    expect(session.wanRoomId, 'WAN-RM01P');
  });

  test('host session with both LAN and WAN availability', () async {
    final localServer = _FakeLocalSessionServer()
      ..nextSession = const HostedSession(
        roomId: 'LAN-R12B9',
        roomName: 'Room',
        mode: StreamingMode.local,
        hostAddress: '192.168.1.20',
        hostPort: 9000,
      );
    final wanService = _FakeWanRoomService()..nextRoomId = 'WAN-RM01P';
    final coordinator = StreamingCoordinator(
      localSessionServer: localServer,
      joinLinkService: JoinLinkService(
        pinValidationService: PinValidationService(),
      ),
      wanRoomService: wanService,
    );

    final session = await coordinator.createHostSession(
      roomName: 'Room',
      pinProtected: false,
      settings: const StreamingSettings(
        internetStreamingEnabled: true,
        signalingServerUrl: 'wss://your-server.example.com/ws',
      ),
      remoteServerStatus: remoteReady,
      destination: BroadcastDestination.both,
      audioSourceEnabled: true,
      microphoneEnabled: false,
    );

    expect(session.mode, StreamingMode.local);
    expect(session.roomId, 'LAN-R12B9');
    expect(session.wanRoomId, 'WAN-RM01P');
    expect(session.serverUrl, 'wss://your-server.example.com/ws');
  });

  test(
    'resolves route selection when LAN and WAN are both available',
    () async {
      final localServer = _FakeLocalSessionServer()..localAvailable = true;
      final coordinator = StreamingCoordinator(
        localSessionServer: localServer,
        joinLinkService: JoinLinkService(
          pinValidationService: PinValidationService(),
        ),
        wanRoomService: _FakeWanRoomService(),
      );

      final availability = await coordinator.resolveBroadcastAvailability(
        settings: const StreamingSettings(
          internetStreamingEnabled: true,
          signalingServerUrl: 'wss://your-server.example.com/ws',
        ),
        remoteServerStatus: remoteReady,
      );

      expect(availability.localAvailable, isTrue);
      expect(availability.internetAvailable, isTrue);
      expect(availability.bothAvailable, isTrue);
      expect(availability.defaultDestination, isNull);
    },
  );

  test('internet-only destination skips local room creation', () async {
    final localServer = _FakeLocalSessionServer()
      ..localAvailable = true
      ..nextError = AppException('should not create LAN', code: 'unexpected');
    final wanService = _FakeWanRoomService()..nextRoomId = 'WAN-RM01P';
    final coordinator = StreamingCoordinator(
      localSessionServer: localServer,
      joinLinkService: JoinLinkService(
        pinValidationService: PinValidationService(),
      ),
      wanRoomService: wanService,
    );

    final session = await coordinator.createHostSession(
      roomName: 'Room',
      pinProtected: false,
      settings: const StreamingSettings(
        internetStreamingEnabled: true,
        signalingServerUrl: 'wss://your-server.example.com/ws',
      ),
      remoteServerStatus: remoteReady,
      destination: BroadcastDestination.internetOnly,
      audioSourceEnabled: true,
      microphoneEnabled: false,
    );

    expect(session.mode, StreamingMode.internet);
    expect(session.roomId, 'WAN-RM01P');
    expect(session.hostAddress, isNull);
  });

  test('local-only destination skips WAN room creation', () async {
    final localServer = _FakeLocalSessionServer()
      ..nextSession = const HostedSession(
        roomId: 'LAN-R12B9',
        roomName: 'Room',
        mode: StreamingMode.local,
        hostAddress: '192.168.1.20',
        hostPort: 9000,
      );
    final wanService = _FakeWanRoomService()
      ..nextError = AppException('should not create WAN', code: 'unexpected');
    final coordinator = StreamingCoordinator(
      localSessionServer: localServer,
      joinLinkService: JoinLinkService(
        pinValidationService: PinValidationService(),
      ),
      wanRoomService: wanService,
    );

    final session = await coordinator.createHostSession(
      roomName: 'Room',
      pinProtected: false,
      settings: const StreamingSettings(
        internetStreamingEnabled: true,
        signalingServerUrl: 'wss://your-server.example.com/ws',
      ),
      remoteServerStatus: remoteReady,
      destination: BroadcastDestination.localOnly,
      audioSourceEnabled: true,
      microphoneEnabled: false,
    );

    expect(session.mode, StreamingMode.local);
    expect(session.wanRoomId, isNull);
    expect(session.serverUrl, isNull);
  });
}
