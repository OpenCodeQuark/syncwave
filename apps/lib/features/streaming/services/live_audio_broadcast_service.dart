import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import '../../../core/audio/android_audio_capture_bridge.dart';
import '../../../core/config/app_config.dart';
import '../../../core/errors/app_exception.dart';
import '../models/hosted_session.dart';
import '../models/live_broadcast_status.dart';
import '../models/streaming_mode.dart';
import 'internet_audio_relay_service.dart';
import 'local_audio_broadcast_server.dart';

class LiveAudioBroadcastService {
  LiveAudioBroadcastService({
    required AndroidAudioCaptureBridge audioCaptureBridge,
    required LocalAudioBroadcastServer localAudioBroadcastServer,
    required InternetAudioRelayService internetAudioRelayService,
    bool Function()? isAndroidPlatform,
  }) : _audioCaptureBridge = audioCaptureBridge,
       _localAudioBroadcastServer = localAudioBroadcastServer,
       _internetAudioRelayService = internetAudioRelayService,
       _isAndroidPlatform = isAndroidPlatform ?? (() => Platform.isAndroid);

  final AndroidAudioCaptureBridge _audioCaptureBridge;
  final LocalAudioBroadcastServer _localAudioBroadcastServer;
  final InternetAudioRelayService _internetAudioRelayService;
  final bool Function() _isAndroidPlatform;

  final _statusController = StreamController<LiveBroadcastStatus>.broadcast();

  StreamSubscription<int>? _listenerCountSubscription;
  StreamSubscription<Map<String, dynamic>>? _captureEventSubscription;
  StreamSubscription<AudioCaptureChunk>? _chunkSubscription;
  StreamSubscription<InternetRelayPhase>? _relayPhaseSubscription;
  Timer? _networkWatchdog;

  LiveBroadcastStatus _status = const LiveBroadcastStatus.idle();
  HostedSession? _activeSession;
  String? _activeLocalHostAddress;
  bool _localTransportActive = false;
  bool _internetTransportActive = false;
  bool _systemAudioMuted = false;
  bool _microphoneMuted = true;
  bool _isStopping = false;
  int _syntheticSequence = 0;
  final Map<int, String> _silentBase64Cache = <int, String>{};

  Stream<LiveBroadcastStatus> get statusStream => _statusController.stream;
  LiveBroadcastStatus get status => _status;
  bool get isBroadcastActive =>
      _status.phase == LiveBroadcastPhase.starting ||
      _status.phase == LiveBroadcastPhase.running ||
      _status.phase == LiveBroadcastPhase.stopping;

