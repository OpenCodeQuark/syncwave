import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../errors/app_exception.dart';

class SignalingWebSocketClient {
  WebSocketChannel? _channel;

  Stream<Map<String, dynamic>> connect(String url) {
    if (_channel != null) {
      throw AppException('WebSocket connection already initialized');
    }

    _channel = WebSocketChannel.connect(Uri.parse(url));

    return _channel!.stream.map((event) {
      if (event is String) {
        final decoded = jsonDecode(event);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      }

      throw AppException('Unsupported event payload from signaling server');
    });
  }

  void send(Map<String, dynamic> event) {
    final channel = _channel;
    if (channel == null) {
      throw AppException('WebSocket connection is not initialized');
    }

    channel.sink.add(jsonEncode(event));
  }

  Future<void> close() async {
    final channel = _channel;
    _channel = null;
    await channel?.sink.close();
  }
}
