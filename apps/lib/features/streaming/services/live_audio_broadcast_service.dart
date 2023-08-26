import 'dart:async';
import 'dart:io';

import '../../../core/audio/android_audio_capture_bridge.dart';
import '../../../core/errors/app_exception.dart';
import '../models/hosted_session.dart';
import '../models/live_broadcast_status.dart';
import '../models/streaming_mode.dart';
import 'local_audio_broadcast_server.dart';

class LiveAudioBroadcastService {
  LiveAudioBroadcastService({
    required AndroidAudioCaptureBridge audioCaptureBridge,
    required LocalAudioBroadcastServer localAudioBroadcastServer,
  }) : _audioCaptureBridge = audioCaptureBridge,
       _localAudioBroadcastServer = localAudioBroadcastServer;

  final AndroidAudioCaptureBridge _audioCaptureBridge;
  final LocalAudioBroadcastServer _localAudioBroadcastServer;

  final _statusController = StreamController<LiveBroadcastStatus>.broadcast();

  StreamSubscription<int>? _listenerCountSubscription;
  StreamSubscription<Map<String, dynamic>>? _captureEventSubscription;
  StreamSubscription<AudioCaptureChunk>? _chunkSubscription;

  LiveBroadcastStatus _status = const LiveBroadcastStatus.idle();

  Stream<LiveBroadcastStatus> get statusStream => _statusController.stream;
  LiveBroadcastStatus get status => _status;

  Future<void> start({
    required HostedSession session,
    required bool useSystemAudio,
    required bool useMicrophone,
  }) async {
    if (!useSystemAudio && !useMicrophone) {
      throw AppException(
        'Enable Audio Source or Microphone before starting broadcast.',
        code: 'audio_source_required',
      );
    }

    if (!Platform.isAndroid) {
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
        updatedAt: DateTime.now(),
      ),
    );

    try {
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
            'System audio capture permission is required to start broadcast.',
            code: 'system_audio_permission_denied',
          );
        }
      }

      if (shouldStartLocalServer) {
        await _localAudioBroadcastServer.start(
          host: hostAddress,
          port: port,
          roomId: session.roomId,
        );

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
        if (_localAudioBroadcastServer.isRunning) {
          unawaited(_localAudioBroadcastServer.broadcast(chunk.data));
        }
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
          clearErrorCode: true,
          updatedAt: DateTime.now(),
        ),
      );
    } on AppException catch (error) {
      await _localAudioBroadcastServer.stop();
      _emit(
        _status.copyWith(
          phase: LiveBroadcastPhase.error,
          message: error.message,
          errorCode: error.code,
          updatedAt: DateTime.now(),
        ),
      );
      rethrow;
    } catch (_) {
      await _localAudioBroadcastServer.stop();
      _emit(
        _status.copyWith(
          phase: LiveBroadcastPhase.error,
          message: 'Failed to start live broadcast.',
          errorCode: 'broadcast_start_failed',
          updatedAt: DateTime.now(),
        ),
      );
      throw AppException(
        'Failed to start live broadcast.',
        code: 'broadcast_start_failed',
      );
    }
  }

  Future<void> stop() async {
    _emit(
      _status.copyWith(
        phase: LiveBroadcastPhase.stopping,
        message: 'Stopping broadcast…',
        updatedAt: DateTime.now(),
      ),
    );

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

    _emit(
      const LiveBroadcastStatus.idle().copyWith(
        message: 'Broadcast stopped.',
        updatedAt: DateTime.now(),
      ),
    );
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
}
