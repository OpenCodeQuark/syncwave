import 'package:flutter_test/flutter_test.dart';
import 'package:syncwave/features/streaming/services/server_url_service.dart';

void main() {
  group('ServerUrlService', () {
    final service = ServerUrlService();

    test('normalizes https/http to websocket schemes', () {
      expect(
        service.normalize('https://example.com'),
        equals('wss://example.com/ws'),
      );
      expect(
        service.normalize('http://example.com'),
        equals('ws://example.com/ws'),
      );
    });

    test('normalizes ws/wss without path to /ws', () {
      expect(
        service.normalize('wss://example.com'),
        equals('wss://example.com/ws'),
      );
      expect(
        service.normalize('ws://example.com'),
        equals('ws://example.com/ws'),
      );
    });

    test('preserves existing path', () {
      expect(
        service.normalize('wss://example.com/custom/path'),
        equals('wss://example.com/custom/path'),
      );
    });

    test('rejects missing scheme', () {
      expect(() => service.normalize('example.com'), throwsFormatException);
    });
  });
}
