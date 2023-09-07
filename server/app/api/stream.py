from html import escape
from pathlib import Path

from fastapi import APIRouter, Request
from fastapi.responses import FileResponse, HTMLResponse

router = APIRouter(tags=['stream'])
STATIC_DIR = Path(__file__).resolve().parents[1] / 'static'


@router.get('/favicon.ico', include_in_schema=False)
def favicon() -> FileResponse:
    return FileResponse(STATIC_DIR / 'favicon.ico', media_type='image/x-icon')


@router.get('/stream/join', response_class=HTMLResponse)
def browser_stream_join(request: Request) -> HTMLResponse:
    room = (request.query_params.get('room') or request.query_params.get('roomId') or '').strip()
    pin = (request.query_params.get('pin') or '').strip()

    html = f'''<!doctype html>
<html>
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width,initial-scale=1" />
  <title>SyncWave Listener</title>
  <link rel="icon" href="/favicon.ico" />
  <style>
    :root {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; }}
    body {{
      margin: 0; min-height: 100vh; display: flex; align-items: center; justify-content: center;
      padding: 16px; background: linear-gradient(180deg, #f5f7ff 0%, #ecfeff 100%); color: #0f172a;
    }}
    .card {{
      width: 100%; max-width: 560px; background: rgba(255,255,255,.95);
      border: 1px solid #dbe3f0; border-radius: 18px; box-shadow: 0 10px 30px rgba(15,23,42,.08);
      padding: 18px;
    }}
    h1 {{ margin: 0 0 4px; font-size: 22px; }}
    .muted {{ color: #475569; font-size: 14px; }}
    .status {{
      margin-top: 12px; display: inline-flex; align-items: center; gap: 8px;
      border: 1px solid #cbd5e1; border-radius: 999px; padding: 7px 11px;
      font-size: 13px; font-weight: 700;
      background: #f8fafc;
    }}
    .dot {{ width: 8px; height: 8px; border-radius: 50%; background: #94a3b8; }}
    .status.playing .dot {{ background: #16a34a; }}
    .status.buffering .dot, .status.rebuffering .dot {{ background: #f59e0b; }}
    .status.error .dot, .status.disconnected .dot {{ background: #dc2626; }}
    .grid {{ margin-top: 14px; display: grid; gap: 10px; }}
    label {{ font-size: 13px; color: #334155; font-weight: 600; }}
    input[type="text"], input[type="password"] {{
      width: 100%; box-sizing: border-box; border: 1px solid #cbd5e1; border-radius: 10px;
      padding: 10px 11px; font-size: 15px;
    }}
    .row {{ display: flex; gap: 10px; }}
    .row > * {{ flex: 1; }}
    .btn {{
      border: 0; border-radius: 12px; cursor: pointer; font-size: 15px; font-weight: 700;
      padding: 11px 14px; color: white; background: #0f766e;
    }}
    .btn.secondary {{ background: #334155; }}
    .btn:disabled {{ opacity: .6; cursor: not-allowed; }}
    .controls {{ margin-top: 14px; display: grid; gap: 10px; }}
    .small-row {{ display: flex; justify-content: space-between; font-size: 13px; color: #475569; }}
    input[type="range"] {{ width: 100%; accent-color: #0f766e; }}
    .error {{ min-height: 20px; color: #dc2626; font-size: 13px; font-weight: 600; }}
    .footer {{
      margin-top: 10px; font-size: 12px; color: #64748b;
      display: flex; align-items: center; justify-content: space-between; gap: 8px;
    }}
    .footer a {{ color: inherit; text-decoration: none; }}
    .heart {{ color: #e11d48; }}
  </style>
</head>
<body>
  <div class="card">
    <h1>SyncWave</h1>
    <div class="muted">Internet listener</div>
    <div id="statusBadge" class="status disconnected">
      <span class="dot"></span><span id="statusText">Disconnected</span>
    </div>

    <div class="grid">
      <div>
        <label for="roomInput">Room code</label>
        <input
          id="roomInput"
          type="text"
          placeholder="LAN-ABCDE or WAN-ABCDE"
          value="{escape(room)}"
        />
      </div>
      <div>
        <label for="pinInput">Room PIN (if required)</label>
        <input
          id="pinInput"
          type="password"
          inputmode="numeric"
          maxlength="6"
          placeholder="6 digits"
          value="{escape(pin)}"
        />
      </div>
      <div>
        <label for="serverPinInput">Server Connection PIN (if required)</label>
        <input
          id="serverPinInput"
          type="password"
          inputmode="numeric"
          maxlength="10"
          placeholder="8 to 10 digits"
        />
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
      <div>
        Made with <span class="heart">♥</span> by
        <a href="https://rjrajujha.github.io" target="_blank" rel="noreferrer">R. Jha</a>
      </div>
      <a
        href="https://github.com/rjrajujha/syncwave"
        target="_blank"
        rel="noreferrer"
        aria-label="GitHub"
      >🐙</a>
    </div>
  </div>

  <script>
    const roomInput = document.getElementById('roomInput');
    const pinInput = document.getElementById('pinInput');
    const serverPinInput = document.getElementById('serverPinInput');
    const connectBtn = document.getElementById('connectBtn');
    const toggleBtn = document.getElementById('toggleBtn');
    const volumeSlider = document.getElementById('volumeSlider');
    const volumeValue = document.getElementById('volumeValue');
    const bufferValue = document.getElementById('bufferValue');
    const latencyValue = document.getElementById('latencyValue');
    const statusBadge = document.getElementById('statusBadge');
    const statusText = document.getElementById('statusText');
    const errorText = document.getElementById('errorText');

    let ws = null;
    let audioCtx = null;
    let gainNode = null;
    let pingTimer = null;
    let scheduler = null;
    let peerId = null;

    let queue = [];
    let queuedMs = 0;
    let started = false;
    let nextPlayTime = 0;
    let targetBufferMs = 260;
    let maxBufferMs = 650;
    let lastSeq = null;
    let readyForRoomJoin = false;

    function setStatus(label, cssClass) {{
      statusText.textContent = label;
      statusBadge.className = 'status ' + cssClass;
    }}

    function setError(message) {{
      errorText.textContent = message || '';
    }}

    function validateRoomCode(room) {{
      const modernPattern = /^(LAN|WAN)-[A-Z0-9]{{5}}$/;
      const legacyPattern = /^SW-[A-Z0-9]{{4}}-[A-Z0-9]{{2}}$/;
      return modernPattern.test(room) || legacyPattern.test(room);
    }}

    function ensureAudio() {{
      if (!audioCtx) {{
        audioCtx = new (window.AudioContext || window.webkitAudioContext)({{ sampleRate: 48000 }});
      }}
      if (!gainNode) {{
        gainNode = audioCtx.createGain();
        gainNode.gain.value = 0.8;
        gainNode.connect(audioCtx.destination);
      }}
      if (!scheduler) {{
        scheduler = setInterval(schedulePlayback, 20);
      }}
    }}

    function updateBufferLabel() {{
      const ahead = audioCtx
        ? Math.max(0, Math.round((nextPlayTime - audioCtx.currentTime) * 1000))
        : 0;
      const total = Math.max(0, ahead + Math.round(queuedMs));
      bufferValue.textContent = total + ' ms';
    }}

    function decodePcm(base64Payload) {{
      const raw = atob(base64Payload);
      const out = new Float32Array(raw.length / 2);
      for (let i = 0; i < raw.length; i += 2) {{
        const low = raw.charCodeAt(i);
        const high = raw.charCodeAt(i + 1);
        let value = (high << 8) | low;
        if (value >= 0x8000) value -= 0x10000;
        out[i / 2] = value / 32768;
      }}
      return out;
    }}

    function enqueueChunk(payload) {{
      const seq = Number(payload.sequence || 0);
      if (lastSeq !== null && seq <= lastSeq) {{
        return;
      }}
      if (lastSeq !== null && seq > lastSeq + 1) {{
        setError('Network jitter detected. Rebuffering...');
        started = false;
        if (audioCtx) {{
          nextPlayTime = Math.max(audioCtx.currentTime + 0.08, nextPlayTime);
        }}
      }} else if (errorText.textContent.startsWith('Network jitter')) {{
        setError('');
      }}
      lastSeq = seq;

      const sampleRate = Number(payload.sampleRate || 48000);
      const channelCount = Number(payload.channelCount || 1);
      const durationMs = Number(payload.durationMs || 0);
      if (!payload.payload) {{
        return;
      }}

      const pcm = decodePcm(payload.payload);
      const frameCount = channelCount > 0 ? Math.floor(pcm.length / channelCount) : pcm.length;
      const audioBuffer = audioCtx.createBuffer(channelCount, frameCount, sampleRate);
      if (channelCount === 1) {{
        audioBuffer.copyToChannel(pcm, 0);
      }} else {{
        for (let ch = 0; ch < channelCount; ch++) {{
          const channelData = audioBuffer.getChannelData(ch);
          for (let i = 0; i < frameCount; i++) {{
            channelData[i] = pcm[i * channelCount + ch] || 0;
          }}
        }}
      }}

      const chunkDurationMs = durationMs > 0
        ? durationMs
        : Math.round((frameCount / sampleRate) * 1000);
      queue.push({{ buffer: audioBuffer, durationMs: chunkDurationMs }});
      queuedMs += chunkDurationMs;
    }}

    function schedulePlayback() {{
      if (!audioCtx || !gainNode || queue.length === 0) {{
        updateBufferLabel();
        return;
      }}

      if (!started) {{
        if (queuedMs < targetBufferMs) {{
          setStatus('Buffering', 'buffering');
          sendEvent('listener.buffering', {{ queuedMs: Math.round(queuedMs) }});
          updateBufferLabel();
          return;
        }}
        started = true;
        nextPlayTime = Math.max(audioCtx.currentTime + 0.06, nextPlayTime);
        setStatus('Playing', 'playing');
        sendEvent('listener.playing', {{ queuedMs: Math.round(queuedMs) }});
      }}

      while (queue.length > 0) {{
        const aheadMs = (nextPlayTime - audioCtx.currentTime) * 1000;
        if (aheadMs < -20) {{
          started = false;
          setStatus('Rebuffering', 'rebuffering');
          sendEvent('listener.buffering', {{ queuedMs: Math.round(queuedMs) }});
          break;
        }}
        if (aheadMs > maxBufferMs) {{
          nextPlayTime -= Math.min((aheadMs - maxBufferMs) / 1000, 0.04);
        }}

        const item = queue.shift();
        if (!item) break;
        queuedMs = Math.max(0, queuedMs - item.durationMs);

        const source = audioCtx.createBufferSource();
        source.buffer = item.buffer;
        source.connect(gainNode);

        const scheduleAt = Math.max(nextPlayTime, audioCtx.currentTime + 0.03);
        source.start(scheduleAt);
        nextPlayTime = scheduleAt + (item.durationMs / 1000);
      }}

      updateBufferLabel();
    }}

    function sendEvent(type, payload = {{}}) {{
      if (!ws || ws.readyState !== WebSocket.OPEN) {{
        return;
      }}
      ws.send(JSON.stringify({{ type, payload }}));
    }}

    function sendRoomJoin() {{
      if (!readyForRoomJoin || !ws || ws.readyState !== WebSocket.OPEN) {{
        return;
      }}
      const roomCode = roomInput.value.trim().toUpperCase();
      const pin = pinInput.value.trim();
      const serverPin = serverPinInput.value.trim();
      ws.send(JSON.stringify({{
        type: 'room.join',
        roomId: roomCode,
        payload: {{
          deviceName: 'Web Listener',
          platform: 'web',
          ...(pin ? {{ pin }} : {{}}),
        }},
      }}));
      ws.send(JSON.stringify({{
        type: 'stream.listener_join',
        roomId: roomCode,
        payload: {{ roomId: roomCode }},
      }}));
      sendEvent('listener.ready', {{ roomId: roomCode }});
    }}

    function startPingLoop() {{
      stopPingLoop();
      pingTimer = setInterval(() => {{
        sendEvent('stream.ping', {{ clientTime: Date.now() }});
      }}, 4000);
    }}

    function stopPingLoop() {{
      if (pingTimer) {{
        clearInterval(pingTimer);
        pingTimer = null;
      }}
    }}

    function connect() {{
      const roomCode = roomInput.value.trim().toUpperCase();
      const pin = pinInput.value.trim();
      const serverPin = serverPinInput.value.trim();
      if (!roomCode) {{
        setError('Enter room code to continue.');
        return;
      }}
      if (!validateRoomCode(roomCode)) {{
        setError('Room code must match LAN-XXXXX or WAN-XXXXX.');
        return;
      }}
      if (pin && !/^\\d{{6}}$/.test(pin)) {{
        setError('PIN must be exactly 6 digits.');
        return;
      }}
      if (serverPin && !/^\\d{{8,10}}$/.test(serverPin)) {{
        setError('Server Connection PIN must be 8 to 10 digits.');
        return;
      }}

      ensureAudio();
      setError('');
      queue = [];
      queuedMs = 0;
      started = false;
      nextPlayTime = audioCtx.currentTime + 0.06;
      lastSeq = null;
      readyForRoomJoin = false;

      if (ws) {{
        ws.close();
      }}

      peerId = 'web_' + Math.random().toString(36).slice(2, 10);
      const proto = location.protocol === 'https:' ? 'wss' : 'ws';
      const wsUrl = proto + '://' + location.host + '/ws?peerId=' + peerId;
      ws = new WebSocket(wsUrl);
      setStatus('Connecting', 'connecting');
      connectBtn.disabled = true;
      toggleBtn.disabled = false;

      ws.onopen = async () => {{
        if (audioCtx.state !== 'running') {{
          await audioCtx.resume();
        }}
      }};

      ws.onmessage = (event) => {{
        if (typeof event.data !== 'string') {{
          return;
        }}

        let decoded;
        try {{
          decoded = JSON.parse(event.data);
        }} catch (_) {{
          return;
        }}

        switch (decoded.type) {{
          case 'connection.ready':
            ws.send(JSON.stringify({{
              type: 'server.hello',
              payload: {{
                appName: 'SyncWave Browser Listener',
                appVersion: '1.1.0',
                protocolVersion: '1',
                clientPlatform: 'web',
                ...(serverPin ? {{ serverConnectionPin: serverPin }} : {{}}),
              }},
            }}));
            break;
          case 'server.ready':
            readyForRoomJoin = true;
            sendRoomJoin();
            setStatus('Buffering', 'buffering');
            startPingLoop();
            break;
          case 'room.joined':
            setStatus('Buffering', 'buffering');
            break;
          case 'room.join_failed':
          case 'server.auth_required':
          case 'server.auth_failed':
          case 'server.unsupported_version':
          case 'error':
            setStatus('Error', 'error');
            setError(decoded.payload?.message || 'Unable to join room.');
            break;
          case 'stream.meta':
            targetBufferMs = Number(
              decoded.payload?.targetBufferMs || decoded.targetBufferMs || 260
            );
            updateBufferLabel();
            break;
          case 'stream.audio_chunk':
            enqueueChunk(decoded.payload || {{}});
            schedulePlayback();
            break;
          case 'stream.pong': {{
            const now = Date.now();
            const sent = Number(decoded.payload?.clientTime || decoded.clientTime || 0);
            if (sent > 0) {{
              latencyValue.textContent = Math.max(0, now - sent) + ' ms';
            }}
            break;
          }}
          case 'stream.host_stopped':
            setStatus('Disconnected', 'disconnected');
            setError('Host ended the stream.');
            break;
        }}
      }};

      ws.onerror = () => {{
        setStatus('Error', 'error');
        setError('Failed to connect to stream server.');
      }};

      ws.onclose = () => {{
        connectBtn.disabled = false;
        stopPingLoop();
        started = false;
        setStatus('Disconnected', 'disconnected');
      }};
    }}

    async function togglePlayback() {{
      ensureAudio();
      if (!audioCtx) return;
      if (audioCtx.state === 'running') {{
        await audioCtx.suspend();
        toggleBtn.textContent = 'Play';
      }} else {{
        await audioCtx.resume();
        toggleBtn.textContent = 'Pause';
      }}
    }}

    connectBtn.addEventListener('click', connect);
    toggleBtn.addEventListener('click', async () => {{
      try {{
        await togglePlayback();
      }} catch (_) {{
        setStatus('Error', 'error');
        setError('Playback action failed on this browser.');
      }}
    }});

    volumeSlider.addEventListener('input', () => {{
      const value = Number(volumeSlider.value || 0);
      volumeValue.textContent = value + '%';
      if (gainNode) {{
        gainNode.gain.value = value / 100;
      }}
    }});

    if (roomInput.value.trim()) {{
      connect();
    }}

    window.addEventListener('beforeunload', () => {{
      stopPingLoop();
      if (scheduler) clearInterval(scheduler);
      if (ws) ws.close();
      if (audioCtx) audioCtx.close();
    }});
  </script>
</body>
</html>'''

    return HTMLResponse(content=html)