  Future<void> start({
    required HostedSession session,
    required bool useSystemAudio,
    required bool useMicrophone,
  }) async {
    if (isBroadcastActive || _activeSession != null) {
      throw AppException(
        'A broadcast is already active. Stop the current broadcast before starting a new one.',
        code: 'broadcast_already_active',
      );
    }
    if (!useSystemAudio && !useMicrophone) {
      throw AppException(
        'Enable Audio Source or Microphone before starting broadcast.',
        code: 'audio_source_required',
      );
    }

    if (!_isAndroidPlatform()) {
      throw AppException(
        'Broadcast hosting is currently supported on Android only. iOS is listener-first in v1.0.0.',
        code: 'host_unsupported_platform',
      );
    }

    final hostAddress = session.hostAddress?.trim();
    final hasUsableLocalHost =
        hostAddress != null &&
        hostAddress.isNotEmpty &&
        hostAddress != 'localhost' &&
        hostAddress != '127.0.0.1' &&
        hostAddress != '0.0.0.0';
    final shouldStartLocalServer =
        session.mode == StreamingMode.local && hasUsableLocalHost;
    final shouldStartInternetRelay =
        session.serverUrl != null && session.serverUrl!.trim().isNotEmpty;
    final relayRoomId =
        session.wanRoomId != null && session.wanRoomId!.trim().isNotEmpty
        ? session.wanRoomId!.trim()
        : session.roomId;
    final port = session.hostPort ?? 9000;

    if (session.mode == StreamingMode.local && !shouldStartLocalServer) {
      throw AppException(
        'Connect to Wi-Fi or enable hotspot to start a local broadcast.',
        code: 'local_network_unavailable',
      );
    }

    _emit(
      _status.copyWith(
        phase: LiveBroadcastPhase.starting,
        message: 'Starting live broadcast…',
        clearErrorCode: true,
        useSystemAudio: useSystemAudio,
        useMicrophone: useMicrophone,
        systemAudioMuted: false,
        microphoneMuted: true,
        microphoneControlAvailable: false,
        updatedAt: DateTime.now(),
      ),
    );

    try {
      _activeSession = session;
      _activeLocalHostAddress = shouldStartLocalServer ? hostAddress : null;
      _localTransportActive = false;
      _internetTransportActive = false;
      _systemAudioMuted = false;
      _microphoneMuted = true;
      _syntheticSequence = 0;
      _silentBase64Cache.clear();

      if (useSystemAudio) {
        final supported = await _audioCaptureBridge.isSupported();
        if (!supported) {
          throw AppException(
            'System audio capture requires Android 10 or newer.',
            code: 'system_audio_unsupported',
          );
        }

        final granted = await _audioCaptureBridge.requestCapturePermission();
        if (!granted) {
          throw AppException(
            'Android requires this permission to capture system audio. SyncWave only captures audio for broadcast.',
            code: 'system_audio_permission_denied',
          );
        }
      }

      if (shouldStartLocalServer) {
        await _localAudioBroadcastServer.start(
          host: hostAddress,
          port: port,
          roomId: session.roomId,
          roomPinProtected: session.roomPinProtected,
          roomPin: session.pin,
        );
        _localTransportActive = true;

        await _listenerCountSubscription?.cancel();
        _listenerCountSubscription = _localAudioBroadcastServer
            .listenerCountStream
            .listen((listenerCount) {
              _emit(
                _status.copyWith(
                  listenerCount: listenerCount,
                  updatedAt: DateTime.now(),
                ),
              );
            });
      }

      if (shouldStartInternetRelay) {
        final config = AppConfig.fromEnvironment();
        final connected = await _internetAudioRelayService.connect(
          websocketUrl: session.serverUrl!.trim(),
          roomId: relayRoomId,
          appName: config.appName,
          appVersion: config.appVersion,
          protocolVersion: config.protocolVersion,
        );
        if (!connected && session.mode == StreamingMode.internet) {
          throw AppException(
            'Internet signaling is available but stream relay connection failed.',
            code: 'internet_stream_relay_failed',
          );
        }
        _internetTransportActive = connected;
      }
      _attachRelayPhaseSubscription();
      _startNetworkWatchdog();

      await _captureEventSubscription?.cancel();
      _captureEventSubscription = _audioCaptureBridge.rawEvents().listen((
        event,
      ) {
        final type = event['type']?.toString();
        if (type == 'error') {
          final message =
              event['message']?.toString() ?? 'Audio capture failed.';
          _emit(
            _status.copyWith(
              phase: LiveBroadcastPhase.error,
              message: message,
              errorCode: 'audio_capture_error',
              updatedAt: DateTime.now(),
            ),
          );
        } else if (type == 'capture_stopped' &&
            _status.phase != LiveBroadcastPhase.stopping &&
            _status.phase != LiveBroadcastPhase.idle) {
          _emit(
            _status.copyWith(
              phase: LiveBroadcastPhase.error,
              message: 'Broadcast capture stopped.',
              errorCode: 'capture_stopped',
              updatedAt: DateTime.now(),
            ),
          );
        }
      });

      await _chunkSubscription?.cancel();
      _chunkSubscription = _audioCaptureBridge.audioChunks().listen((chunk) {
        final effectiveChunk = _toEffectiveChunk(
          roomId: session.roomId,
          originalChunk: chunk,
        );

        if (_localAudioBroadcastServer.isRunning) {
          unawaited(
            _localAudioBroadcastServer.broadcastChunk(
              StreamAudioChunk(
                roomId: session.roomId,
                sequence: effectiveChunk.sequence,
                captureTimestampMs: effectiveChunk.captureTimestampMs,
                hostTimestampMs: effectiveChunk.hostTimestampMs,
                sampleRate: effectiveChunk.sampleRate,
                channelCount: effectiveChunk.channelCount,
                format: effectiveChunk.format,
                durationMs: effectiveChunk.durationMs,
                payloadBase64: effectiveChunk.payloadBase64,
                streamStartedAtMs: effectiveChunk.streamStartedAtMs,
              ),
            ),
          );
        }
        _internetAudioRelayService.sendAudioChunk(
          StreamAudioChunk(
            roomId: relayRoomId,
            sequence: effectiveChunk.sequence,
            captureTimestampMs: effectiveChunk.captureTimestampMs,
            hostTimestampMs: effectiveChunk.hostTimestampMs,
            sampleRate: effectiveChunk.sampleRate,
            channelCount: effectiveChunk.channelCount,
            format: effectiveChunk.format,
            durationMs: effectiveChunk.durationMs,
            payloadBase64: effectiveChunk.payloadBase64,
            streamStartedAtMs: effectiveChunk.streamStartedAtMs,
          ),
        );
      });

      await _audioCaptureBridge.startCapture(
        useSystemAudio: useSystemAudio,
        useMicrophone: useMicrophone,
      );

      final joinUri = shouldStartLocalServer
          ? Uri(
              scheme: 'http',
              host: hostAddress,
              port: port,
              path: '/stream/join',
              queryParameters: {'room': session.roomId},
            ).toString()
          : _internetJoinUri(session.serverUrl, session.roomId);

      _emit(
        _status.copyWith(
          phase: LiveBroadcastPhase.running,
          message: shouldStartLocalServer
              ? 'Broadcast is live on local network.'
              : 'Broadcast capture is live with internet signaling session.',
          joinUrl: joinUri,
          listenerCount: _localAudioBroadcastServer.listenerCount,
          systemAudioMuted: _systemAudioMuted,
          microphoneMuted: _microphoneMuted,
          microphoneControlAvailable: false,
          clearErrorCode: true,
          updatedAt: DateTime.now(),
        ),
      );
    } on AppException catch (error) {
      await _cleanupRuntimeResources();
      _emit(
        _status.copyWith(
          phase: LiveBroadcastPhase.error,
          message: error.message,
          errorCode: error.code,
          updatedAt: DateTime.now(),
        ),
      );
      rethrow;
    } catch (error) {
      final message = error is PlatformException
          ? (error.message ?? 'Failed to start live broadcast.')
          : 'Failed to start live broadcast.';
      await _cleanupRuntimeResources();
      _emit(
        _status.copyWith(
          phase: LiveBroadcastPhase.error,
          message: message,
          errorCode: 'broadcast_start_failed',
          updatedAt: DateTime.now(),
        ),
      );
      throw AppException(message, code: 'broadcast_start_failed');
    }
  }

