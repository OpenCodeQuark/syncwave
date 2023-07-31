import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/errors/app_exception.dart';
import '../models/remote_server_connection_state.dart';
import '../models/remote_server_status.dart';
import '../models/server_handshake_models.dart';
import 'remote_signaling_client.dart';
import 'server_url_service.dart';

class RemoteServerStatusService {
  RemoteServerStatusService({
    required ServerUrlService serverUrlService,
    required RemoteSignalingGateway remoteSignalingClient,
    http.Client? httpClient,
    DateTime Function()? now,
  }) : _serverUrlService = serverUrlService,
       _remoteSignalingClient = remoteSignalingClient,
       _httpClient = httpClient ?? http.Client(),
       _now = now ?? DateTime.now;

  final ServerUrlService _serverUrlService;
  final RemoteSignalingGateway _remoteSignalingClient;
  final http.Client _httpClient;
  final DateTime Function() _now;

  final _statusController = StreamController<RemoteServerStatus>.broadcast();

  Stream<Map<String, dynamic>>? _eventStream;
  StreamSubscription<Map<String, dynamic>>? _connectionSubscription;
  bool _connected = false;

  RemoteServerStatus _lastStatus = const RemoteServerStatus();

  Stream<RemoteServerStatus> get statusStream => _statusController.stream;

  RemoteServerStatus get lastStatus => _lastStatus;

  bool get isConnected => _connected;

  Future<RemoteServerStatus> checkServer({
    required String serverUrlInput,
    required String appName,
    required String appVersion,
    required String protocolVersion,
    String? serverConnectionPin,
    bool attemptWebSocket = false,
  }) async {
    final trimmed = serverUrlInput.trim();
    if (trimmed.isEmpty) {
      return _emitStatus(
        const RemoteServerStatus(
          state: RemoteServerConnectionState.notConfigured,
          message: 'Configure a server URL to enable internet signaling.',
        ),
      );
    }

    String normalizedWebSocketUrl;
    String statusUrl;

    try {
      normalizedWebSocketUrl = _serverUrlService.normalize(trimmed);
      statusUrl = _serverUrlService.deriveStatusUrl(normalizedWebSocketUrl);
    } on FormatException catch (error) {
      return _emitStatus(
        RemoteServerStatus(
          state: RemoteServerConnectionState.invalidUrl,
          message: error.message,
          checkedAt: _now(),
        ),
      );
    }

    _emitStatus(
      RemoteServerStatus(
        normalizedWebSocketUrl: normalizedWebSocketUrl,
        statusUrl: statusUrl,
        state: RemoteServerConnectionState.checking,
        checkedAt: _now(),
      ),
    );

    try {
      final statusResponse = await _httpClient
          .get(Uri.parse(statusUrl))
          .timeout(const Duration(seconds: 5));
      final healthUrl = Uri.parse(statusUrl).replace(path: '/health').toString();

      Map<String, dynamic>? decoded;
      var sourceWasStatus = false;
      var errorCode = '';
      if (statusResponse.statusCode >= 200 && statusResponse.statusCode < 300) {
        final statusDecoded = jsonDecode(statusResponse.body);
        if (statusDecoded is Map<String, dynamic>) {
          decoded = statusDecoded;
          sourceWasStatus = true;
        }
      } else {
        errorCode = 'http_${statusResponse.statusCode}';
      }

      if (decoded == null) {
        final healthResponse = await _httpClient
            .get(Uri.parse(healthUrl))
            .timeout(const Duration(seconds: 5));

        if (healthResponse.statusCode < 200 || healthResponse.statusCode >= 300) {
          return _emitStatus(
            RemoteServerStatus(
              normalizedWebSocketUrl: normalizedWebSocketUrl,
              statusUrl: statusUrl,
              state: RemoteServerConnectionState.disconnected,
              message:
                  'Server status failed (${statusResponse.statusCode}); health check failed (${healthResponse.statusCode}).',
              errorCode: errorCode.isEmpty
                  ? 'http_${healthResponse.statusCode}'
                  : errorCode,
              checkedAt: _now(),
            ),
          );
        }

        final healthDecoded = jsonDecode(healthResponse.body);
        if (healthDecoded is! Map<String, dynamic>) {
          return _emitStatus(
            RemoteServerStatus(
              normalizedWebSocketUrl: normalizedWebSocketUrl,
              statusUrl: statusUrl,
              state: RemoteServerConnectionState.notSyncWaveServer,
              message: 'Health endpoint returned an unsupported payload.',
              checkedAt: _now(),
              reachable: true,
            ),
          );
        }

        decoded = healthDecoded;
      }

      final app = (decoded['app'] ?? decoded['service'])?.toString() ?? '';
      final isSyncWaveServer = app.toLowerCase().contains('syncwave');

      final serverStatus = RemoteServerStatus(
        normalizedWebSocketUrl: normalizedWebSocketUrl,
        statusUrl: statusUrl,
        reachable: true,
        isSyncWaveServer: isSyncWaveServer,
        websocketConnected: false,
        handshakeAccepted: false,
        authenticationRequired: _toBool(decoded['authenticationRequired']),
        serverVersion:
            decoded['version']?.toString() ?? decoded['appVersion']?.toString(),
        protocolVersion:
            decoded['supportedProtocolVersion']?.toString() ??
            decoded['protocolVersion']?.toString(),
        redisConnected: _toNullableBool(decoded['redisConnected']),
        activeRooms: _toNullableInt(decoded['activeRooms']),
        activeConnections: _toNullableInt(decoded['activeConnections']),
        checkedAt: _now(),
        state: isSyncWaveServer
            ? (sourceWasStatus
                  ? RemoteServerConnectionState.serverOnlineNotConnected
                  : RemoteServerConnectionState.serverReachable)
            : RemoteServerConnectionState.notSyncWaveServer,
        message: isSyncWaveServer
            ? (sourceWasStatus
                  ? 'Server online, not connected.'
                  : 'Server reachable via /health. Connect to verify signaling.')
            : 'Status endpoint is reachable but does not look like SyncWave.',
      );

      if (!attemptWebSocket) {
        return _emitStatus(serverStatus);
      }

      final probeStatus = await _probeWebSocket(
        baseStatus: serverStatus,
        appName: appName,
        appVersion: appVersion,
        protocolVersion: protocolVersion,
        serverConnectionPin: serverConnectionPin,
      );
      return _emitStatus(probeStatus);
    } on TimeoutException {
      return _emitStatus(
        RemoteServerStatus(
          normalizedWebSocketUrl: normalizedWebSocketUrl,
          statusUrl: statusUrl,
          checkedAt: _now(),
          state: RemoteServerConnectionState.disconnected,
          message: 'Status check timed out.',
          errorCode: 'status_timeout',
        ),
      );
    } catch (error) {
      return _emitStatus(
        RemoteServerStatus(
          normalizedWebSocketUrl: normalizedWebSocketUrl,
          statusUrl: statusUrl,
          checkedAt: _now(),
          state: RemoteServerConnectionState.disconnected,
          message: error.toString(),
          errorCode: 'status_unreachable',
        ),
      );
    }
  }

