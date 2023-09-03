import 'package:flutter_test/flutter_test.dart';
import 'package:syncwave/features/streaming/models/internet_mode_gate.dart';
import 'package:syncwave/features/streaming/models/remote_server_connection_state.dart';
import 'package:syncwave/features/streaming/models/remote_server_status.dart';
import 'package:syncwave/features/streaming/models/streaming_settings.dart';

void main() {
  test(
    'internet broadcast is available only when configured and connected',
    () {
      const settings = StreamingSettings(
        internetStreamingEnabled: true,
        signalingServerUrl: 'wss://your-server.example.com/ws',
      );

      const disconnectedStatus = RemoteServerStatus(
        reachable: true,
        isSyncWaveServer: true,
        websocketConnected: false,
        handshakeAccepted: true,
        state: RemoteServerConnectionState.serverOnlineNotConnected,
      );

      const connectedStatus = RemoteServerStatus(
        reachable: true,
        isSyncWaveServer: true,
        websocketConnected: true,
        handshakeAccepted: true,
        state: RemoteServerConnectionState.connected,
      );

      expect(
        isInternetBroadcastAvailable(settings, disconnectedStatus),
        isFalse,
      );
      expect(isInternetBroadcastAvailable(settings, connectedStatus), isTrue);
    },
  );
}