  Future<void> stop() async {
    if (_isStopping) {
      return;
    }
    _isStopping = true;

    if (_status.phase == LiveBroadcastPhase.idle &&
        _activeSession == null &&
        !_localAudioBroadcastServer.isRunning &&
        !_internetAudioRelayService.isConnected) {
      _isStopping = false;
      return;
    }
    try {
      _emit(
        _status.copyWith(
          phase: LiveBroadcastPhase.stopping,
          message: 'Stopping broadcast…',
          updatedAt: DateTime.now(),
        ),
      );

      await _cleanupRuntimeResources();

      _emit(
        const LiveBroadcastStatus.idle().copyWith(
          message: 'Broadcast stopped.',
          updatedAt: DateTime.now(),
        ),
      );
    } finally {
      _isStopping = false;
    }
  }

  Future<void> dispose() async {
    await stop();
    await _statusController.close();
  }

  String? _internetJoinUri(String? serverUrl, String roomId) {
    if (serverUrl == null || serverUrl.trim().isEmpty) {
      return null;
    }

    final parsed = Uri.tryParse(serverUrl.trim());
    if (parsed == null || parsed.host.isEmpty || parsed.scheme.isEmpty) {
      return null;
    }

    final httpScheme = parsed.scheme == 'wss' ? 'https' : 'http';
    return parsed
        .replace(
          scheme: httpScheme,
          path: '/stream/join',
          queryParameters: {'room': roomId},
        )
        .toString();
  }

  void _emit(LiveBroadcastStatus next) {
    _status = next;
    if (!_statusController.isClosed) {
      _statusController.add(next);
    }
  }

