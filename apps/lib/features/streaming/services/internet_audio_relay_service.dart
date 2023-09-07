import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'local_audio_broadcast_server.dart';

enum InternetRelayPhase { disconnected, connecting, connected, error }

class InternetAudioRelayService {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  final _phaseController = StreamController<InternetRelayPhase>.broadcast();

  bool _connected = false;
  String? _activeRoomId;
  String? _lastErrorCode;

  bool get isConnected => _connected;
  String? get activeRoomId => _activeRoomId;
  String? get lastErrorCode => _lastErrorCode;
  Stream<InternetRelayPhase> get phaseStream => _phaseController.stream;

  Future<bool> connect({
    required String websocketUrl,
    required String roomId,
    required String appName,
    required String appVersion,
    required String protocolVersion,
    String? serverConnectionPin,
  }) async {
    await disconnect();
    _emitPhase(InternetRelayPhase.connecting);

    final readyCompleter = Completer<bool>();
    final handshakeCompleter = Completer<bool>();
    try {
      _channel = WebSocketChannel.connect(Uri.parse(websocketUrl));
      _subscription = _channel!.stream.listen(
        (event) {
          Map<String, dynamic>? payload;
          if (event is String) {
            final decoded = jsonDecode(event);
            if (decoded is Map<String, dynamic>) {
              payload = decoded;
            }
          }
          if (payload == null) {
            return;
          }

          final type = payload['type']?.toString();
          if (type == 'connection.ready' && !readyCompleter.isCompleted) {
            readyCompleter.complete(true);
            return;
          }
          if (type == 'server.ready' && !handshakeCompleter.isCompleted) {
            handshakeCompleter.complete(true);
            return;
          }
          if ((type == 'server.auth_required' ||
                  type == 'server.auth_failed' ||
                  type == 'server.unsupported_version') &&
              !handshakeCompleter.isCompleted) {
            _lastErrorCode = type;
            handshakeCompleter.complete(false);
          }
        },
        onError: (_) {
          _connected = false;
          _lastErrorCode = 'relay_stream_error';
          _emitPhase(InternetRelayPhase.error);
          if (!readyCompleter.isCompleted) {
            readyCompleter.complete(false);
          }
          if (!handshakeCompleter.isCompleted) {
            handshakeCompleter.complete(false);
          }
        },
        onDone: () {
          _connected = false;
          if (_activeRoomId != null) {
            _lastErrorCode = 'relay_stream_closed';
            _emitPhase(InternetRelayPhase.error);
          } else {
            _emitPhase(InternetRelayPhase.disconnected);
          }
        },
        cancelOnError: true,
      );
    } catch (_) {
      _lastErrorCode = 'relay_connect_failed';
      _emitPhase(InternetRelayPhase.error);
      await disconnect();
      return false;
    }

    final ready = await readyCompleter.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => false,
    );
    if (!ready) {
      await disconnect();
      return false;
    }

    _send({
      'type': 'server.hello',
      'payload': {
        'appName': appName,
        'appVersion': appVersion,
        'protocolVersion': protocolVersion,
        'clientPlatform': 'android',
        if (serverConnectionPin != null &&
            serverConnectionPin.trim().isNotEmpty)
          'serverConnectionPin': serverConnectionPin.trim(),
      },
    });

    final handshakeAccepted = await handshakeCompleter.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => false,
    );
    if (!handshakeAccepted) {
      _lastErrorCode ??= 'relay_handshake_failed';
      await disconnect();
      return false;
    }

    _send({
      'type': 'stream.host_start',
      'roomId': roomId,
      'payload': {
        'roomId': roomId,
        'streamStartedAt': DateTime.now().millisecondsSinceEpoch,
        'targetBufferMs': 260,
      },
    });

    _connected = true;
    _lastErrorCode = null;
    _activeRoomId = roomId;
    _emitPhase(InternetRelayPhase.connected);
    return true;
  }

  void sendAudioChunk(StreamAudioChunk chunk) {
    if (!_connected || _channel == null) {
      return;
    }

    _send({
      'type': 'stream.audio_chunk',
      'roomId': chunk.roomId,
      'payload': {
        'roomId': chunk.roomId,
        'sequence': chunk.sequence,
        'captureTimestamp': chunk.captureTimestampMs,
        'hostTimestamp': chunk.hostTimestampMs,
        'sampleRate': chunk.sampleRate,
        'channelCount': chunk.channelCount,
        'format': chunk.format,
        'durationMs': chunk.durationMs,
        'streamStartedAt': chunk.streamStartedAtMs,
        'payload': chunk.payloadBase64,
      },
    });
  }

  Future<void> disconnect() async {
    if (_connected && _activeRoomId != null) {
      _send({
        'type': 'stream.host_stop',
        'roomId': _activeRoomId,
        'payload': {'roomId': _activeRoomId},
      });
    }

    _connected = false;
    _activeRoomId = null;
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
    _emitPhase(InternetRelayPhase.disconnected);
  }

  void _send(Map<String, dynamic> event) {
    final channel = _channel;
    if (channel == null) {
      return;
    }
    channel.sink.add(jsonEncode(event));
  }

  Future<void> dispose() async {
    await disconnect();
    await _phaseController.close();
  }

  void _emitPhase(InternetRelayPhase phase) {
    if (_phaseController.isClosed) {
      return;
    }
    _phaseController.add(phase);
  }
}
