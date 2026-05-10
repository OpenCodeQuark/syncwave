import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

class AudioCaptureChunk {
  const AudioCaptureChunk({
    required this.data,
    required this.base64Payload,
    required this.sampleRate,
    required this.channelCount,
    required this.format,
    required this.sequence,
    required this.captureTimestampMs,
    required this.hostTimestampMs,
    required this.durationMs,
    this.streamStartedAtMs,
  });

  final Uint8List data;
  final String base64Payload;
  final int sampleRate;
  final int channelCount;
  final String format;
  final int sequence;
  final int captureTimestampMs;
  final int hostTimestampMs;
  final int durationMs;
  final int? streamStartedAtMs;
}

class AndroidAudioCaptureBridge {
  static const _methodChannel = MethodChannel(
    'io.github.opencodequark.syncwave/audio_capture',
  );
  static const _eventChannel = EventChannel(
    'io.github.opencodequark.syncwave/audio_capture_events',
  );

  Stream<Map<String, dynamic>>? _events;

  Future<bool> isSupported() async {
    final result = await _methodChannel.invokeMethod<bool>('isSupported');
    return result ?? false;
  }

  Future<bool> requestCapturePermission() async {
    final result = await _methodChannel.invokeMethod<bool>(
      'requestCapturePermission',
    );
    return result ?? false;
  }

  Future<void> startCapture({
    required bool useSystemAudio,
    required bool useMicrophone,
  }) async {
    await _methodChannel.invokeMethod('startCapture', {
      'useSystemAudio': useSystemAudio,
      'useMicrophone': useMicrophone,
    });
  }

  Future<void> stopCapture() async {
    await _methodChannel.invokeMethod('stopCapture');
  }

  Stream<Map<String, dynamic>> rawEvents() {
    _events ??= _eventChannel
        .receiveBroadcastStream()
        .map<Map<String, dynamic>>((dynamic event) {
          if (event is Map) {
            return Map<String, dynamic>.from(event);
          }
          return const <String, dynamic>{};
        })
        .asBroadcastStream();

    return _events!;
  }

  Stream<AudioCaptureChunk> audioChunks() {
    return rawEvents().where((event) => event['type'] == 'audio_chunk').map((
      event,
    ) {
      final rawData = event['data'];
      final decoded = rawData is Uint8List
          ? rawData
          : base64Decode(rawData?.toString() ?? '');
      final encoded = rawData is String ? rawData : base64Encode(decoded);
      final sampleRate = _toInt(event['sampleRate']) ?? 48000;
      final channelCount = _toInt(event['channelCount']) ?? 1;
      final format = event['format']?.toString() ?? 'pcm16';
      final sequence = _toInt(event['sequence']) ?? 0;
      final captureTimestampMs = _toInt(event['captureTimestamp']) ?? 0;
      final hostTimestampMs =
          _toInt(event['hostTimestamp']) ?? captureTimestampMs;
      final durationMs = _toInt(event['durationMs']) ?? 0;
      final streamStartedAtMs = _toInt(event['streamStartedAt']);
      return AudioCaptureChunk(
        data: decoded,
        base64Payload: encoded,
        sampleRate: sampleRate,
        channelCount: channelCount,
        format: format,
        sequence: sequence,
        captureTimestampMs: captureTimestampMs,
        hostTimestampMs: hostTimestampMs,
        durationMs: durationMs,
        streamStartedAtMs: streamStartedAtMs,
      );
    });
  }

  int? _toInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }
}
