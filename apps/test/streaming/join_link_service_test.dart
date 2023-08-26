import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:syncwave/features/streaming/models/hosted_session.dart';
import 'package:syncwave/features/streaming/models/room_join_target.dart';
import 'package:syncwave/features/streaming/models/streaming_mode.dart';
import 'package:syncwave/features/streaming/services/join_link_service.dart';
import 'package:syncwave/features/streaming/services/pin_validation_service.dart';

void main() {
  group('JoinLinkService', () {
    final service = JoinLinkService(
      pinValidationService: PinValidationService(),
    );

    test('builds app QR payload with roomPinProtected and appVersion', () {
      final payload = service.buildAppQrPayload(
        const HostedSession(
          roomId: 'SW-8FD2-KQ',
          roomName: 'Room',
          mode: StreamingMode.local,
          hostAddress: '192.168.1.20',
          hostPort: 9000,
          roomPinProtected: true,
          pin: '123456',
        ),
        appVersion: '1.0.0',
      );

      final decoded = jsonDecode(payload) as Map<String, dynamic>;
      expect(decoded['app'], 'syncwave');
      expect(decoded['appVersion'], '1.0.0');
      expect(decoded['roomPinProtected'], isTrue);
      expect(
        decoded['joinUrl'],
        'http://192.168.1.20:9000/stream/join?room=SW-8FD2-KQ',
      );
    });

    test('builds browser URL QR without pin by default', () {
      final browserUrl = service.buildBrowserUrlQr(
        const RoomJoinTarget(
          mode: StreamingMode.local,
          roomId: 'SW-8FD2-KQ',
          hostAddress: '192.168.1.20',
          hostPort: 9000,
          pin: '123456',
          roomPinProtected: true,
        ),
      );

      expect(
        browserUrl,
        equals('http://192.168.1.20:9000/stream/join?room=SW-8FD2-KQ'),
      );
      expect(browserUrl.contains('pin='), isFalse);
    });

    test('builds syncwave deep link with host and room', () {
      final deepLink = service.buildPrimaryQrPayload(
        const HostedSession(
          roomId: 'SW-8FD2-KQ',
          roomName: 'Room',
          mode: StreamingMode.local,
          hostAddress: '192.168.1.20',
          hostPort: 9000,
          roomPinProtected: false,
        ),
      );

      expect(
        deepLink,
        equals('syncwave://join?host=192.168.1.20%3A9000&room=SW-8FD2-KQ'),
      );
    });

    test('rejects localhost deep links', () {
      expect(
        () => service.parseQrPayload(
          'syncwave://join?host=127.0.0.1:9000&room=SW-8FD2-KQ',
        ),
        throwsFormatException,
      );
    });

    test('parses syncwave internet deep link', () {
      final target = service.parseQrPayload(
        'syncwave://join?host=your-server.example.com&room=SW-8FD2-KQ',
      );

      expect(target.mode, StreamingMode.internet);
      expect(target.serverUrl, 'https://your-server.example.com');
    });

    test('parses structured QR payload with local data', () {
      const payload = {
        'app': 'syncwave',
        'version': 1,
        'appVersion': '1.0.0',
        'mode': 'local',
        'roomId': 'SW-8FD2-KQ',
        'hostAddress': '192.168.1.20',
        'hostPort': 9000,
        'roomPinProtected': true,
        'pin': '123456',
      };

      final target = service.parseQrPayload(jsonEncode(payload));
      expect(target.mode, StreamingMode.local);
      expect(target.roomId, 'SW-8FD2-KQ');
      expect(target.hostAddress, '192.168.1.20');
      expect(target.pin, '123456');
      expect(target.roomPinProtected, isTrue);
    });

    test('rejects invalid QR room pin', () {
      const payload = {
        'app': 'syncwave',
        'version': 1,
        'mode': 'local',
        'roomId': 'SW-8FD2-KQ',
        'pin': '12345',
      };

      expect(
        () => service.parseQrPayload(jsonEncode(payload)),
        throwsFormatException,
      );
    });
  });
}