  Future<void> toggleSystemAudioMute() async {
    final muted = !_systemAudioMuted;
    _systemAudioMuted = muted;
    _emit(
      _status.copyWith(
        systemAudioMuted: muted,
        message: muted
            ? 'System audio muted. Listeners will receive silence.'
            : 'System audio unmuted.',
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> toggleMicrophoneMute() async {
    throw AppException(
      'Microphone overlay controls are coming soon.',
      code: 'microphone_control_unavailable',
    );
  }

  StreamAudioChunk _toEffectiveChunk({
    required String roomId,
    required AudioCaptureChunk originalChunk,
  }) {
    if (!_systemAudioMuted || !_status.useSystemAudio) {
      return StreamAudioChunk(
        roomId: roomId,
        sequence: originalChunk.sequence,
        captureTimestampMs: originalChunk.captureTimestampMs,
        hostTimestampMs: originalChunk.hostTimestampMs,
        sampleRate: originalChunk.sampleRate,
        channelCount: originalChunk.channelCount,
        format: originalChunk.format,
        durationMs: originalChunk.durationMs,
        payloadBase64: originalChunk.base64Payload,
        streamStartedAtMs: originalChunk.streamStartedAtMs,
      );
    }

    final payloadLength = originalChunk.data.length;
    final silentBase64 = _silentBase64Cache.putIfAbsent(payloadLength, () {
      final silentBytes = Uint8List(payloadLength);
      return base64Encode(silentBytes);
    });
    _syntheticSequence += 1;

    return StreamAudioChunk(
      roomId: roomId,
      sequence: originalChunk.sequence + _syntheticSequence,
      captureTimestampMs: originalChunk.captureTimestampMs,
      hostTimestampMs: originalChunk.hostTimestampMs,
      sampleRate: originalChunk.sampleRate,
      channelCount: originalChunk.channelCount,
      format: originalChunk.format,
      durationMs: originalChunk.durationMs,
      payloadBase64: silentBase64,
      streamStartedAtMs: originalChunk.streamStartedAtMs,
    );
  }

  void _attachRelayPhaseSubscription() {
    unawaited(_relayPhaseSubscription?.cancel());
    _relayPhaseSubscription = _internetAudioRelayService.phaseStream.listen((
      phase,
    ) {
      if (_status.phase == LiveBroadcastPhase.stopping ||
          _status.phase == LiveBroadcastPhase.idle) {
        return;
      }

      if (phase == InternetRelayPhase.connected) {
        _internetTransportActive = true;
      }

      if (phase == InternetRelayPhase.disconnected ||
          phase == InternetRelayPhase.error) {
        if (!_internetTransportActive) {
          return;
        }
        _internetTransportActive = false;

        if (_localTransportActive) {
          _emit(
            _status.copyWith(
              message:
                  'Internet relay disconnected. Continuing local broadcast.',
              updatedAt: DateTime.now(),
            ),
          );
          return;
        }

        _emit(
          _status.copyWith(
            phase: LiveBroadcastPhase.error,
            message:
                'Internet relay disconnected and no local network is available.',
            errorCode: 'internet_relay_disconnected',
            updatedAt: DateTime.now(),
          ),
        );
        unawaited(stop());
      }
    });
  }

  void _startNetworkWatchdog() {
    _networkWatchdog?.cancel();
    _networkWatchdog = Timer.periodic(const Duration(seconds: 4), (_) {
      unawaited(_checkNetworkHealth());
    });
  }

  Future<void> _checkNetworkHealth() async {
    if (_status.phase != LiveBroadcastPhase.running) {
      return;
    }

    if (_localTransportActive && _activeLocalHostAddress != null) {
      final localStillAvailable = await _isLocalHostStillAvailable(
        _activeLocalHostAddress!,
      );
      if (!localStillAvailable) {
        _localTransportActive = false;
        await _localAudioBroadcastServer.stop();
        if (_internetTransportActive &&
            _internetAudioRelayService.isConnected) {
          _emit(
            _status.copyWith(
              message:
                  'Local Wi-Fi/hotspot disconnected. Continuing internet broadcast.',
              updatedAt: DateTime.now(),
            ),
          );
        } else {
          _emit(
            _status.copyWith(
              phase: LiveBroadcastPhase.error,
              message:
                  'Local network lost and internet signaling is unavailable.',
              errorCode: 'network_lost',
              updatedAt: DateTime.now(),
            ),
          );
          await stop();
          return;
        }
      }
    }

    if (_internetTransportActive && !_internetAudioRelayService.isConnected) {
      _internetTransportActive = false;
      if (_localTransportActive) {
        _emit(
          _status.copyWith(
            message:
                'Internet signaling disconnected. Continuing local stream.',
            updatedAt: DateTime.now(),
          ),
        );
      } else {
        _emit(
          _status.copyWith(
            phase: LiveBroadcastPhase.error,
            message:
                'Internet signaling disconnected and local stream is unavailable.',
            errorCode: 'network_lost',
            updatedAt: DateTime.now(),
          ),
        );
        await stop();
      }
    }
  }

  Future<bool> _isLocalHostStillAvailable(String hostAddress) async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        includeLinkLocal: false,
        type: InternetAddressType.IPv4,
      );
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (address.address == hostAddress) {
            return true;
          }
        }
      }
      return false;
    } catch (_) {
      return true;
    }
  }

  Future<void> _cleanupRuntimeResources() async {
    _networkWatchdog?.cancel();
    _networkWatchdog = null;

    await _relayPhaseSubscription?.cancel();
    _relayPhaseSubscription = null;

    await _captureEventSubscription?.cancel();
    _captureEventSubscription = null;

    await _chunkSubscription?.cancel();
    _chunkSubscription = null;

    await _listenerCountSubscription?.cancel();
    _listenerCountSubscription = null;

    try {
      await _audioCaptureBridge.stopCapture();
    } catch (_) {
      // No-op when capture service was never started.
    }
    await _localAudioBroadcastServer.stop();
    await _internetAudioRelayService.disconnect();

    _activeSession = null;
    _activeLocalHostAddress = null;
    _localTransportActive = false;
    _internetTransportActive = false;
    _systemAudioMuted = false;
    _microphoneMuted = true;
    _silentBase64Cache.clear();
    _syntheticSequence = 0;
  }
}
