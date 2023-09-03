import 'package:freezed_annotation/freezed_annotation.dart';

import 'streaming_mode.dart';

part 'join_qr_payload.freezed.dart';
part 'join_qr_payload.g.dart';

Object? _readRoomPinProtected(Map<dynamic, dynamic> json, String key) {
  return json[key] ?? json['pinProtected'];
}

bool _boolFromDynamic(Object? value) => value == true;

Object? _readHost(Map<dynamic, dynamic> json, String key) {
  return json[key] ?? json['hostAddress'];
}

Object? _readPort(Map<dynamic, dynamic> json, String key) {
  return json[key] ?? json['hostPort'];
}

@freezed
abstract class JoinQrPayload with _$JoinQrPayload {
  const factory JoinQrPayload({
    @Default('syncwave') String app,
    @Default(1) int version,
    String? appVersion,
    @JsonKey(fromJson: streamingModeFromJson, toJson: streamingModeToJson)
    required StreamingMode mode,
    required String roomId,
    String? protocolVersion,
    String? joinUrl,
    String? joinPath,
    String? wsPath,
    @JsonKey(readValue: _readHost) String? host,
    @JsonKey(readValue: _readPort) int? port,
    String? hostAddress,
    int? hostPort,
    String? serverUrl,
    String? pin,
    @JsonKey(
      readValue: _readRoomPinProtected,
      fromJson: _boolFromDynamic,
      name: 'roomPinProtected',
    )
    @Default(false)
    bool roomPinProtected,
  }) = _JoinQrPayload;

  factory JoinQrPayload.fromJson(Map<String, dynamic> json) =>
      _$JoinQrPayloadFromJson(json);
}
