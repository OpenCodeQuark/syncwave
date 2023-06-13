enum StreamingMode {
  local('local', 'Local Mode'),
  internet('internet', 'Internet Mode');

  const StreamingMode(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static StreamingMode fromWireValue(String value) {
    return StreamingMode.values.firstWhere(
      (mode) => mode.wireValue == value,
      orElse: () => StreamingMode.local,
    );
  }
}

StreamingMode streamingModeFromJson(String value) {
  return StreamingMode.fromWireValue(value);
}

String streamingModeToJson(StreamingMode mode) {
  return mode.wireValue;
}
