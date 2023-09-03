import 'dart:math';

class RoomCodeService {
  static final _lanPattern = RegExp(r'^LAN-[A-Z0-9]{5}$');
  static final _wanPattern = RegExp(r'^WAN-[A-Z0-9]{5}$');
  static final _legacyPattern = RegExp(r'^SW-[A-Z0-9]{4}-[A-Z0-9]{2}$');

  static const _characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  final Random _random = Random.secure();

  bool isValidLanCode(String code) => _lanPattern.hasMatch(code.trim());

  bool isValidWanCode(String code) => _wanPattern.hasMatch(code.trim());

  bool isValidRoomCode(String code) {
    final value = code.trim();
    return _lanPattern.hasMatch(value) ||
        _wanPattern.hasMatch(value) ||
        _legacyPattern.hasMatch(value);
  }

  String generateLanCode({Set<String> activeCodes = const <String>{}}) {
    while (true) {
      final suffix = List.generate(
        5,
        (_) => _characters[_random.nextInt(_characters.length)],
      ).join();
      final roomCode = 'LAN-$suffix';
      if (!activeCodes.contains(roomCode)) {
        return roomCode;
      }
    }
  }
}
