import 'package:flutter_test/flutter_test.dart';
import 'package:syncwave/core/config/app_config.dart';

void main() {
  test('app version default is 1.0.0', () {
    final config = AppConfig.fromEnvironment();
    expect(config.appVersion, '1.0.0');
  });
}
