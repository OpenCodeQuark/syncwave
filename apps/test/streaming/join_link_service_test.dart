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

    test('builds app QR payload without PIN by default', () {
      final payload = service.buildAppQrPayload(
        const HostedSession(
          roomId: 'LAN-R12B9',
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
      expect(decoded['pin'], isNull);
      expect(decoded['protocolVersion'], '1');
      expect(decoded['joinPath'], '/stream/join');
      expect(decoded['wsPath'], '/stream/audio');
      expect(
        decoded['joinUrl'],
        'http://192.168.1.20:9000/stream/join?room=LAN-R12B9',
      );
    });

    test('includes PIN in app QR payload only when enabled', () {
      final payload = service.buildAppQrPayload(
        const HostedSession(
          roomId: 'LAN-R12B9',
          roomName: 'Room',
          mode: StreamingMode.local,
          hostAddress: '192.168.1.20',
          hostPort: 9000,
          roomPinProtected: true,
          pin: '123456',
        ),
        includeRoomPin: true,
      );

      final decoded = jsonDecode(payload) as Map<String, dynamic>;
      expect(decoded['pin'], '123456');
      expect(decoded['joinUrl'], contains('pin=123456'));
    });

    test('builds browser URL QR without pin by default', () {
      final browserUrl = service.buildBrowserUrlQr(
        const RoomJoinTarget(
          mode: StreamingMode.local,
          roomId: 'LAN-R12B9',
          hostAddress: '192.168.1.20',
          hostPort: 9000,
          pin: '123456',
          roomPinProtected: true,
        ),
      );

      expect(
        browserUrl,
        equals('http://192.168.1.20:9000/stream/join?room=LAN-R12B9'),
      );
      expect(browserUrl.contains('pin='), isFalse);
    });

    test('builds syncwave deep link with host and room', () {
      final deepLink = service.buildPrimaryQrPayload(
        const HostedSession(
          roomId: 'LAN-R12B9',
          roomName: 'Room',
          mode: StreamingMode.local,
          hostAddress: '192.168.1.20',
          hostPort: 9000,
          roomPinProtected: false,
        ),
      );

      expect(
        deepLink,
        equals('syncwave://join?host=192.168.1.20%3A9000&room=LAN-R12B9'),
      );
    });

    test('builds syncwave deep link with PIN only when explicitly enabled', () {
      final deepLink = service.buildPrimaryQrPayload(
        const HostedSession(
          roomId: 'LAN-R12B9',
          roomName: 'Room',
          mode: StreamingMode.local,
          hostAddress: '192.168.1.20',
          hostPort: 9000,
          roomPinProtected: true,
          pin: '123456',
        ),
        includeRoomPin: true,
      );

      expect(
        deepLink,
        equals(
          'syncwave://join?host=192.168.1.20%3A9000&room=LAN-R12B9&pin=123456',
        ),
      );
    });

    test('rejects localhost deep links', () {
      expect(
        () => service.parseQrPayload(
          'syncwave://join?host=127.0.0.1:9000&room=LAN-R12B9',
        ),
        throwsFormatException,
      );
    });

    test('rejects 0.0.0.0 deep links', () {
      expect(
        () => service.parseQrPayload(
          'syncwave://join?host=0.0.0.0:9000&room=LAN-R12B9',
        ),
        throwsFormatException,
      );
    });

    test('parses syncwave internet deep link', () {
      final target = service.parseQrPayload(
        'syncwave://join?host=your-server.example.com&room=WAN-RM01P',
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
        'roomId': 'LAN-R12B9',
        'hostAddress': '192.168.1.20',
        'hostPort': 9000,
        'roomPinProtected': true,
        'pin': '123456',
      };

      final target = service.parseQrPayload(jsonEncode(payload));
      expect(target.mode, StreamingMode.local);
      expect(target.roomId, 'LAN-R12B9');
      expect(target.hostAddress, '192.168.1.20');
      expect(target.pin, '123456');
      expect(target.roomPinProtected, isTrue);
    });

    test('rejects invalid QR room pin', () {
      const payload = {
        'app': 'syncwave',
        'version': 1,
        'mode': 'local',
        'roomId': 'LAN-R12B9',
        'pin': '12345',
      };

      expect(
        () => service.parseQrPayload(jsonEncode(payload)),
        throwsFormatException,
      );
    });

    test('rejects invalid room code in syncwave deep link', () {
      expect(
        () => service.parseQrPayload(
          'syncwave://join?host=192.168.1.20:9000&room=LAN-1234',
        ),
        throwsFormatException,
      );
    });
  });
}
