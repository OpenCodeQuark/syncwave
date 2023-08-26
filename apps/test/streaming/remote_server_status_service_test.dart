import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:syncwave/features/streaming/models/remote_server_connection_state.dart';
import 'package:syncwave/features/streaming/services/remote_server_status_service.dart';
import 'package:syncwave/features/streaming/services/remote_signaling_client.dart';
import 'package:syncwave/features/streaming/services/server_url_service.dart';

class FakeRemoteSignalingGateway implements RemoteSignalingGateway {
  final Queue<List<Map<String, dynamic>>> _responses =
      Queue<List<Map<String, dynamic>>>();
  final List<Map<String, dynamic>> sentEvents = <Map<String, dynamic>>[];

  bool throwOnConnect = false;
  int disconnectCalls = 0;

  void enqueueResponse(List<Map<String, dynamic>> events) {
    _responses.add(events);
  }

  @override
  Stream<Map<String, dynamic>> connect(String serverUrl) {
    if (throwOnConnect) {
      throw Exception('websocket_connect_failed');
    }

    if (_responses.isEmpty) {
      return const Stream<Map<String, dynamic>>.empty();
    }

    return Stream<Map<String, dynamic>>.fromIterable(_responses.removeFirst());
  }

  @override
  Future<void> disconnect() async {
    disconnectCalls += 1;
  }

  @override
  void sendEvent(Map<String, dynamic> event) {
    sentEvents.add(event);
  }
}

