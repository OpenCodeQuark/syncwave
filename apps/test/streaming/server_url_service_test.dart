import 'package:flutter_test/flutter_test.dart';
import 'package:syncwave/features/streaming/services/server_url_service.dart';

void main() {
  group('ServerUrlService', () {
    final service = ServerUrlService();

    test('normalizes https/http to websocket schemes', () {
      expect(
        service.normalize('https://your-server.example.com'),
        equals('wss://your-server.example.com/ws'),
      );
      expect(
        service.normalize('http://your-server.example.com'),
        equals('ws://your-server.example.com/ws'),
      );
    });

    test('normalizes ws/wss without path to /ws', () {
      expect(
        service.normalize('wss://your-server.example.com'),
        equals('wss://your-server.example.com/ws'),
      );
      expect(
        service.normalize('ws://your-server.example.com'),
        equals('ws://your-server.example.com/ws'),
      );
    });

    test('preserves existing path', () {
      expect(
        service.normalize('wss://your-server.example.com/custom/path'),
        equals('wss://your-server.example.com/custom/path'),
      );
    });

    test('normalizes browser join and status URLs to websocket path', () {
      expect(
        service.normalize(
          'https://your-server.example.com/stream/join?room=WAN-RM01P',
        ),
        equals('wss://your-server.example.com/ws'),
      );
      expect(
        service.normalize('https://your-server.example.com/status'),
        equals('wss://your-server.example.com/ws'),
      );
    });

    test('derives /status URL from websocket URL', () {
      expect(
        service.deriveStatusUrl('wss://your-server.example.com/ws'),
        equals('https://your-server.example.com/status'),
      );
      expect(
        service.deriveStatusUrl('ws://your-server.example.com/ws'),
        equals('http://your-server.example.com/status'),
      );
    });

    test('rejects missing scheme', () {
      expect(
        () => service.normalize('your-server.example.com'),
        throwsFormatException,
      );
    });
  });
}
