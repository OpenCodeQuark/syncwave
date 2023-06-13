import '../../../core/errors/app_exception.dart';
import '../models/hosted_session.dart';
import '../models/streaming_mode.dart';
import '../models/streaming_settings.dart';
import 'join_link_service.dart';
import 'local_session_server.dart';
import 'remote_signaling_client.dart';

class StreamingCoordinator {
  StreamingCoordinator({
    required LocalSessionServer localSessionServer,
    required RemoteSignalingClient remoteSignalingClient,
    required JoinLinkService joinLinkService,
  }) : _localSessionServer = localSessionServer,
       _remoteSignalingClient = remoteSignalingClient,
       _joinLinkService = joinLinkService;

  final LocalSessionServer _localSessionServer;
  final RemoteSignalingClient _remoteSignalingClient;
  final JoinLinkService _joinLinkService;

  Future<HostedSession> createHostSession({
    required StreamingMode mode,
    required String roomName,
    required bool pinProtected,
    String? pin,
    required StreamingSettings settings,
  }) async {
    if (mode == StreamingMode.local) {
      return _localSessionServer.createRoom(
        roomName: roomName,
        pinProtected: pinProtected,
        pin: pin,
      );
    }

    final serverUrl = settings.signalingServerUrl?.trim();
    if (!settings.internetStreamingEnabled ||
        serverUrl == null ||
        serverUrl.isEmpty) {
      throw AppException(
        'Internet mode requires enabling internet streaming and a valid signaling server URL.',
        code: 'internet_mode_not_configured',
      );
    }

    _remoteSignalingClient.connect(serverUrl);
    return HostedSession(
      roomId: 'SW-INTERNET',
      roomName: roomName,
      mode: StreamingMode.internet,
      serverUrl: serverUrl,
      pinProtected: pinProtected,
      pin: pin,
    );
  }

  String buildQrPayload(HostedSession session) {
    return _joinLinkService.buildQrPayload(session);
  }

  Future<void> stopLocalSession() {
    return _localSessionServer.stopRoom();
  }
}
