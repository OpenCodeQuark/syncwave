import 'package:shared_preferences/shared_preferences.dart';

import '../models/streaming_settings.dart';
import 'server_connection_pin_repository.dart';
import 'server_connection_pin_validation_service.dart';
import 'server_url_service.dart';

class StreamingSettingsRepository {
  StreamingSettingsRepository({
    required ServerUrlService serverUrlService,
    required ServerConnectionPinRepository serverConnectionPinRepository,
    required ServerConnectionPinValidationService
    serverConnectionPinValidationService,
  }) : _serverUrlService = serverUrlService,
       _serverConnectionPinRepository = serverConnectionPinRepository,
       _serverConnectionPinValidationService =
           serverConnectionPinValidationService;

  final ServerUrlService _serverUrlService;
  final ServerConnectionPinRepository _serverConnectionPinRepository;
  final ServerConnectionPinValidationService
  _serverConnectionPinValidationService;

  static const _internetEnabledKey = 'settings.internet_streaming_enabled';
  static const _signalingServerUrlKey = 'settings.signaling_server_url';

  Future<StreamingSettings> load() async {
    final preferences = await SharedPreferences.getInstance();

    final internetEnabled = preferences.getBool(_internetEnabledKey) ?? false;
    final rawUrl = preferences.getString(_signalingServerUrlKey)?.trim();

    String? normalized;
    if (rawUrl != null && rawUrl.isNotEmpty) {
      if (_serverUrlService.isValidServerUrl(rawUrl)) {
        normalized = _serverUrlService.normalize(rawUrl);
      }
    }
    final serverConnectionPin = await _serverConnectionPinRepository.readPin();

    return StreamingSettings(
      internetStreamingEnabled: internetEnabled,
      signalingServerUrl: normalized,
      serverConnectionPinConfigured: serverConnectionPin != null,
    );
  }

  Future<void> save(
    StreamingSettings settings, {
    String? serverConnectionPin,
    bool clearServerConnectionPin = false,
  }) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setBool(
      _internetEnabledKey,
      settings.internetStreamingEnabled,
    );

    final urlValue = settings.signalingServerUrl?.trim();
    if (urlValue == null || urlValue.isEmpty) {
      await preferences.remove(_signalingServerUrlKey);
    } else {
      final normalized = _serverUrlService.normalize(urlValue);
      await preferences.setString(_signalingServerUrlKey, normalized);
    }

    if (clearServerConnectionPin) {
      await _serverConnectionPinRepository.clearPin();
      return;
    }

    if (serverConnectionPin != null) {
      final normalizedPin = _serverConnectionPinValidationService
          .normalizeAndValidateOptional(serverConnectionPin);
      if (normalizedPin == null) {
        await _serverConnectionPinRepository.clearPin();
      } else {
        await _serverConnectionPinRepository.savePin(normalizedPin);
      }
    }
  }

  String normalizeSignalingServerUrl(String value) {
    return _serverUrlService.normalize(value);
  }

  bool isValidSignalingServerUrl(String value) {
    return _serverUrlService.isValidServerUrl(value);
  }

  String deriveStatusUrl(String normalizedWebSocketUrl) {
    return _serverUrlService.deriveStatusUrl(normalizedWebSocketUrl);
  }

  Future<String?> readServerConnectionPin() {
    return _serverConnectionPinRepository.readPin();
  }

  bool isValidServerConnectionPin(String pin) {
    return _serverConnectionPinValidationService.isValid(pin);
  }
}
