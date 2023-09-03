import 'package:flutter_test/flutter_test.dart';
import 'package:syncwave/features/settings/presentation/utils/server_status_copy_formatter.dart';
import 'package:syncwave/features/streaming/models/remote_server_connection_state.dart';
import 'package:syncwave/features/streaming/models/remote_server_status.dart';

void main() {
  group('ServerStatusCopyFormatter', () {
    final formatter = ServerStatusCopyFormatter();

    test('formats full status details', () {
      final result = formatter.format(
        connectionState: RemoteServerConnectionState.connected,
        status: RemoteServerStatus(
          normalizedWebSocketUrl: 'wss://your-server.example.com/ws',
          statusUrl: 'https://your-server.example.com/status',
          checkedAt: DateTime.utc(2026, 5, 10, 8, 30),
          serverVersion: '1.0.0',
          protocolVersion: '1',
          redisConnected: false,
          activeRooms: 3,
          activeConnections: 8,
          message: 'Connected.',
        ),
      );

      expect(result, contains('Connection state: Connected'));
      expect(
        result,
        contains('WebSocket URL: wss://your-server.example.com/ws'),
      );
      expect(
        result,
        contains('Status URL: https://your-server.example.com/status'),
      );
      expect(result, contains('Redis connected: false'));
      expect(result, contains('Active rooms: 3'));
      expect(result, contains('Active connections: 8'));
    });

    test('falls back to derived urls when status is absent', () {
      final result = formatter.format(
        connectionState: RemoteServerConnectionState.notConfigured,
        status: null,
        normalizedWebSocketUrl: 'ws://192.168.1.20:9000/ws',
        derivedStatusUrl: 'http://192.168.1.20:9000/status',
      );

      expect(result, contains('Connection state: Not configured'));
      expect(result, contains('WebSocket URL: ws://192.168.1.20:9000/ws'));
      expect(result, contains('Status URL: http://192.168.1.20:9000/status'));
    });
  });
}
