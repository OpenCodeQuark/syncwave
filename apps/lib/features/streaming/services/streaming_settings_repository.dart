import 'package:shared_preferences/shared_preferences.dart';

import '../models/streaming_settings.dart';
import 'server_url_service.dart';

class StreamingSettingsRepository {
  StreamingSettingsRepository({required ServerUrlService serverUrlService})
    : _serverUrlService = serverUrlService;

  final ServerUrlService _serverUrlService;

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

    return StreamingSettings(
      internetStreamingEnabled: internetEnabled,
      signalingServerUrl: normalized,
    );
  }

  Future<void> save(StreamingSettings settings) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setBool(
      _internetEnabledKey,
      settings.internetStreamingEnabled,
    );

    final urlValue = settings.signalingServerUrl?.trim();
    if (urlValue == null || urlValue.isEmpty) {
      await preferences.remove(_signalingServerUrlKey);
      return;
    }

    final normalized = _serverUrlService.normalize(urlValue);
    await preferences.setString(_signalingServerUrlKey, normalized);
  }

  String normalizeSignalingServerUrl(String value) {
    return _serverUrlService.normalize(value);
  }

  bool isValidSignalingServerUrl(String value) {
    return _serverUrlService.isValidServerUrl(value);
  }
}
