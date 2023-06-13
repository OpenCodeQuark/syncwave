import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:syncwave/features/streaming/models/streaming_mode.dart';
import 'package:syncwave/features/streaming/services/join_link_service.dart';
import 'package:syncwave/features/streaming/services/pin_validation_service.dart';

void main() {
  group('JoinLinkService', () {
    final service = JoinLinkService(
      pinValidationService: PinValidationService(),
    );

    test('parses structured QR payload with local data', () {
      const payload = {
        'app': 'syncwave',
        'version': 1,
        'mode': 'local',
        'roomId': 'SW-8FD2-KQ',
        'hostAddress': '192.168.1.20',
        'hostPort': 9000,
        'pinProtected': true,
        'pin': '123456',
      };

      final target = service.parseQrPayload(jsonEncode(payload));
      expect(target.mode, StreamingMode.local);
      expect(target.roomId, 'SW-8FD2-KQ');
      expect(target.hostAddress, '192.168.1.20');
      expect(target.pin, '123456');
    });

    test('rejects invalid QR pin', () {
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
