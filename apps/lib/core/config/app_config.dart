import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppConfig {
  const AppConfig({
    required this.appName,
    required this.appVersion,
    required this.appBuildNumber,
    required this.protocolVersion,
    required this.environment,
    required this.apiBaseUrl,
    required this.signalingServerUrl,
  });

  static const defaultAppVersion = '1.1.4';
  static const defaultBuildNumber = '4';

  factory AppConfig.fromEnvironment() {
    return const AppConfig(
      appName: 'SyncWave',
      appVersion: String.fromEnvironment(
        'APP_VERSION',
        defaultValue: defaultAppVersion,
      ),
      appBuildNumber: String.fromEnvironment(
        'APP_BUILD_NUMBER',
        defaultValue: defaultBuildNumber,
      ),
      protocolVersion: String.fromEnvironment(
        'APP_PROTOCOL_VERSION',
        defaultValue: '1',
      ),
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
  final String appVersion;
  final String appBuildNumber;
  final String protocolVersion;
  final String environment;
  final String apiBaseUrl;
  final String signalingServerUrl;

  String get displayVersion => '$appVersion+$appBuildNumber';
}

final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
);
