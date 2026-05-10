import 'package:flutter_test/flutter_test.dart';
import 'package:syncwave/core/config/app_config.dart';

void main() {
  test('app version and build defaults are centralized', () {
    final config = AppConfig.fromEnvironment();
    expect(config.appVersion, AppConfig.defaultAppVersion);
    expect(config.appBuildNumber, AppConfig.defaultBuildNumber);
    expect(config.displayVersion, '1.1.4+4');
  });
}
