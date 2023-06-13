import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppConfig {
  const AppConfig({
    required this.appName,
    required this.environment,
    required this.apiBaseUrl,
    required this.signalingServerUrl,
  });

  factory AppConfig.fromEnvironment() {
    return const AppConfig(
      appName: 'SyncWave',
      environment: String.fromEnvironment(
        'APP_ENV',
        defaultValue: 'development',
      ),
      apiBaseUrl: String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:8000',
      ),
      signalingServerUrl: String.fromEnvironment(
        'SIGNALING_SERVER_URL',
        defaultValue: '',
      ),
    );
  }

  final String appName;
  final String environment;
  final String apiBaseUrl;
  final String signalingServerUrl;
}

final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
);
