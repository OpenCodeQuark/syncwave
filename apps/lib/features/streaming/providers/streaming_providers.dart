import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/signaling_web_socket_client.dart';
import '../services/join_link_service.dart';
import '../services/local_network_info_service.dart';
import '../services/local_session_server.dart';
import '../services/pin_validation_service.dart';
import '../services/remote_signaling_client.dart';
import '../services/remote_server_status_service.dart';
import '../services/room_discovery_service.dart';
import '../services/server_connection_pin_repository.dart';
import '../services/server_connection_pin_validation_service.dart';
import '../services/server_url_service.dart';
import '../services/streaming_coordinator.dart';
import '../services/streaming_settings_repository.dart';

final serverUrlServiceProvider = Provider<ServerUrlService>(
  (ref) => ServerUrlService(),
);

final pinValidationServiceProvider = Provider<PinValidationService>(
  (ref) => PinValidationService(),
);

final serverConnectionPinValidationServiceProvider =
    Provider<ServerConnectionPinValidationService>(
      (ref) => ServerConnectionPinValidationService(),
    );

final serverConnectionPinRepositoryProvider =
    Provider<ServerConnectionPinRepository>(
      (ref) => ServerConnectionPinRepository(),
    );

final streamingSettingsRepositoryProvider =
    Provider<StreamingSettingsRepository>(
      (ref) => StreamingSettingsRepository(
        serverUrlService: ref.watch(serverUrlServiceProvider),
        serverConnectionPinRepository: ref.watch(
          serverConnectionPinRepositoryProvider,
        ),
        serverConnectionPinValidationService: ref.watch(
          serverConnectionPinValidationServiceProvider,
        ),
      ),
    );

final roomDiscoveryServiceProvider = Provider<RoomDiscoveryService>(
  (ref) => RoomDiscoveryService(
    pinValidationService: ref.watch(pinValidationServiceProvider),
  ),
);

final joinLinkServiceProvider = Provider<JoinLinkService>(
  (ref) => JoinLinkService(
    pinValidationService: ref.watch(pinValidationServiceProvider),
  ),
);

final localNetworkInfoServiceProvider = Provider<LocalNetworkInfoService>(
  (ref) => LocalNetworkInfoService(),
);

final localSessionServerProvider = Provider<LocalSessionServer>((ref) {
  return LocalSessionServer(
    localNetworkInfoService: ref.watch(localNetworkInfoServiceProvider),
  );
});

final remoteSignalingWebSocketClientProvider =
    Provider<SignalingWebSocketClient>((ref) => SignalingWebSocketClient());

final remoteSignalingClientProvider = Provider<RemoteSignalingClient>((ref) {
  return RemoteSignalingClient(
    ref.watch(remoteSignalingWebSocketClientProvider),
  );
});

final remoteServerStatusServiceProvider = Provider<RemoteServerStatusService>((
  ref,
) {
  final service = RemoteServerStatusService(
    serverUrlService: ref.watch(serverUrlServiceProvider),
    remoteSignalingClient: ref.watch(remoteSignalingClientProvider),
  );
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

final streamingCoordinatorProvider = Provider<StreamingCoordinator>((ref) {
  return StreamingCoordinator(
    localSessionServer: ref.watch(localSessionServerProvider),
    joinLinkService: ref.watch(joinLinkServiceProvider),
  );
});
