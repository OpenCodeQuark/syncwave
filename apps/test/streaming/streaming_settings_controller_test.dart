import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncwave/core/errors/app_exception.dart';
import 'package:syncwave/features/settings/presentation/controllers/streaming_settings_controller.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('rejects invalid server connection pin', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(streamingSettingsControllerProvider.future);

    final notifier = container.read(
      streamingSettingsControllerProvider.notifier,
    );

    expect(
      () => notifier.saveInternetStreamingConfig(
        internetEnabled: true,
        serverUrlInput: 'https://your-server.example.com',
        serverConnectionPinInput: '1234567',
      ),
      throwsA(
        isA<AppException>().having(
          (error) => error.code,
          'code',
          'invalid_server_connection_pin',
        ),
      ),
    );
  });

  test('saves normalized URL and marks server pin as configured', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(streamingSettingsControllerProvider.future);

    final notifier = container.read(
      streamingSettingsControllerProvider.notifier,
    );

    await notifier.saveInternetStreamingConfig(
      internetEnabled: true,
      serverUrlInput: 'https://your-server.example.com',
      serverConnectionPinInput: '12345678',
    );

    final settings = container.read(streamingSettingsControllerProvider).value;
    expect(settings, isNotNull);
    expect(settings!.internetStreamingEnabled, isTrue);
    expect(settings.signalingServerUrl, 'wss://your-server.example.com/ws');
    expect(settings.serverConnectionPinConfigured, isTrue);
  });
}
