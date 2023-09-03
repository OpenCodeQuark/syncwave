import 'package:flutter_test/flutter_test.dart';
import 'package:syncwave/features/streaming/services/room_code_service.dart';

void main() {
  group('RoomCodeService', () {
    final service = RoomCodeService();

    test('generates LAN room code in LAN-XXXXX format', () {
      final code = service.generateLanCode();
      expect(RegExp(r'^LAN-[A-Z0-9]{5}$').hasMatch(code), isTrue);
      expect(service.isValidLanCode(code), isTrue);
    });

    test('validates LAN/WAN codes and rejects invalid names', () {
      expect(service.isValidRoomCode('LAN-R12B9'), isTrue);
      expect(service.isValidRoomCode('WAN-RM01P'), isTrue);
      expect(service.isValidRoomCode('wan-rm01p'), isFalse);
      expect(service.isValidRoomCode('LAN-1234'), isFalse);
      expect(service.isValidRoomCode('ABC-12345'), isFalse);
    });
  });
}
