import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ServerConnectionPinRepository {
  ServerConnectionPinRepository({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secureStorage;

  static const _pinKey = 'settings.server_connection_pin';

  String? _memoryFallbackPin;

  Future<String?> readPin() async {
    try {
      final value = await _secureStorage.read(key: _pinKey);
      if (value == null || value.trim().isEmpty) {
        return null;
      }
      return value.trim();
    } catch (_) {
      return _memoryFallbackPin;
    }
  }

  Future<void> savePin(String pin) async {
    _memoryFallbackPin = pin;
    try {
      await _secureStorage.write(key: _pinKey, value: pin);
    } catch (_) {
      // Ignore storage fallback write failures; in-memory fallback remains active.
    }
  }

  Future<void> clearPin() async {
    _memoryFallbackPin = null;
    try {
      await _secureStorage.delete(key: _pinKey);
    } catch (_) {
      // Ignore storage fallback delete failures.
    }
  }
}
