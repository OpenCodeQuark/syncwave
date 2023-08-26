import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

class AudioCaptureChunk {
  const AudioCaptureChunk({
    required this.data,
    required this.sampleRate,
    required this.channelCount,
    required this.format,
  });

  final Uint8List data;
  final int sampleRate;
  final int channelCount;
  final String format;
}

class AndroidAudioCaptureBridge {
  static const _methodChannel = MethodChannel(
    'dev.rajujha.syncwave/audio_capture',
  );
  static const _eventChannel = EventChannel(
    'dev.rajujha.syncwave/audio_capture_events',
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
      final encoded = event['data']?.toString() ?? '';
      final decoded = base64Decode(encoded);
      final sampleRate = (event['sampleRate'] as int?) ?? 48000;
      final channelCount = (event['channelCount'] as int?) ?? 1;
      final format = event['format']?.toString() ?? 'pcm16';
      return AudioCaptureChunk(
        data: decoded,
        sampleRate: sampleRate,
        channelCount: channelCount,
        format: format,
      );
    });
  }
}
