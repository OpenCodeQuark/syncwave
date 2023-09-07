import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../../core/errors/app_exception.dart';

class StreamAudioChunk {
  const StreamAudioChunk({
    required this.roomId,
    required this.sequence,
    required this.captureTimestampMs,
    required this.hostTimestampMs,
    required this.sampleRate,
    required this.channelCount,
    required this.format,
    required this.durationMs,
    required this.payloadBase64,
    this.streamStartedAtMs,
  });

  final String roomId;
  final int sequence;
  final int captureTimestampMs;
  final int hostTimestampMs;
  final int sampleRate;
  final int channelCount;
  final String format;
  final int durationMs;
  final String payloadBase64;
  final int? streamStartedAtMs;

  Map<String, dynamic> toJson() {
    return {
      'type': 'stream.audio',
      'roomId': roomId,
      'sequence': sequence,
      'captureTimestamp': captureTimestampMs,
      'hostTimestamp': hostTimestampMs,
      'sampleRate': sampleRate,
      'channelCount': channelCount,
      'format': format,
      'durationMs': durationMs,
      'payload': payloadBase64,
    };
  }
}

class LocalAudioBroadcastServer {
  HttpServer? _server;
  final Set<WebSocket> _listeners = <WebSocket>{};
  final _listenerCountController = StreamController<int>.broadcast();

  String? _roomId;
  String? _hostAddress;
  int? _port;
  bool _roomPinProtected = false;
  String? _roomPin;

  int? _streamStartedAtMs;
  int _sampleRate = 48000;
  int _channelCount = 1;
  String _format = 'pcm16';
  final int _targetBufferMs = 260;
  int _syncTick = 0;

  bool get isRunning => _server != null;
  int get listenerCount => _listeners.length;
  Stream<int> get listenerCountStream => _listenerCountController.stream;
  int? get port => _server?.port ?? _port;
  String? get hostAddress => _hostAddress;

