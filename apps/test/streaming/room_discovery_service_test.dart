import 'package:flutter_test/flutter_test.dart';
import 'package:syncwave/features/streaming/models/streaming_mode.dart';
import 'package:syncwave/features/streaming/services/pin_validation_service.dart';
import 'package:syncwave/features/streaming/services/room_discovery_service.dart';

void main() {
  group('RoomDiscoveryService', () {
    final service = RoomDiscoveryService(
      pinValidationService: PinValidationService(),
    );

    test('parses local join URL with room and pin query params', () {
      final target = service.parseManualJoinInput(
        'http://192.168.1.20:9000/stream/join?room=LAN-R12B9&pin=123456',
      );

      expect(target.mode, StreamingMode.local);
      expect(target.roomId, 'LAN-R12B9');
      expect(target.hostAddress, '192.168.1.20');
      expect(target.hostPort, 9000);
      expect(target.pin, '123456');
    });

    test('parses internet join URL with room query param', () {
      final target = service.parseManualJoinInput(
        'https://your-server.example.com/stream/join?room=WAN-RM01P',
      );

      expect(target.mode, StreamingMode.internet);
      expect(target.roomId, 'WAN-RM01P');
      expect(target.serverUrl, isNotNull);
    });

    test('parses bare WAN room code as internet target', () {
      final target = service.parseManualJoinInput('WAN-RM01P');

      expect(target.mode, StreamingMode.internet);
      expect(target.roomId, 'WAN-RM01P');
    });

    test('parses join URL with roomId query parameter', () {
      final target = service.parseManualJoinInput(
        'https://your-server.example.com/stream/join?roomId=WAN-RM01P',
      );

      expect(target.mode, StreamingMode.internet);
      expect(target.roomId, 'WAN-RM01P');
    });

    test('parses join URL without room into placeholder room id', () {
      final target = service.parseManualJoinInput(
        'http://192.168.1.20:9000/stream/join',
      );

      expect(target.mode, StreamingMode.local);
      expect(target.roomId, 'LAN-UNKWN');
    });

    test('rejects invalid pin from join URL', () {
      expect(
        () => service.parseManualJoinInput(
          'http://192.168.1.20:9000/stream/join?room=LAN-R12B9&pin=12345',
        ),
        throwsFormatException,
      );
    });

    test('parses syncwave deep link with host and room', () {
      final target = service.parseManualJoinInput(
        'syncwave://join?host=192.168.1.20:9000&room=LAN-R12B9',
      );

      expect(target.mode, StreamingMode.local);
      expect(target.roomId, 'LAN-R12B9');
      expect(target.hostAddress, '192.168.1.20');
      expect(target.hostPort, 9000);
    });

    test('parses syncwave deep link with separate port parameter', () {
      final target = service.parseManualJoinInput(
        'syncwave://join?host=192.168.1.20&port=9000&room=LAN-R12B9',
      );

      expect(target.mode, StreamingMode.local);
      expect(target.roomId, 'LAN-R12B9');
      expect(target.hostAddress, '192.168.1.20');
      expect(target.hostPort, 9000);
    });

    test('rejects localhost syncwave target', () {
      expect(
        () => service.parseManualJoinInput(
          'syncwave://join?host=127.0.0.1:9000&room=LAN-R12B9',
        ),
        throwsFormatException,
      );
    });

    test('rejects 0.0.0.0 syncwave target', () {
      expect(
        () => service.parseManualJoinInput(
          'syncwave://join?host=0.0.0.0:9000&room=LAN-R12B9',
        ),
        throwsFormatException,
      );
    });

    test('parses syncwave internet host target', () {
      final target = service.parseManualJoinInput(
        'syncwave://join?host=your-server.example.com&room=WAN-RM01P',
      );

      expect(target.mode, StreamingMode.internet);
      expect(target.serverUrl, 'https://your-server.example.com');
    });

    test('respects roomPinProtected query flag without exposing pin', () {
      final target = service.parseManualJoinInput(
        'http://192.168.1.20:9000/stream/join?room=LAN-R12B9&roomPinProtected=true',
      );

      expect(target.roomPinProtected, isTrue);
      expect(target.pin, isNull);
    });
  });
}
