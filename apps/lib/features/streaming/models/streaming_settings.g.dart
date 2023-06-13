// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'streaming_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StreamingSettings _$StreamingSettingsFromJson(Map<String, dynamic> json) =>
    _StreamingSettings(
      internetStreamingEnabled:
          json['internetStreamingEnabled'] as bool? ?? false,
      signalingServerUrl: json['signalingServerUrl'] as String?,
    );

Map<String, dynamic> _$StreamingSettingsToJson(_StreamingSettings instance) =>
    <String, dynamic>{
      'internetStreamingEnabled': instance.internetStreamingEnabled,
      'signalingServerUrl': instance.signalingServerUrl,
    };
