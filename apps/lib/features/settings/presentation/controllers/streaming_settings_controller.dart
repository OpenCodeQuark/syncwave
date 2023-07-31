import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../streaming/models/streaming_settings.dart';
import '../../../streaming/providers/streaming_providers.dart';
import '../../../streaming/services/streaming_settings_repository.dart';

class StreamingSettingsController extends AsyncNotifier<StreamingSettings> {
  late final StreamingSettingsRepository _repository;

  @override
  Future<StreamingSettings> build() async {
    _repository = ref.read(streamingSettingsRepositoryProvider);
    return _repository.load();
  }

  Future<void> saveInternetStreamingConfig({
    required bool internetEnabled,
    required String serverUrlInput,
    required String serverConnectionPinInput,
  }) async {
    final currentSettings = state.value ?? await _repository.load();
    final trimmedUrl = serverUrlInput.trim();
    final trimmedServerPin = serverConnectionPinInput.trim();

    String? normalizedUrl;
    try {
      if (trimmedUrl.isNotEmpty) {
        normalizedUrl = _repository.normalizeSignalingServerUrl(trimmedUrl);
      }
    } on FormatException {
      throw AppException(
        'Enter a valid signaling server URL (ws://, wss://, http://, or https://).',
        code: 'invalid_server_url',
      );
    }

    if (trimmedServerPin.isNotEmpty &&
        !_repository.isValidServerConnectionPin(trimmedServerPin)) {
      throw AppException(
        'Server Connection PIN must be 8 to 10 digits.',
        code: 'invalid_server_connection_pin',
      );
    }

    if (internetEnabled) {
      if (normalizedUrl == null ||
          !_repository.isValidSignalingServerUrl(normalizedUrl)) {
        throw AppException(
          'Enter a valid signaling server URL (ws://, wss://, http://, or https://).',
          code: 'invalid_server_url',
        );
      }
    }

    final nextSettings = currentSettings.copyWith(
      internetStreamingEnabled: internetEnabled,
      signalingServerUrl: normalizedUrl,
      serverConnectionPinConfigured:
          trimmedServerPin.isNotEmpty ||
          currentSettings.serverConnectionPinConfigured,
    );

    state = const AsyncLoading();
    await _repository.save(
      nextSettings,
      serverConnectionPin: trimmedServerPin.isEmpty ? null : trimmedServerPin,
    );

    final reloaded = await _repository.load();
    state = AsyncData(reloaded);
  }

  bool isValidSignalingServerUrl(String url) {
    return _repository.isValidSignalingServerUrl(url);
  }

  bool isValidServerConnectionPin(String pin) {
    return _repository.isValidServerConnectionPin(pin);
  }

  String deriveStatusUrl(String normalizedWebSocketUrl) {
    return _repository.deriveStatusUrl(normalizedWebSocketUrl);
  }

  String normalizeSignalingServerUrl(String url) {
    return _repository.normalizeSignalingServerUrl(url);
  }

  Future<String?> readServerConnectionPin() {
    return _repository.readServerConnectionPin();
  }
}

final streamingSettingsControllerProvider =
    AsyncNotifierProvider<StreamingSettingsController, StreamingSettings>(
      StreamingSettingsController.new,
    );
