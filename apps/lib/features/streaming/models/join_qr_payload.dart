import 'package:freezed_annotation/freezed_annotation.dart';

import 'streaming_mode.dart';

part 'join_qr_payload.freezed.dart';
part 'join_qr_payload.g.dart';

@freezed
abstract class JoinQrPayload with _$JoinQrPayload {
  const factory JoinQrPayload({
    @Default('syncwave') String app,
    @Default(1) int version,
    @JsonKey(fromJson: streamingModeFromJson, toJson: streamingModeToJson)
    required StreamingMode mode,
    required String roomId,
    String? joinUrl,
    String? hostAddress,
    int? hostPort,
    String? serverUrl,
    String? pin,
    @Default(false) bool pinProtected,
  }) = _JoinQrPayload;

  factory JoinQrPayload.fromJson(Map<String, dynamic> json) =>
      _$JoinQrPayloadFromJson(json);
}
