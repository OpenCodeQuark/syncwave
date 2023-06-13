import 'package:flutter_test/flutter_test.dart';
import 'package:syncwave/features/streaming/services/pin_validation_service.dart';

void main() {
  group('PinValidationService', () {
    final service = PinValidationService();

    test('accepts valid six-digit pins', () {
      expect(service.isValidPin('123456'), isTrue);
      expect(service.isValidPin('000001'), isTrue);
      expect(service.isValidPin('987654'), isTrue);
    });

    test('rejects invalid pins', () {
      expect(service.isValidPin('12345'), isFalse);
      expect(service.isValidPin('1234567'), isFalse);
      expect(service.isValidPin('abc123'), isFalse);
      expect(service.isValidPin('12 3456'), isFalse);
      expect(service.isValidPin('123-456'), isFalse);
    });

    test('normalizeAndValidateOptional throws for invalid format', () {
      expect(
        () => service.normalizeAndValidateOptional('12345'),
        throwsFormatException,
      );
    });
  });
}
