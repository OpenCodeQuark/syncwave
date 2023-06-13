import 'package:freezed_annotation/freezed_annotation.dart';

part 'streaming_settings.freezed.dart';
part 'streaming_settings.g.dart';

@freezed
abstract class StreamingSettings with _$StreamingSettings {
  const factory StreamingSettings({
    @Default(false) bool internetStreamingEnabled,
    String? signalingServerUrl,
  }) = _StreamingSettings;

  factory StreamingSettings.fromJson(Map<String, dynamic> json) =>
      _$StreamingSettingsFromJson(json);
}

extension StreamingSettingsX on StreamingSettings {
  bool get hasServerUrl => signalingServerUrl?.trim().isNotEmpty ?? false;

  bool get internetModeReady => internetStreamingEnabled && hasServerUrl;
}