  Future<RemoteServerStatus> connect({
    required String serverUrlInput,
    required String appName,
    required String appVersion,
    required String protocolVersion,
    String? serverConnectionPin,
  }) async {
    final checked = await checkServer(
      serverUrlInput: serverUrlInput,
      appName: appName,
      appVersion: appVersion,
      protocolVersion: protocolVersion,
      serverConnectionPin: serverConnectionPin,
      attemptWebSocket: false,
    );

    if (!checked.reachable || !checked.isSyncWaveServer) {
      return checked;
    }

    await disconnect();

    final normalizedUrl = checked.normalizedWebSocketUrl;
    if (normalizedUrl == null) {
      return _emitStatus(
        checked.copyWith(
          state: RemoteServerConnectionState.invalidUrl,
          message: 'Invalid normalized WebSocket URL.',
          checkedAt: _now(),
        ),
      );
    }

    try {
      _eventStream = _remoteSignalingClient.connect(normalizedUrl);
      final eventStream = _eventStream;
      if (eventStream == null) {
        throw AppException('WebSocket stream unavailable.');
      }

      await _waitForConnectionReady(eventStream);

      final hello = ServerHelloEvent(
        appName: appName,
        appVersion: appVersion,
        protocolVersion: protocolVersion,
        clientPlatform: _platformName(),
        serverConnectionPin: serverConnectionPin,
      );

      _remoteSignalingClient.sendEvent(hello.toJson());
      final handshake = await _waitForHandshake(eventStream);

      if (handshake.type == 'server.auth_required') {
        await disconnect();
        return _emitStatus(
          checked.copyWith(
            authenticationRequired: true,
            authenticationFailed: false,
            websocketConnected: false,
            handshakeAccepted: false,
            state: RemoteServerConnectionState.authenticationRequired,
            checkedAt: _now(),
            message: handshake.message ?? 'Server Connection PIN is required.',
            errorCode: handshake.errorCode ?? 'server_connection_pin_required',
          ),
        );
      }

      if (handshake.type == 'server.auth_failed') {
        await disconnect();
        return _emitStatus(
          checked.copyWith(
            authenticationRequired: false,
            authenticationFailed: true,
            websocketConnected: false,
            handshakeAccepted: false,
            state: RemoteServerConnectionState.authenticationFailed,
            checkedAt: _now(),
            message:
                handshake.message ?? 'Server Connection PIN authentication failed.',
            errorCode: handshake.errorCode ?? 'server_connection_pin_invalid',
          ),
        );
      }

      if (handshake.type == 'server.unsupported_version') {
        await disconnect();
        return _emitStatus(
          checked.copyWith(
            websocketConnected: false,
            handshakeAccepted: false,
            state: RemoteServerConnectionState.websocketFailed,
            checkedAt: _now(),
            message: handshake.message ?? 'Unsupported server protocol version.',
            errorCode: handshake.errorCode ?? 'unsupported_protocol_version',
          ),
        );
      }

      if (!handshake.accepted) {
        await disconnect();
        return _emitStatus(
          checked.copyWith(
            websocketConnected: false,
            handshakeAccepted: false,
            state: RemoteServerConnectionState.websocketFailed,
            checkedAt: _now(),
            message: handshake.message ?? 'WebSocket handshake failed.',
            errorCode: handshake.errorCode ?? 'websocket_handshake_failed',
          ),
        );
      }

      _connected = true;
      _connectionSubscription = eventStream.listen(
        (_) {},
        onError: (_) {
          _connected = false;
          _emitStatus(
            _lastStatus.copyWith(
              websocketConnected: false,
              state: RemoteServerConnectionState.disconnected,
              checkedAt: _now(),
              message: 'Disconnected from signaling server.',
              errorCode: 'websocket_disconnected',
            ),
          );
        },
        onDone: () {
          _connected = false;
          _emitStatus(
            _lastStatus.copyWith(
              websocketConnected: false,
              state: RemoteServerConnectionState.disconnected,
              checkedAt: _now(),
              message: 'Disconnected from signaling server.',
              errorCode: 'websocket_disconnected',
            ),
          );
        },
      );

      return _emitStatus(
        checked.copyWith(
          websocketConnected: true,
          handshakeAccepted: true,
          authenticationRequired: false,
          authenticationFailed: false,
          serverVersion: handshake.serverVersion ?? checked.serverVersion,
          protocolVersion: handshake.protocolVersion ?? checked.protocolVersion,
          state: RemoteServerConnectionState.connected,
          checkedAt: _now(),
          message: 'Connected.',
          errorCode: null,
        ),
      );
    } catch (error) {
      await disconnect();
      return _emitStatus(
        checked.copyWith(
          websocketConnected: false,
          handshakeAccepted: false,
          state: RemoteServerConnectionState.websocketFailed,
          checkedAt: _now(),
          message: error.toString(),
          errorCode: 'websocket_connect_failed',
        ),
      );
    }
  }

