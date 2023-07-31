import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../streaming/models/remote_server_status.dart';
import '../../../streaming/providers/streaming_providers.dart';
import '../../../streaming/services/remote_server_status_service.dart';

class RemoteServerConnectionController extends AsyncNotifier<RemoteServerStatus> {
  late final RemoteServerStatusService _service;
  StreamSubscription<RemoteServerStatus>? _statusSubscription;

  @override
  Future<RemoteServerStatus> build() async {
    _service = ref.read(remoteServerStatusServiceProvider);
    _statusSubscription = _service.statusStream.listen((status) {
      state = AsyncData(status);
    });
    ref.onDispose(() {
      _statusSubscription?.cancel();
    });

    return _service.lastStatus;
  }

  Future<void> checkConnection({
    required String serverUrlInput,
    required String? serverConnectionPin,
    bool attemptWebSocket = true,
  }) async {
    final config = ref.read(appConfigProvider);
    state = const AsyncLoading();
    final status = await _service.checkServer(
      serverUrlInput: serverUrlInput,
      appName: config.appName,
      appVersion: config.appVersion,
      protocolVersion: config.protocolVersion,
      serverConnectionPin: serverConnectionPin,
      attemptWebSocket: attemptWebSocket,
    );
    state = AsyncData(status);
  }

  Future<void> connect({
    required String serverUrlInput,
    required String? serverConnectionPin,
  }) async {
    final config = ref.read(appConfigProvider);
    state = const AsyncLoading();
    final status = await _service.connect(
      serverUrlInput: serverUrlInput,
      appName: config.appName,
      appVersion: config.appVersion,
      protocolVersion: config.protocolVersion,
      serverConnectionPin: serverConnectionPin,
    );
    state = AsyncData(status);
  }

  Future<void> disconnect() async {
    state = const AsyncLoading();
    final status = await _service.disconnect();
    state = AsyncData(status);
  }
}

final remoteServerConnectionControllerProvider =
    AsyncNotifierProvider<RemoteServerConnectionController, RemoteServerStatus>(
      RemoteServerConnectionController.new,
    );
