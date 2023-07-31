import 'package:flutter_test/flutter_test.dart';
import 'package:syncwave/features/streaming/services/server_connection_pin_validation_service.dart';

void main() {
  group('ServerConnectionPinValidationService', () {
    final service = ServerConnectionPinValidationService();

    test('accepts 8-10 digit pins', () {
      expect(service.isValid('12345678'), isTrue);
      expect(service.isValid('1234567890'), isTrue);
    });

    test('rejects invalid server connection pins', () {
      expect(service.isValid('1234567'), isFalse);
      expect(service.isValid('12345678901'), isFalse);
      expect(service.isValid('abc12345'), isFalse);
      expect(service.isValid('1234 5678'), isFalse);
    });

    test('normalizeAndValidateOptional throws for invalid format', () {
      expect(
        () => service.normalizeAndValidateOptional('1234567'),
        throwsFormatException,
      );
    });
  });
}