  Future<RemoteServerStatus> disconnect() async {
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;
    _eventStream = null;
    _connected = false;
    await _remoteSignalingClient.disconnect();

    if (_lastStatus.normalizedWebSocketUrl == null &&
        _lastStatus.statusUrl == null) {
      return _emitStatus(const RemoteServerStatus());
    }

    return _emitStatus(
      _lastStatus.copyWith(
        websocketConnected: false,
        handshakeAccepted: false,
        state: _lastStatus.reachable
            ? RemoteServerConnectionState.serverOnlineNotConnected
            : RemoteServerConnectionState.disconnected,
        checkedAt: _now(),
        message: _lastStatus.reachable
            ? 'Server online, not connected.'
            : 'Disconnected.',
      ),
    );
  }

  Future<void> dispose() async {
    await disconnect();
    await _statusController.close();
    _httpClient.close();
  }

  Future<RemoteServerStatus> _probeWebSocket({
    required RemoteServerStatus baseStatus,
    required String appName,
    required String appVersion,
    required String protocolVersion,
    String? serverConnectionPin,
  }) async {
    final wsUrl = baseStatus.normalizedWebSocketUrl;
    if (wsUrl == null || wsUrl.trim().isEmpty) {
      return baseStatus.copyWith(
        state: RemoteServerConnectionState.invalidUrl,
        checkedAt: _now(),
        message: 'Invalid WebSocket URL for probe.',
      );
    }

    try {
      final stream = _remoteSignalingClient.connect(wsUrl);
      await _waitForConnectionReady(stream);

      final hello = ServerHelloEvent(
        appName: appName,
        appVersion: appVersion,
        protocolVersion: protocolVersion,
        clientPlatform: _platformName(),
        serverConnectionPin: serverConnectionPin,
      );
      _remoteSignalingClient.sendEvent(hello.toJson());

      final handshake = await _waitForHandshake(stream);
      await _remoteSignalingClient.disconnect();

      if (handshake.type == 'server.auth_required') {
        return baseStatus.copyWith(
          authenticationRequired: true,
          authenticationFailed: false,
          websocketConnected: false,
          handshakeAccepted: false,
          state: RemoteServerConnectionState.authenticationRequired,
          checkedAt: _now(),
          message: handshake.message ?? 'Server Connection PIN is required.',
          errorCode: handshake.errorCode ?? 'server_connection_pin_required',
        );
      }

      if (handshake.type == 'server.auth_failed') {
        return baseStatus.copyWith(
          authenticationRequired: false,
          authenticationFailed: true,
          websocketConnected: false,
          handshakeAccepted: false,
          state: RemoteServerConnectionState.authenticationFailed,
          checkedAt: _now(),
          message: handshake.message ?? 'Server Connection PIN authentication failed.',
          errorCode: handshake.errorCode ?? 'server_connection_pin_invalid',
        );
      }

      if (!handshake.accepted) {
        return baseStatus.copyWith(
          websocketConnected: false,
          handshakeAccepted: false,
          state: RemoteServerConnectionState.websocketFailed,
          checkedAt: _now(),
          message: handshake.message ?? 'WebSocket handshake failed.',
          errorCode: handshake.errorCode ?? 'websocket_handshake_failed',
        );
      }

      return baseStatus.copyWith(
        websocketConnected: false,
        handshakeAccepted: true,
        authenticationRequired: false,
        authenticationFailed: false,
        serverVersion: handshake.serverVersion ?? baseStatus.serverVersion,
        protocolVersion: handshake.protocolVersion ?? baseStatus.protocolVersion,
        state: RemoteServerConnectionState.serverOnlineNotConnected,
        checkedAt: _now(),
        message: 'Server online, not connected.',
      );
    } catch (error) {
      await _remoteSignalingClient.disconnect();
      return baseStatus.copyWith(
        websocketConnected: false,
        handshakeAccepted: false,
        state: RemoteServerConnectionState.websocketFailed,
        checkedAt: _now(),
        message: error.toString(),
        errorCode: 'websocket_probe_failed',
      );
    }
  }

  Future<void> _waitForConnectionReady(Stream<Map<String, dynamic>> stream) async {
    await stream
        .firstWhere((event) => event['type']?.toString() == 'connection.ready')
        .timeout(const Duration(seconds: 5));
  }

  Future<ServerHandshakeResponse> _waitForHandshake(
    Stream<Map<String, dynamic>> stream,
  ) async {
    final handshakeEvent = await stream.firstWhere((event) {
      final type = event['type']?.toString();
      return type == 'server.ready' ||
          type == 'server.auth_required' ||
          type == 'server.auth_failed' ||
          type == 'server.unsupported_version' ||
          type == 'error';
    }).timeout(const Duration(seconds: 5));

    return ServerHandshakeResponse.fromEvent(handshakeEvent);
  }

  RemoteServerStatus _emitStatus(RemoteServerStatus status) {
    _lastStatus = status;
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
    return status;
  }

  String _platformName() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }

  bool _toBool(Object? value) {
    return value == true;
  }

  bool? _toNullableBool(Object? value) {
    if (value is bool) {
      return value;
    }
    return null;
  }

  int? _toNullableInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }
}
