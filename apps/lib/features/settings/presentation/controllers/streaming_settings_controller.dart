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
  }) async {
    final currentSettings = state.value ?? await _repository.load();
    final trimmedUrl = serverUrlInput.trim();
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
    );

    state = const AsyncLoading();
    await _repository.save(nextSettings);
    state = AsyncData(nextSettings);
  }

  bool isValidSignalingServerUrl(String url) {
    return _repository.isValidSignalingServerUrl(url);
  }
}

final streamingSettingsControllerProvider =
    AsyncNotifierProvider<StreamingSettingsController, StreamingSettings>(
      StreamingSettingsController.new,
    );
