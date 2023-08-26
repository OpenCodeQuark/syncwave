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
        'http://192.168.1.20:9000/stream/join?room=SW-8FD2-KQ&pin=123456',
      );

      expect(target.mode, StreamingMode.local);
      expect(target.roomId, 'SW-8FD2-KQ');
      expect(target.hostAddress, '192.168.1.20');
      expect(target.hostPort, 9000);
      expect(target.pin, '123456');
    });

    test('parses internet join URL with room query param', () {
      final target = service.parseManualJoinInput(
        'https://your-server.example.com/stream/join?room=SW-8FD2-KQ',
      );

      expect(target.mode, StreamingMode.internet);
      expect(target.roomId, 'SW-8FD2-KQ');
      expect(target.serverUrl, isNotNull);
    });

    test('parses join URL with roomId query parameter', () {
      final target = service.parseManualJoinInput(
        'https://your-server.example.com/stream/join?roomId=SW-8FD2-KQ',
      );

      expect(target.mode, StreamingMode.internet);
      expect(target.roomId, 'SW-8FD2-KQ');
    });

    test('parses join URL without room into placeholder room id', () {
      final target = service.parseManualJoinInput(
        'http://192.168.1.20:9000/stream/join',
      );

      expect(target.mode, StreamingMode.local);
      expect(target.roomId, 'SW-UNKNOWN');
    });

    test('rejects invalid pin from join URL', () {
      expect(
        () => service.parseManualJoinInput(
          'http://192.168.1.20:9000/stream/join?room=SW-8FD2-KQ&pin=12345',
        ),
        throwsFormatException,
      );
    });

    test('parses syncwave deep link with host and room', () {
      final target = service.parseManualJoinInput(
        'syncwave://join?host=192.168.1.20:9000&room=SW-8FD2-KQ',
      );

      expect(target.mode, StreamingMode.local);
      expect(target.roomId, 'SW-8FD2-KQ');
      expect(target.hostAddress, '192.168.1.20');
      expect(target.hostPort, 9000);
    });

    test('rejects localhost syncwave target', () {
      expect(
        () => service.parseManualJoinInput(
          'syncwave://join?host=127.0.0.1:9000&room=SW-8FD2-KQ',
        ),
        throwsFormatException,
      );
    });

    test('parses syncwave internet host target', () {
      final target = service.parseManualJoinInput(
        'syncwave://join?host=your-server.example.com&room=SW-8FD2-KQ',
      );

      expect(target.mode, StreamingMode.internet);
      expect(target.serverUrl, 'https://your-server.example.com');
    });
  });
}
