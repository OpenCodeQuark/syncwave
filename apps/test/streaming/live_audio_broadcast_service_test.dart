import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:syncwave/core/audio/android_audio_capture_bridge.dart';
import 'package:syncwave/core/errors/app_exception.dart';
import 'package:syncwave/features/streaming/models/hosted_session.dart';
import 'package:syncwave/features/streaming/models/live_broadcast_status.dart';
import 'package:syncwave/features/streaming/models/streaming_mode.dart';
import 'package:syncwave/features/streaming/services/internet_audio_relay_service.dart';
import 'package:syncwave/features/streaming/services/live_audio_broadcast_service.dart';
import 'package:syncwave/features/streaming/services/local_audio_broadcast_server.dart';

class _FakeAudioCaptureBridge extends AndroidAudioCaptureBridge {
  bool supported = true;
  bool permissionGranted = true;
  bool startCalled = false;

  @override
  Future<bool> isSupported() async => supported;

  @override
  Future<bool> requestCapturePermission() async => permissionGranted;

  @override
  Future<void> startCapture({
    required bool useSystemAudio,
    required bool useMicrophone,
  }) async {
    startCalled = true;
  }

  @override
  Future<void> stopCapture() async {}

  @override
  Stream<Map<String, dynamic>> rawEvents() {
    return const Stream<Map<String, dynamic>>.empty();
  }

  @override
  Stream<AudioCaptureChunk> audioChunks() {
    return const Stream<AudioCaptureChunk>.empty();
  }
}

class _FakeLocalAudioBroadcastServer extends LocalAudioBroadcastServer {
  bool startCalled = false;
  bool stopCalled = false;

  @override
  bool get isRunning => startCalled && !stopCalled;

  @override
  Future<void> broadcast(Uint8List bytes) async {}

  @override
  Future<void> start({
    required String host,
    required int port,
    required String roomId,
    bool roomPinProtected = false,
    String? roomPin,
  }) async {
    startCalled = true;
    stopCalled = false;
  }

  @override
  Future<void> stop() async {
    stopCalled = true;
  }
}

class _FakeInternetAudioRelayService extends InternetAudioRelayService {
  @override
  Future<bool> connect({
    required String websocketUrl,
    required String roomId,
    required String appName,
    required String appVersion,
    required String protocolVersion,
    String? serverConnectionPin,
  }) async {
    return true;
  }

  @override
  Future<void> disconnect() async {}
}

void main() {
  HostedSession testSession({
    String? hostAddress = '192.168.1.20',
    StreamingMode mode = StreamingMode.local,
    String roomName = 'Room',
  }) {
    return HostedSession(
      roomId: 'LAN-R12B9',
      roomName: roomName,
      mode: mode,
      hostAddress: hostAddress,
      hostPort: 9000,
      roomPinProtected: false,
    );
  }

  test('requires at least one audio source', () async {
    final service = LiveAudioBroadcastService(
      audioCaptureBridge: _FakeAudioCaptureBridge(),
      localAudioBroadcastServer: _FakeLocalAudioBroadcastServer(),
      internetAudioRelayService: _FakeInternetAudioRelayService(),
      isAndroidPlatform: () => true,
    );

    expect(
      () => service.start(
        session: testSession(),
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

  test('fails when MediaProjection permission is denied', () async {
    final bridge = _FakeAudioCaptureBridge()..permissionGranted = false;
    final service = LiveAudioBroadcastService(
      audioCaptureBridge: bridge,
      localAudioBroadcastServer: _FakeLocalAudioBroadcastServer(),
      internetAudioRelayService: _FakeInternetAudioRelayService(),
      isAndroidPlatform: () => true,
    );

    expect(
      () => service.start(
        session: testSession(),
        useSystemAudio: true,
        useMicrophone: false,
      ),
      throwsA(
        isA<AppException>().having(
          (error) => error.code,
          'code',
          'system_audio_permission_denied',
        ),
      ),
    );
  });

  test('fails when Android version does not support system audio', () async {
    final bridge = _FakeAudioCaptureBridge()..supported = false;
    final service = LiveAudioBroadcastService(
      audioCaptureBridge: bridge,
      localAudioBroadcastServer: _FakeLocalAudioBroadcastServer(),
      internetAudioRelayService: _FakeInternetAudioRelayService(),
      isAndroidPlatform: () => true,
    );

    expect(
      () => service.start(
        session: testSession(),
        useSystemAudio: true,
        useMicrophone: false,
      ),
      throwsA(
        isA<AppException>().having(
          (error) => error.code,
          'code',
          'system_audio_unsupported',
        ),
      ),
    );
  });

  test('blocks local broadcast when room has no usable host ip', () async {
    final service = LiveAudioBroadcastService(
      audioCaptureBridge: _FakeAudioCaptureBridge(),
      localAudioBroadcastServer: _FakeLocalAudioBroadcastServer(),
      internetAudioRelayService: _FakeInternetAudioRelayService(),
      isAndroidPlatform: () => true,
    );

    expect(
      () => service.start(
        session: testSession(hostAddress: null),
        useSystemAudio: true,
        useMicrophone: false,
      ),
      throwsA(
        isA<AppException>().having(
          (error) => error.code,
          'code',
          'local_network_unavailable',
        ),
      ),
    );
  });

  test('cannot start second broadcast while active', () async {
    final bridge = _FakeAudioCaptureBridge();
    final localServer = _FakeLocalAudioBroadcastServer();
    final service = LiveAudioBroadcastService(
      audioCaptureBridge: bridge,
      localAudioBroadcastServer: localServer,
      internetAudioRelayService: _FakeInternetAudioRelayService(),
      isAndroidPlatform: () => true,
    );

    await service.start(
      session: testSession(),
      useSystemAudio: true,
      useMicrophone: false,
    );

    expect(
      () => service.start(
        session: testSession(),
        useSystemAudio: true,
        useMicrophone: false,
      ),
      throwsA(
        isA<AppException>().having(
          (error) => error.code,
          'code',
          'broadcast_already_active',
        ),
      ),
    );
  });

  test('stop clears active state and rebroadcast works', () async {
    final bridge = _FakeAudioCaptureBridge();
    final localServer = _FakeLocalAudioBroadcastServer();
    final service = LiveAudioBroadcastService(
      audioCaptureBridge: bridge,
      localAudioBroadcastServer: localServer,
      internetAudioRelayService: _FakeInternetAudioRelayService(),
      isAndroidPlatform: () => true,
    );

    await service.start(
      session: testSession(roomName: 'Room A'),
      useSystemAudio: true,
      useMicrophone: false,
    );
    expect(service.status.phase, LiveBroadcastPhase.running);

    await service.stop();
    expect(localServer.stopCalled, isTrue);
    expect(service.status.phase, LiveBroadcastPhase.idle);

    await service.start(
      session: testSession(roomName: 'Room B'),
      useSystemAudio: true,
      useMicrophone: false,
    );
    expect(service.status.phase, LiveBroadcastPhase.running);
  });
}
