class ServerConnectionPinValidationService {
  static final _pattern = RegExp(r'^\d{8,10}$');

  bool isValid(String pin) {
    return _pattern.hasMatch(pin.trim());
  }

  String? normalizeAndValidateOptional(String? pin) {
    final raw = pin?.trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }

    if (!isValid(raw)) {
      throw const FormatException(
        'Server Connection PIN must be 8 to 10 digits.',
      );
    }

    return raw;
  }
}
