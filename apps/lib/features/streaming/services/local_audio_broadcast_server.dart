import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../../core/errors/app_exception.dart';

class LocalAudioBroadcastServer {
  HttpServer? _server;
  final Set<WebSocket> _listeners = <WebSocket>{};
  final _listenerCountController = StreamController<int>.broadcast();

  String? _roomId;

  bool get isRunning => _server != null;
  int get listenerCount => _listeners.length;
  Stream<int> get listenerCountStream => _listenerCountController.stream;

  Future<void> start({
    required String host,
    required int port,
    required String roomId,
  }) async {
    if (_server != null) {
      return;
    }

    _roomId = roomId;

    try {
      _server = await HttpServer.bind(host, port, shared: true);
    } catch (_) {
      throw AppException(
        'Unable to start local broadcast endpoint at $host:$port.',
        code: 'local_audio_server_bind_failed',
      );
    }

    unawaited(
      _server!.forEach((request) async {
        try {
          await _handleRequest(request);
        } catch (_) {
          request.response
            ..statusCode = HttpStatus.internalServerError
            ..write('Internal server error')
            ..close();
        }
      }),
    );
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final path = request.uri.path;

    if (path == '/status') {
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode({
          'app': 'SyncWave Local Broadcast',
          'status': 'ok',
          'roomId': _roomId,
          'listeners': _listeners.length,
          'audioWebSocketPath': '/stream/audio',
        }),
      );
      await request.response.close();
      return;
    }

    if (path == '/stream/join') {
      request.response.headers.contentType = ContentType.html;
      request.response.write(_browserJoinHtml(request));
      await request.response.close();
      return;
    }

    if (path == '/stream/audio') {
      if (!WebSocketTransformer.isUpgradeRequest(request)) {
        request.response
          ..statusCode = HttpStatus.badRequest
          ..write('WebSocket upgrade required')
          ..close();
        return;
      }

      final room = request.uri.queryParameters['room'];
      if (_roomId != null &&
          room != null &&
          room.isNotEmpty &&
          room != _roomId) {
        request.response
          ..statusCode = HttpStatus.forbidden
          ..write('Room mismatch')
          ..close();
        return;
      }

      final socket = await WebSocketTransformer.upgrade(request);
      _listeners.add(socket);
      _emitListenerCount();
      socket.done.whenComplete(() {
        _listeners.remove(socket);
        _emitListenerCount();
      });
      return;
    }

    request.response
      ..statusCode = HttpStatus.notFound
      ..write('Not found')
      ..close();
  }

  Future<void> broadcast(Uint8List bytes) async {
    if (_listeners.isEmpty) {
      return;
    }

    final closed = <WebSocket>[];
    for (final socket in _listeners) {
      try {
        socket.add(bytes);
      } catch (_) {
        closed.add(socket);
      }
    }

    for (final socket in closed) {
      _listeners.remove(socket);
      await socket.close();
    }
    if (closed.isNotEmpty) {
      _emitListenerCount();
    }
  }

  Future<void> stop() async {
    final sockets = List<WebSocket>.from(_listeners);
    _listeners.clear();
    for (final socket in sockets) {
      await socket.close();
    }

    final server = _server;
    _server = null;
    _roomId = null;
    await server?.close(force: true);
    _emitListenerCount();
  }

  Future<void> dispose() async {
    await stop();
    await _listenerCountController.close();
  }

  void _emitListenerCount() {
    if (_listenerCountController.isClosed) {
      return;
    }
    _listenerCountController.add(_listeners.length);
  }

  String _browserJoinHtml(HttpRequest request) {
    final currentRoom = request.uri.queryParameters['room'] ?? _roomId ?? '';
    return '''
<!doctype html>
<html>
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width,initial-scale=1" />
  <title>SyncWave Browser Listener</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, Segoe UI, sans-serif; background: #0f172a; color: #e2e8f0; margin: 0; padding: 24px; }
    .card { max-width: 720px; margin: 0 auto; background: #111827; border: 1px solid #1f2937; border-radius: 16px; padding: 20px; }
    button { background: #0891b2; color: white; border: none; border-radius: 12px; padding: 10px 16px; font-size: 14px; cursor: pointer; }
    code { color: #67e8f9; }
  </style>
</head>
<body>
  <div class="card">
    <h2>SyncWave Browser Listener</h2>
    <p>Room: <code>${htmlEscape.convert(currentRoom)}</code></p>
    <p id="status">Disconnected</p>
    <button id="connectBtn">Connect Audio</button>
  </div>
  <script>
    const statusEl = document.getElementById('status');
    const btn = document.getElementById('connectBtn');
    let socket = null;
    let ctx = null;
    let processor = null;
    let queue = [];

    function int16ToFloat32(buffer) {
      const input = new Int16Array(buffer);
      const out = new Float32Array(input.length);
      for (let i = 0; i < input.length; i++) {
        out[i] = input[i] / 32768;
      }
      return out;
    }

    function onAudioProcess(e) {
      const output = e.outputBuffer.getChannelData(0);
      output.fill(0);
      if (queue.length === 0) return;
      const chunk = queue.shift();
      const len = Math.min(output.length, chunk.length);
      for (let i = 0; i < len; i++) {
        output[i] = chunk[i];
      }
    }

    btn.onclick = async () => {
      if (socket) return;
      const proto = location.protocol === 'https:' ? 'wss' : 'ws';
      const room = encodeURIComponent('${htmlEscape.convert(currentRoom)}');
      const wsUrl = proto + '://' + location.host + '/stream/audio?room=' + room;

      ctx = new (window.AudioContext || window.webkitAudioContext)({ sampleRate: 48000 });
      processor = ctx.createScriptProcessor(4096, 1, 1);
      processor.onaudioprocess = onAudioProcess;
      processor.connect(ctx.destination);

      socket = new WebSocket(wsUrl);
      socket.binaryType = 'arraybuffer';
      statusEl.textContent = 'Connecting...';

      socket.onopen = () => {
        statusEl.textContent = 'Connected';
      };
      socket.onmessage = (ev) => {
        if (ev.data instanceof ArrayBuffer) {
          queue.push(int16ToFloat32(ev.data));
        }
      };
      socket.onerror = () => {
        statusEl.textContent = 'Connection error';
      };
      socket.onclose = () => {
        statusEl.textContent = 'Disconnected';
        socket = null;
      };
    };
  </script>
</body>
</html>
''';
  }
}
