import '../../../core/errors/app_exception.dart';
import '../models/broadcast_destination.dart';
import '../models/hosted_session.dart';
import '../models/remote_server_status.dart';
import '../models/room_join_target.dart';
import '../models/streaming_mode.dart';
import '../models/streaming_settings.dart';
import 'join_link_service.dart';
import 'local_session_server.dart';
import 'wan_room_service.dart';

class StreamingCoordinator {
  StreamingCoordinator({
    required LocalSessionServer localSessionServer,
    required JoinLinkService joinLinkService,
    required WanRoomService wanRoomService,
  }) : _localSessionServer = localSessionServer,
       _joinLinkService = joinLinkService,
       _wanRoomService = wanRoomService;

  final LocalSessionServer _localSessionServer;
  final JoinLinkService _joinLinkService;
  final WanRoomService _wanRoomService;

  Future<BroadcastAvailability> resolveBroadcastAvailability({
    required StreamingSettings settings,
    RemoteServerStatus? remoteServerStatus,
  }) async {
    final localAvailable = await _localSessionServer.hasAvailableLocalNetwork();
    final internetAvailable =
        settings.internetModeConfigured &&
        remoteServerStatus != null &&
        remoteServerStatus.internetBroadcastReady;

    return BroadcastAvailability(
      localAvailable: localAvailable,
      internetAvailable: internetAvailable,
    );
  }

  Future<HostedSession> createHostSession({
    required String roomName,
    required bool pinProtected,
    String? pin,
    required StreamingSettings settings,
    RemoteServerStatus? remoteServerStatus,
    BroadcastDestination destination = BroadcastDestination.automatic,
    String? serverConnectionPin,
    required bool audioSourceEnabled,
    required bool microphoneEnabled,
  }) async {
    final internetReady =
        settings.internetModeConfigured &&
        remoteServerStatus != null &&
        remoteServerStatus.internetBroadcastReady;
    final wantsLocal = destination.includesLocal;
    final wantsInternet = destination.includesInternet && internetReady;
    final explicitDestination = destination != BroadcastDestination.automatic;

    if ((destination == BroadcastDestination.internetOnly ||
            destination == BroadcastDestination.both) &&
        !internetReady) {
      throw AppException(
        'Connect the internet signaling server before choosing this broadcast destination.',
        code: 'internet_mode_not_connected',
      );
    }

    HostedSession? localSession;
    AppException? localFailure;
    if (wantsLocal) {
      try {
        localSession = await _localSessionServer.createRoom(
          roomName: roomName,
          pinProtected: pinProtected,
          pin: pin,
        );
      } on AppException catch (error) {
        if (error.code == 'local_room_already_active' ||
            destination == BroadcastDestination.localOnly ||
            destination == BroadcastDestination.both) {
          rethrow;
        }
        localFailure = error;
      }
    }

    String? wanRoomId;
    final serverUrl = settings.signalingServerUrl?.trim();
    if (wantsInternet && serverUrl != null && serverUrl.isNotEmpty) {
      try {
        wanRoomId = await _wanRoomService.createWanRoom(
          serverWebSocketUrl: serverUrl,
          roomName: roomName,
          pin: pin,
          serverConnectionPin: serverConnectionPin,
        );
      } on AppException catch (_) {
        if (localSession == null || explicitDestination) {
          rethrow;
        }
      }
    }

    if (localSession != null) {
      return localSession.copyWith(
        audioSourceEnabled: audioSourceEnabled,
        microphoneEnabled: microphoneEnabled,
        serverUrl: wanRoomId != null ? serverUrl : null,
        wanRoomId: wanRoomId,
      );
    }

    if (!wantsInternet) {
      if (localFailure != null) {
        throw localFailure;
      }
      if (destination == BroadcastDestination.internetOnly) {
        throw AppException(
          'Connect the internet signaling server before choosing Internet only.',
          code: 'internet_mode_not_connected',
        );
      }
      throw AppException(
        'Connect to Wi-Fi, enable hotspot, or connect an internet signaling server to start broadcasting.',
        code: 'broadcast_unavailable',
      );
    }

    if (serverUrl == null || serverUrl.isEmpty) {
      throw AppException(
        'Internet signaling is enabled, but server URL is missing.',
        code: 'internet_mode_not_configured',
      );
    }

    if (wanRoomId == null || wanRoomId.trim().isEmpty) {
      throw AppException(
        'Internet signaling is connected, but WAN room creation failed.',
        code: 'wan_room_create_failed',
      );
    }

    return HostedSession(
      roomId: wanRoomId,
      roomName: roomName,
      mode: StreamingMode.internet,
      serverUrl: serverUrl,
      wanRoomId: wanRoomId,
      roomPinProtected: pinProtected,
      pin: pin,
      audioSourceEnabled: audioSourceEnabled,
      microphoneEnabled: microphoneEnabled,
    );
  }

  String buildAppQrPayload(
    HostedSession session, {
    String? appVersion,
    bool includeRoomPin = false,
  }) {
    return _joinLinkService.buildAppQrPayload(
      session,
      appVersion: appVersion,
      includeRoomPin: includeRoomPin,
    );
  }

  String buildPrimaryQrPayload(
    HostedSession session, {
    bool includeRoomPin = false,
  }) {
    return _joinLinkService.buildPrimaryQrPayload(
      session,
      includeRoomPin: includeRoomPin,
    );
  }

  String buildJoinUrl(HostedSession session, {bool includeRoomPin = false}) {
    return _joinLinkService.buildJoinUri(
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

  String buildBrowserQrPayload(HostedSession session) {
    return _joinLinkService.buildBrowserUrlQr(
      RoomJoinTarget(
        mode: session.mode,
        roomId: session.roomId,
        hostAddress: session.hostAddress,
        hostPort: session.hostPort,
        serverUrl: session.serverUrl,
        pin: session.pin,
        roomPinProtected: session.roomPinProtected,
      ),
      includeRoomPin: false,
    );
  }

  String? buildInternetJoinUrl(
    HostedSession session, {
    bool includeRoomPin = false,
  }) {
    final serverUrl = session.serverUrl?.trim();
    final wanRoomId = session.wanRoomId?.trim();
    if (serverUrl == null ||
        serverUrl.isEmpty ||
        wanRoomId == null ||
        wanRoomId.isEmpty) {
      return null;
    }

    return _joinLinkService.buildJoinUri(
      RoomJoinTarget(
        mode: StreamingMode.internet,
        roomId: wanRoomId,
        serverUrl: serverUrl,
        pin: session.pin,
        roomPinProtected: session.roomPinProtected,
      ),
      includeRoomPin: includeRoomPin,
    );
  }

  Future<void> stopLocalSession() {
    return _localSessionServer.stopRoom();
  }
}
