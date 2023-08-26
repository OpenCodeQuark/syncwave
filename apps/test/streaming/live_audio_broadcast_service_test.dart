import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:syncwave/core/audio/android_audio_capture_bridge.dart';
import 'package:syncwave/core/errors/app_exception.dart';
import 'package:syncwave/features/streaming/models/hosted_session.dart';
import 'package:syncwave/features/streaming/models/streaming_mode.dart';
import 'package:syncwave/features/streaming/services/live_audio_broadcast_service.dart';
import 'package:syncwave/features/streaming/services/local_audio_broadcast_server.dart';

class _FakeAudioCaptureBridge extends AndroidAudioCaptureBridge {}

class _FakeLocalAudioBroadcastServer extends LocalAudioBroadcastServer {
  @override
  Future<void> broadcast(Uint8List bytes) async {}
}

void main() {
  test('requires at least one audio source', () async {
    final service = LiveAudioBroadcastService(
      audioCaptureBridge: _FakeAudioCaptureBridge(),
      localAudioBroadcastServer: _FakeLocalAudioBroadcastServer(),
    );

    expect(
      () => service.start(
        session: const HostedSession(
          roomId: 'SW-8FD2-KQ',
          roomName: 'Room',
          mode: StreamingMode.local,
          hostAddress: '192.168.1.20',
          hostPort: 9000,
          roomPinProtected: false,
        ),
        useSystemAudio: false,
        useMicrophone: false,
      ),
      throwsA(
        isA<AppException>().having(
          (error) => error.code,
          'code',
          'audio_source_required',
        ),
      ),
    );
  });
}