void main() {
  group('RemoteServerStatusService', () {
    test('parses SyncWave /status successfully', () async {
      final gateway = FakeRemoteSignalingGateway();
      final service = RemoteServerStatusService(
        serverUrlService: ServerUrlService(),
        remoteSignalingClient: gateway,
        httpClient: MockClient((request) async {
          if (request.url.path == '/status') {
            return http.Response(
              '{"app":"SyncWave Signaling Server","version":"1.0.0","supportedProtocolVersion":"1","redisConnected":true,"activeRooms":2,"activeConnections":3,"authenticationRequired":false}',
              200,
            );
          }
          return http.Response('not found', 404);
        }),
      );

      final status = await service.checkServer(
        serverUrlInput: 'https://your-server.example.com',
        appName: 'SyncWave',
        appVersion: '1.0.0',
        protocolVersion: '1',
      );

      expect(status.normalizedWebSocketUrl, 'wss://your-server.example.com/ws');
      expect(status.statusUrl, 'https://your-server.example.com/status');
      expect(status.reachable, isTrue);
      expect(status.isSyncWaveServer, isTrue);
      expect(
        status.state,
        RemoteServerConnectionState.serverOnlineNotConnected,
      );
      expect(status.serverVersion, '1.0.0');
      expect(status.activeRooms, 2);
      expect(status.activeConnections, 3);
    });

    test('falls back to /health when /status is unavailable', () async {
      final gateway = FakeRemoteSignalingGateway();
      final service = RemoteServerStatusService(
        serverUrlService: ServerUrlService(),
        remoteSignalingClient: gateway,
        httpClient: MockClient((request) async {
          if (request.url.path == '/status') {
            return http.Response('missing', 404);
          }
          if (request.url.path == '/health') {
            return http.Response(
              '{"status":"ok","service":"SyncWave Signaling Server","environment":"development"}',
              200,
            );
          }
          return http.Response('not found', 404);
        }),
      );

      final status = await service.checkServer(
        serverUrlInput: 'wss://your-server.example.com/ws',
        appName: 'SyncWave',
        appVersion: '1.0.0',
        protocolVersion: '1',
      );

      expect(status.reachable, isTrue);
      expect(status.isSyncWaveServer, isTrue);
      expect(status.state, RemoteServerConnectionState.serverReachable);
    });

    test('returns unreachable state when HTTP probe fails', () async {
      final gateway = FakeRemoteSignalingGateway();
      final service = RemoteServerStatusService(
        serverUrlService: ServerUrlService(),
        remoteSignalingClient: gateway,
        httpClient: MockClient((request) async {
          throw Exception('network_down');
        }),
      );

      final status = await service.checkServer(
        serverUrlInput: 'https://your-server.example.com',
        appName: 'SyncWave',
        appVersion: '1.0.0',
        protocolVersion: '1',
      );

      expect(status.reachable, isFalse);
      expect(status.state, RemoteServerConnectionState.disconnected);
      expect(status.errorCode, 'status_unreachable');
    });

    test('returns websocket failed when websocket probe fails', () async {
      final gateway = FakeRemoteSignalingGateway()..throwOnConnect = true;
      final service = RemoteServerStatusService(
        serverUrlService: ServerUrlService(),
        remoteSignalingClient: gateway,
        httpClient: MockClient((request) async {
          return http.Response(
            '{"app":"SyncWave Signaling Server","version":"1.0.0","supportedProtocolVersion":"1"}',
            200,
          );
        }),
      );

      final status = await service.checkServer(
        serverUrlInput: 'https://your-server.example.com',
        appName: 'SyncWave',
        appVersion: '1.0.0',
        protocolVersion: '1',
        attemptWebSocket: true,
      );

      expect(status.state, RemoteServerConnectionState.websocketFailed);
      expect(status.handshakeAccepted, isFalse);
    });

    test(
      'returns authentication required when handshake needs server pin',
      () async {
        final gateway = FakeRemoteSignalingGateway()
          ..enqueueResponse(<Map<String, dynamic>>[
            {
              'type': 'connection.ready',
              'payload': {'protocolVersion': '1'},
            },
            {
              'type': 'server.auth_required',
              'payload': {'code': 'server_connection_pin_required'},
            },
          ]);

        final service = RemoteServerStatusService(
          serverUrlService: ServerUrlService(),
          remoteSignalingClient: gateway,
          httpClient: MockClient((request) async {
            return http.Response(
              '{"app":"SyncWave Signaling Server","version":"1.0.0","supportedProtocolVersion":"1","authenticationRequired":true}',
              200,
            );
          }),
        );

        final status = await service.checkServer(
          serverUrlInput: 'https://your-server.example.com',
          appName: 'SyncWave',
          appVersion: '1.0.0',
          protocolVersion: '1',
          attemptWebSocket: true,
        );

        expect(
          status.state,
          RemoteServerConnectionState.authenticationRequired,
        );
        expect(status.authenticationRequired, isTrue);
      },
    );

    test('returns authentication failed when server pin is wrong', () async {
      final gateway = FakeRemoteSignalingGateway()
        ..enqueueResponse(<Map<String, dynamic>>[
          {
            'type': 'connection.ready',
            'payload': {'protocolVersion': '1'},
          },
          {
            'type': 'server.auth_failed',
            'payload': {'code': 'server_connection_pin_invalid'},
          },
        ]);

      final service = RemoteServerStatusService(
        serverUrlService: ServerUrlService(),
        remoteSignalingClient: gateway,
        httpClient: MockClient((request) async {
          return http.Response(
            '{"app":"SyncWave Signaling Server","version":"1.0.0","supportedProtocolVersion":"1","authenticationRequired":true}',
            200,
          );
        }),
      );

      final status = await service.checkServer(
        serverUrlInput: 'https://your-server.example.com',
        appName: 'SyncWave',
        appVersion: '1.0.0',
        protocolVersion: '1',
        attemptWebSocket: true,
      );

      expect(status.state, RemoteServerConnectionState.authenticationFailed);
      expect(status.authenticationFailed, isTrue);
    });

    test(
      'reports handshake success without keeping socket open on test',
      () async {
        final gateway = FakeRemoteSignalingGateway()
          ..enqueueResponse(<Map<String, dynamic>>[
            {
              'type': 'connection.ready',
              'payload': {'protocolVersion': '1'},
            },
            {
              'type': 'server.ready',
              'payload': {'serverVersion': '1.0.0', 'protocolVersion': '1'},
            },
          ]);

        final service = RemoteServerStatusService(
          serverUrlService: ServerUrlService(),
          remoteSignalingClient: gateway,
          httpClient: MockClient((request) async {
            return http.Response(
              '{"app":"SyncWave Signaling Server","version":"1.0.0","supportedProtocolVersion":"1"}',
              200,
            );
          }),
        );

        final status = await service.checkServer(
          serverUrlInput: 'https://your-server.example.com',
          appName: 'SyncWave',
          appVersion: '1.0.0',
          protocolVersion: '1',
          attemptWebSocket: true,
        );

        expect(
          status.state,
          RemoteServerConnectionState.serverOnlineNotConnected,
        );
        expect(status.handshakeAccepted, isTrue);
        expect(status.websocketConnected, isFalse);
        expect(gateway.disconnectCalls, greaterThan(0));
      },
    );

    test('connect flow does not double-listen websocket stream', () async {
      final gateway = FakeRemoteSignalingGateway()
        ..enqueueResponse(<Map<String, dynamic>>[
          {
            'type': 'connection.ready',
            'payload': {'protocolVersion': '1'},
          },
          {
            'type': 'server.ready',
            'payload': {'serverVersion': '1.0.0', 'protocolVersion': '1'},
          },
        ]);

      final service = RemoteServerStatusService(
        serverUrlService: ServerUrlService(),
        remoteSignalingClient: gateway,
        httpClient: MockClient((request) async {
          return http.Response(
            '{"app":"SyncWave Signaling Server","version":"1.0.0","supportedProtocolVersion":"1"}',
            200,
          );
        }),
      );

      final status = await service.connect(
        serverUrlInput: 'https://your-server.example.com',
        appName: 'SyncWave',
        appVersion: '1.0.0',
        protocolVersion: '1',
      );

      expect(status.state, RemoteServerConnectionState.connected);
      expect(status.websocketConnected, isTrue);
      expect(status.handshakeAccepted, isTrue);
    });
  });
}