  Future<void> start({
    required String host,
    required int port,
    required String roomId,
    bool roomPinProtected = false,
    String? roomPin,
  }) async {
    if (_server != null) {
      return;
    }

    _roomId = roomId;
    _hostAddress = host;
    _port = port;
    _roomPinProtected = roomPinProtected;
    _roomPin = roomPinProtected ? roomPin?.trim() : null;
    _streamStartedAtMs = DateTime.now().millisecondsSinceEpoch;

    try {
      _server = await HttpServer.bind(
        InternetAddress.anyIPv4,
        port,
        shared: true,
      );
      _port = _server!.port;
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
            ..write('Internal server error');
          await request.response.close();
        }
      }),
    );
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final response = request.response;
    _setBaseHeaders(response);

    if (request.method == 'OPTIONS') {
      response.statusCode = HttpStatus.noContent;
      await response.close();
      return;
    }

    final path = request.uri.path;

    if (path == '/') {
      final redirectSuffix = _roomId == null ? '' : '?room=$_roomId';
      response.statusCode = HttpStatus.temporaryRedirect;
      response.headers.set(
        HttpHeaders.locationHeader,
        '/stream/join$redirectSuffix',
      );
      await response.close();
      return;
    }

    if (path == '/status') {
      response.headers.contentType = ContentType(
        'application',
        'json',
        charset: 'utf-8',
      );
      response.write(
        jsonEncode({
          'app': 'SyncWave Local Broadcast',
          'status': 'ok',
          'roomId': _roomId,
          'hostAddress': _hostAddress,
          'hostPort': _port,
          'listeners': _listeners.length,
          'audioWebSocketPath': '/stream/audio',
          'targetBufferMs': _targetBufferMs,
          'streamStartedAt': _streamStartedAtMs,
          'roomPinProtected': _roomPinProtected,
        }),
      );
      await response.close();
      return;
    }

    if (path == '/stream/join') {
      response.headers.contentType = ContentType(
        'text',
        'html',
        charset: 'utf-8',
      );
      response.write(_browserJoinHtml(request));
      await response.close();
      return;
    }

    if (path == '/stream/audio') {
      if (!WebSocketTransformer.isUpgradeRequest(request)) {
        response
          ..statusCode = HttpStatus.badRequest
          ..write('WebSocket upgrade required');
        await response.close();
        return;
      }

      final room =
          (request.uri.queryParameters['room'] ??
                  request.uri.queryParameters['roomId'])
              ?.trim();
      if (_roomId != null &&
          room != null &&
          room.isNotEmpty &&
          room != _roomId) {
        response
          ..statusCode = HttpStatus.forbidden
          ..write('Room mismatch');
        await response.close();
        return;
      }

      final pin = request.uri.queryParameters['pin']?.trim();
      if (pin != null && pin.isNotEmpty && !RegExp(r'^\d{6}$').hasMatch(pin)) {
        response
          ..statusCode = HttpStatus.badRequest
          ..write('PIN must be exactly 6 digits');
        await response.close();
        return;
      }
      if (_roomPinProtected) {
        if (pin == null || pin.isEmpty || _roomPin == null || pin != _roomPin) {
          response
            ..statusCode = HttpStatus.unauthorized
            ..write('Room PIN is required to join this stream');
          await response.close();
          return;
        }
      }

      response.headers.set('Access-Control-Allow-Origin', '*');
      final socket = await WebSocketTransformer.upgrade(request);
      _listeners.add(socket);
      _emitListenerCount();
      _sendMeta(socket);

      socket.listen(
        (message) {
          _handleListenerMessage(socket, message);
        },
        onDone: () {
          _listeners.remove(socket);
          _emitListenerCount();
        },
        onError: (_) {
          _listeners.remove(socket);
          _emitListenerCount();
        },
        cancelOnError: true,
      );
      return;
    }

    response
      ..statusCode = HttpStatus.notFound
      ..write('Not found');
    await response.close();
  }

  Future<void> broadcast(Uint8List bytes) async {
    final roomId = _roomId;
    if (roomId == null) {
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final durationMs = ((bytes.length / 2) / _sampleRate * 1000).round();
    final chunk = StreamAudioChunk(
      roomId: roomId,
      sequence: now,
      captureTimestampMs: now,
      hostTimestampMs: now,
      sampleRate: _sampleRate,
      channelCount: _channelCount,
      format: _format,
      durationMs: durationMs,
      payloadBase64: base64Encode(bytes),
      streamStartedAtMs: _streamStartedAtMs,
    );

    await broadcastChunk(chunk);
  }

  Future<void> broadcastChunk(StreamAudioChunk chunk) async {
    if (_listeners.isEmpty) {
      return;
    }

    _sampleRate = chunk.sampleRate;
    _channelCount = chunk.channelCount;
    _format = chunk.format;
    _streamStartedAtMs ??= chunk.streamStartedAtMs;

    final payload = jsonEncode(chunk.toJson());
    await _broadcastPayload(payload);

    _syncTick += 1;
    if (_syncTick >= 20) {
      _syncTick = 0;
      await _broadcastPayload(
        jsonEncode({
          'type': 'stream.sync',
          'roomId': _roomId,
          'sequence': chunk.sequence,
          'chunkDurationMs': chunk.durationMs,
          'targetBufferMs': _targetBufferMs,
          'serverTime': DateTime.now().millisecondsSinceEpoch,
          'streamStartedAt': _streamStartedAtMs,
        }),
      );
    }
  }

  Future<void> _broadcastPayload(String payload) async {
    if (_listeners.isEmpty) {
      return;
    }

    final closed = <WebSocket>[];
    for (final socket in _listeners) {
      try {
        socket.add(payload);
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
    if (_listeners.isNotEmpty) {
      await _broadcastPayload(
        jsonEncode({
          'type': 'stream.host_stopped',
          'roomId': _roomId,
          'message': 'Host stopped broadcast.',
        }),
      );
    }

    final sockets = List<WebSocket>.from(_listeners);
    _listeners.clear();
    for (final socket in sockets) {
      await socket.close();
    }

    final server = _server;
    _server = null;
    _roomId = null;
    _hostAddress = null;
    _port = null;
    _roomPinProtected = false;
    _roomPin = null;
    _streamStartedAtMs = null;
    _sampleRate = 48000;
    _channelCount = 1;
    _format = 'pcm16';
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
    final event = jsonEncode({
      'type': 'stream.listener_count',
      'count': _listeners.length,
      'roomId': _roomId,
    });
    for (final socket in _listeners) {
      try {
        socket.add(event);
      } catch (_) {
        // Ignore per-socket failures; cleanup happens on next broadcast.
      }
    }
  }

  void _sendMeta(WebSocket socket) {
    socket.add(
      jsonEncode({
        'type': 'stream.meta',
        'roomId': _roomId,
        'sampleRate': _sampleRate,
        'channelCount': _channelCount,
        'format': _format,
        'targetBufferMs': _targetBufferMs,
        'streamStartedAt': _streamStartedAtMs,
        'serverTime': DateTime.now().millisecondsSinceEpoch,
        'audioPath': '/stream/audio',
      }),
    );
  }

  void _handleListenerMessage(WebSocket socket, dynamic message) {
    if (message is! String) {
      return;
    }

    Map<String, dynamic> payload;
    try {
      final decoded = jsonDecode(message);
      if (decoded is! Map<String, dynamic>) {
        return;
      }
      payload = decoded;
    } catch (_) {
      return;
    }

    final type = payload['type']?.toString();
    if (type == 'stream.ping') {
      socket.add(
        jsonEncode({
          'type': 'stream.pong',
          'serverTime': DateTime.now().millisecondsSinceEpoch,
          'clientTime': payload['clientTime'],
        }),
      );
      return;
    }

    if (type == 'listener.ready' ||
        type == 'listener.buffering' ||
        type == 'listener.playing') {
      // Reserved for status analytics.
      return;
    }
  }

  void _setBaseHeaders(HttpResponse response) {
    response.headers.set('Access-Control-Allow-Origin', '*');
    response.headers.set('Access-Control-Allow-Headers', '*');
    response.headers.set('Access-Control-Allow-Methods', 'GET,OPTIONS');
    response.headers.set('Cache-Control', 'no-store');
    response.headers.set('X-Content-Type-Options', 'nosniff');
  }

  String _browserJoinHtml(HttpRequest request) {
    final currentRoom =
        (request.uri.queryParameters['room'] ??
                request.uri.queryParameters['roomId'] ??
                _roomId ??
                '')
            .trim();
    final initialRoom = htmlEscape.convert(currentRoom);
    final initialPin = htmlEscape.convert(
      request.uri.queryParameters['pin'] ?? '',
    );
    final pinRequired = _roomPinProtected ? 'true' : 'false';

    return '''
<!doctype html>
<html>
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width,initial-scale=1" />
  <title>SyncWave Listener</title>
  <style>
    :root { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; }
    body {
      margin: 0;
      min-height: 100vh;
      background: linear-gradient(180deg, #f5f7ff 0%, #ecfdf5 100%);
      color: #0f172a;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 16px;
    }
    .card {
      width: 100%;
      max-width: 560px;
      border-radius: 18px;
      border: 1px solid #dbe3f0;
      background: rgba(255,255,255,.95);
      box-shadow: 0 10px 30px rgba(15,23,42,.09);
      padding: 18px;
    }
    h1 { margin: 0 0 4px; font-size: 22px; }
    .muted { color: #475569; font-size: 14px; }
    .status {
      margin-top: 12px;
      display: inline-flex;
      gap: 8px;
      align-items: center;
      border-radius: 999px;
      border: 1px solid #cbd5e1;
      padding: 7px 11px;
      font-size: 13px;
      font-weight: 700;
      background: #f8fafc;
    }
    .dot { width: 8px; height: 8px; border-radius: 50%; background: #94a3b8; }
    .status.playing .dot { background: #16a34a; }
    .status.buffering .dot, .status.rebuffering .dot { background: #f59e0b; }
    .status.error .dot, .status.disconnected .dot { background: #dc2626; }
    .grid { margin-top: 14px; display: grid; gap: 10px; }
    label { font-size: 13px; color: #334155; font-weight: 600; }
    input[type="text"], input[type="password"] {
      width: 100%;
      box-sizing: border-box;
      border: 1px solid #cbd5e1;
      border-radius: 10px;
      padding: 10px 11px;
      font-size: 15px;
    }
    .row { display: flex; gap: 10px; }
    .row > * { flex: 1; }
    .btn {
      border: 0;
      border-radius: 12px;
      cursor: pointer;
      font-size: 15px;
      font-weight: 700;
      padding: 11px 14px;
      color: white;
      background: #0f766e;
    }
    .btn.secondary { background: #334155; }
    .btn:disabled { opacity: .6; cursor: not-allowed; }
    .controls { margin-top: 14px; display: grid; gap: 10px; }
    .small-row { display: flex; justify-content: space-between; font-size: 13px; color: #475569; }
    input[type="range"] { width: 100%; accent-color: #0f766e; }
    .error { min-height: 20px; color: #dc2626; font-size: 13px; font-weight: 600; }
    .footer {
      margin-top: 10px;
      font-size: 12px;
      color: #64748b;
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 8px;
    }
    .footer a { color: inherit; text-decoration: none; }
    .heart { color: #e11d48; }
  </style>
</head>
<body>
  <div class="card">
    <h1>SyncWave</h1>
    <div class="muted">Local listener over Wi-Fi or hotspot</div>

    <div id="statusBadge" class="status disconnected">
      <span class="dot"></span>
      <span id="statusText">Disconnected</span>
    </div>

    <div class="grid">
      <div>
        <label for="roomInput">Room code</label>
        <input id="roomInput" type="text" placeholder="LAN-ABCDE or WAN-ABCDE" value="$initialRoom" />
      </div>
      <div>
        <label for="pinInput">Room PIN (if required)</label>
        <input id="pinInput" type="password" inputmode="numeric" maxlength="6" placeholder="6 digits" value="$initialPin" />
      </div>
      <div class="row">
        <button id="connectBtn" class="btn">Connect</button>
        <button id="toggleBtn" class="btn secondary" disabled>Play</button>
      </div>
    </div>

    <div class="controls">
      <div class="small-row"><span>Volume</span><span id="volumeValue">80%</span></div>
      <input id="volumeSlider" type="range" min="0" max="100" value="80" />
      <div class="small-row"><span>Buffer</span><span id="bufferValue">0 ms</span></div>
      <div class="small-row"><span>Latency (RTT)</span><span id="latencyValue">-</span></div>
      <div id="errorText" class="error" role="alert"></div>
    </div>
    <div class="footer">
      <div>Made with <span class="heart">♥</span> by <a href="https://rjrajujha.github.io" target="_blank" rel="noreferrer">R. Jha</a></div>
      <a href="https://github.com/rjrajujha/syncwave" target="_blank" rel="noreferrer" aria-label="GitHub">🐙</a>
    </div>
  </div>

  <script>
    const roomInput = document.getElementById('roomInput');
    const pinInput = document.getElementById('pinInput');
    const connectBtn = document.getElementById('connectBtn');
    const toggleBtn = document.getElementById('toggleBtn');
    const volumeSlider = document.getElementById('volumeSlider');
    const volumeValue = document.getElementById('volumeValue');
    const bufferValue = document.getElementById('bufferValue');
    const latencyValue = document.getElementById('latencyValue');
    const statusBadge = document.getElementById('statusBadge');
    const statusText = document.getElementById('statusText');
    const errorText = document.getElementById('errorText');
    const pinRequired = $pinRequired;

    let ws = null;
    let audioCtx = null;
    let gainNode = null;
    let pingTimer = null;
    let scheduleTimer = null;

    let started = false;
    let nextPlayTime = 0;
    let targetBufferMs = 260;
    let maxBufferMs = 650;
    let queue = [];
    let queuedMs = 0;
    let lastSequence = null;

    function setStatus(label, cssClass) {
      statusText.textContent = label;
      statusBadge.className = 'status ' + cssClass;
    }

    function setError(message) {
      errorText.textContent = message || '';
    }

    function updateBufferLabel() {
      const aheadMs = audioCtx ? Math.max(0, Math.round((nextPlayTime - audioCtx.currentTime) * 1000)) : 0;
      const total = Math.max(0, aheadMs + Math.round(queuedMs));
      bufferValue.textContent = total + ' ms';
    }

    function validateRoomCode(room) {
      return (/^(LAN|WAN)-[A-Z0-9]{5}/.test(room) && room.length === 9) ||
        (/^SW-[A-Z0-9]{4}-[A-Z0-9]{2}/.test(room) && room.length === 10);
    }

    function ensureAudio() {
      if (!audioCtx) {
        audioCtx = new (window.AudioContext || window.webkitAudioContext)({ sampleRate: 48000 });
      }
      if (!gainNode) {
        gainNode = audioCtx.createGain();
        gainNode.gain.value = 0.8;
        gainNode.connect(audioCtx.destination);
      }
      if (!scheduleTimer) {
        scheduleTimer = setInterval(schedulePlayback, 20);
      }
    }

    function toFloat32FromPcm16(base64Payload) {
      const raw = atob(base64Payload);
      const buffer = new Float32Array(raw.length / 2);
      for (let i = 0; i < raw.length; i += 2) {
        const low = raw.charCodeAt(i);
        const high = raw.charCodeAt(i + 1);
        let value = (high << 8) | low;
        if (value >= 0x8000) value = value - 0x10000;
        buffer[i / 2] = value / 32768;
      }
      return buffer;
    }

    function enqueueChunk(event) {
      const seq = Number(event.sequence || 0);
      if (lastSequence !== null && seq <= lastSequence) {
        return;
      }
      if (lastSequence !== null && seq > lastSequence + 1) {
        setError('Minor network jitter detected. Rebuffering smoothly...');
        started = false;
        if (audioCtx) {
          nextPlayTime = Math.max(audioCtx.currentTime + 0.08, nextPlayTime);
        }
      } else if (errorText.textContent.startsWith('Minor network jitter')) {
        setError('');
      }
      lastSequence = seq;

      const sampleRate = Number(event.sampleRate || 48000);
      const channelCount = Number(event.channelCount || 1);
      const durationMs = Number(event.durationMs || 0);
      if (!event.payload) {
        return;
      }

      const pcm = toFloat32FromPcm16(event.payload);
      const frameCount = channelCount > 0 ? Math.floor(pcm.length / channelCount) : pcm.length;
      const audioBuffer = audioCtx.createBuffer(channelCount, frameCount, sampleRate);
      if (channelCount === 1) {
        audioBuffer.copyToChannel(pcm, 0);
      } else {
        for (let channel = 0; channel < channelCount; channel++) {
          const channelData = audioBuffer.getChannelData(channel);
          for (let i = 0; i < frameCount; i++) {
            channelData[i] = pcm[i * channelCount + channel] || 0;
          }
        }
      }

      const chunkDurationMs = durationMs > 0 ? durationMs : Math.round((frameCount / sampleRate) * 1000);
      queue.push({ buffer: audioBuffer, durationMs: chunkDurationMs });
      queuedMs += chunkDurationMs;
    }

    function schedulePlayback() {
      if (!audioCtx || !gainNode || queue.length === 0) {
        updateBufferLabel();
        return;
      }

      if (!started) {
        if (queuedMs < targetBufferMs) {
          setStatus('Buffering', 'buffering');
          sendClientEvent('listener.buffering', { queuedMs: Math.round(queuedMs) });
          updateBufferLabel();
          return;
        }
        started = true;
        nextPlayTime = Math.max(audioCtx.currentTime + 0.06, nextPlayTime);
        setStatus('Playing', 'playing');
        sendClientEvent('listener.playing', { queuedMs: Math.round(queuedMs) });
      }

      while (queue.length > 0) {
        const aheadMs = (nextPlayTime - audioCtx.currentTime) * 1000;
        if (aheadMs < -20) {
          started = false;
          setStatus('Rebuffering', 'rebuffering');
          sendClientEvent('listener.buffering', { queuedMs: Math.round(queuedMs) });
          break;
        }

        if (aheadMs > maxBufferMs) {
          nextPlayTime -= Math.min((aheadMs - maxBufferMs) / 1000, 0.04);
        }

        const item = queue.shift();
        if (!item) break;
        queuedMs = Math.max(0, queuedMs - item.durationMs);

        const source = audioCtx.createBufferSource();
        source.buffer = item.buffer;
        source.connect(gainNode);

        const scheduleAt = Math.max(nextPlayTime, audioCtx.currentTime + 0.03);
        source.start(scheduleAt);
        nextPlayTime = scheduleAt + (item.durationMs / 1000);
      }

      updateBufferLabel();
    }

    function sendClientEvent(type, payload = {}) {
      if (!ws || ws.readyState !== WebSocket.OPEN) {
        return;
      }
      ws.send(JSON.stringify({ type, payload }));
    }

    function startPingLoop() {
      stopPingLoop();
      pingTimer = setInterval(() => {
        sendClientEvent('stream.ping', { clientTime: Date.now() });
      }, 4000);
    }

    function stopPingLoop() {
      if (pingTimer) {
        clearInterval(pingTimer);
        pingTimer = null;
      }
    }

    function connect() {
      const roomCode = roomInput.value.trim().toUpperCase();
      const pin = pinInput.value.trim();

      if (!roomCode) {
        setError('Enter room code to continue.');
        return;
      }
      if (!validateRoomCode(roomCode)) {
        setError('Room code must match LAN-XXXXX or WAN-XXXXX.');
        return;
      }
      if (pin && !(/^[0-9]{6}/.test(pin) && pin.length === 6)) {
        setError('PIN must be exactly 6 digits.');
        return;
      }
      if (pinRequired && !pin) {
        setError('This room requires a 6-digit PIN.');
        return;
      }

      ensureAudio();
      queue = [];
      queuedMs = 0;
      started = false;
      nextPlayTime = audioCtx.currentTime + 0.06;
      lastSequence = null;
      setError('');

      if (ws) {
        ws.close();
      }

      const proto = location.protocol === 'https:' ? 'wss' : 'ws';
      const params = new URLSearchParams({ room: roomCode });
      if (pin) {
        params.set('pin', pin);
      }

      const wsUrl = proto + '://' + location.host + '/stream/audio?' + params.toString();
      ws = new WebSocket(wsUrl);

      setStatus('Connecting', 'connecting');
      connectBtn.disabled = true;
      toggleBtn.disabled = false;

      ws.onopen = async () => {
        setStatus('Buffering', 'buffering');
        sendClientEvent('listener.ready', { roomId: roomCode });
        sendClientEvent('stream.ping', { clientTime: Date.now() });
        startPingLoop();
        if (audioCtx.state !== 'running') {
          await audioCtx.resume();
        }
      };

      ws.onmessage = (event) => {
        if (typeof event.data !== 'string') {
          return;
        }

        let decoded;
        try {
          decoded = JSON.parse(event.data);
        } catch (_) {
          return;
        }

        switch (decoded.type) {
          case 'stream.meta':
            targetBufferMs = Number(decoded.targetBufferMs || 260);
            updateBufferLabel();
            break;
          case 'stream.audio':
            enqueueChunk(decoded);
            schedulePlayback();
            break;
          case 'stream.sync':
            if (decoded.targetBufferMs) {
              targetBufferMs = Number(decoded.targetBufferMs);
            }
            break;
          case 'stream.pong': {
            const now = Date.now();
            const sent = Number(decoded.clientTime || 0);
            if (sent > 0) {
              const rtt = Math.max(0, now - sent);
              latencyValue.textContent = rtt + ' ms';
            }
            break;
          }
          case 'error':
            setStatus('Error', 'error');
            setError(decoded.message || 'Stream error occurred.');
            break;
        }
      };

      ws.onerror = () => {
        setStatus('Error', 'error');
        setError('Could not connect to stream.');
      };

      ws.onclose = () => {
        stopPingLoop();
        connectBtn.disabled = false;
        setStatus('Disconnected', 'disconnected');
        if (started) {
          setError('Stream disconnected. Reconnect to continue.');
        }
        started = false;
      };
    }

    async function togglePlayback() {
      ensureAudio();
      if (!audioCtx) return;
      if (audioCtx.state === 'running') {
        await audioCtx.suspend();
        toggleBtn.textContent = 'Play';
        if (ws && ws.readyState === WebSocket.OPEN) {
          setStatus('Paused', 'disconnected');
        }
      } else {
        await audioCtx.resume();
        toggleBtn.textContent = 'Pause';
        if (ws && ws.readyState === WebSocket.OPEN) {
          setStatus(started ? 'Playing' : 'Buffering', started ? 'playing' : 'buffering');
        }
      }
    }

    connectBtn.addEventListener('click', connect);
    toggleBtn.addEventListener('click', async () => {
      try {
        await togglePlayback();
      } catch (_) {
        setStatus('Error', 'error');
        setError('Playback action failed on this browser.');
      }
    });

    volumeSlider.addEventListener('input', () => {
      const value = Number(volumeSlider.value || 0);
      volumeValue.textContent = value + '%';
      if (gainNode) {
        gainNode.gain.value = value / 100;
      }
    });

    if (roomInput.value.trim()) {
      connect();
    }

    window.addEventListener('beforeunload', () => {
      stopPingLoop();
      if (scheduleTimer) {
        clearInterval(scheduleTimer);
      }
      if (ws) {
        ws.close();
      }
      if (audioCtx) {
        audioCtx.close();
      }
    });
  </script>
</body>
</html>
''';
  }
}
