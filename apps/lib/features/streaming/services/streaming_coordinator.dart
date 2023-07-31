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
    required StreamingMode mode,
    required String roomName,
    required bool pinProtected,
    String? pin,
    required StreamingSettings settings,
    RemoteServerStatus? remoteServerStatus,
  }) async {
    if (mode == StreamingMode.local) {
      return _localSessionServer.createRoom(
        roomName: roomName,
        pinProtected: pinProtected,
        pin: pin,
      );
    }

    final serverUrl = settings.signalingServerUrl?.trim();
    if (!settings.internetModeConfigured ||
        serverUrl == null ||
        serverUrl.isEmpty) {
      throw AppException(
        'Internet mode requires enabling internet streaming and a valid signaling server URL.',
        code: 'internet_mode_not_configured',
      );
    }

    if (remoteServerStatus == null || !remoteServerStatus.internetBroadcastReady) {
      throw AppException(
        'Internet mode requires an active server connection. Use Settings > Test Connection and Connect first.',
        code: 'internet_mode_not_connected',
      );
    }

    return HostedSession(
      roomId: 'SW-INTERNET',
      roomName: roomName,
      mode: StreamingMode.internet,
      serverUrl: serverUrl,
      roomPinProtected: pinProtected,
      pin: pin,
    );
  }

  String buildAppQrPayload(HostedSession session, {String? appVersion}) {
    return _joinLinkService.buildAppQrPayload(
      session,
      appVersion: appVersion,
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
