import '../../../core/errors/app_exception.dart';
import '../models/hosted_session.dart';
import '../models/remote_server_status.dart';
import '../models/room_join_target.dart';
import '../models/streaming_mode.dart';
import '../models/streaming_settings.dart';
import 'join_link_service.dart';
import 'local_session_server.dart';

class StreamingCoordinator {
  StreamingCoordinator({
    required LocalSessionServer localSessionServer,
    required JoinLinkService joinLinkService,
  }) : _localSessionServer = localSessionServer,
       _joinLinkService = joinLinkService;

  final LocalSessionServer _localSessionServer;
  final JoinLinkService _joinLinkService;

  Future<HostedSession> createHostSession({
    required String roomName,
    required bool pinProtected,
    String? pin,
    required StreamingSettings settings,
    RemoteServerStatus? remoteServerStatus,
    required bool audioSourceEnabled,
    required bool microphoneEnabled,
  }) async {
    HostedSession? localSession;
    AppException? localFailure;
    try {
      localSession = await _localSessionServer.createRoom(
        roomName: roomName,
        pinProtected: pinProtected,
        pin: pin,
      );
    } on AppException catch (error) {
      localFailure = error;
    }

    final internetReady =
        settings.internetModeConfigured &&
        remoteServerStatus != null &&
        remoteServerStatus.internetBroadcastReady;

    if (localSession != null) {
      return localSession.copyWith(
        audioSourceEnabled: audioSourceEnabled,
        microphoneEnabled: microphoneEnabled,
        serverUrl: internetReady ? settings.signalingServerUrl : null,
      );
    }

    if (!internetReady) {
      if (localFailure != null) {
        throw localFailure;
      }
      throw AppException(
        'Connect to Wi-Fi, enable hotspot, or connect an internet signaling server to start broadcasting.',
        code: 'broadcast_unavailable',
      );
    }

    final serverUrl = settings.signalingServerUrl?.trim();
    if (serverUrl == null || serverUrl.isEmpty) {
      throw AppException(
        'Internet signaling is enabled, but server URL is missing.',
        code: 'internet_mode_not_configured',
      );
    }

    return HostedSession(
      roomId: 'SW-INTERNET',
      roomName: roomName,
      mode: StreamingMode.internet,
      serverUrl: serverUrl,
      roomPinProtected: pinProtected,
      pin: pin,
      audioSourceEnabled: audioSourceEnabled,
      microphoneEnabled: microphoneEnabled,
    );
  }

  String buildAppQrPayload(HostedSession session, {String? appVersion}) {
    return _joinLinkService.buildAppQrPayload(session, appVersion: appVersion);
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

  Future<void> stopLocalSession() {
    return _localSessionServer.stopRoom();
  }
}
