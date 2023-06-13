class PinValidationService {
  static final _pinPattern = RegExp(r'^\d{6}$');

  bool isValidPin(String pin) {
    return _pinPattern.hasMatch(pin.trim());
  }

  String? normalizeAndValidateOptional(String? pin) {
    final raw = pin?.trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }

    if (!isValidPin(raw)) {
      throw const FormatException('PIN must be exactly 6 digits.');
    }

    return raw;
  }

  void validateRequired(String pin) {
    if (!isValidPin(pin.trim())) {
      throw const FormatException('PIN must be exactly 6 digits.');
    }
  }
}
