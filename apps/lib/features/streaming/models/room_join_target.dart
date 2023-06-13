import 'package:freezed_annotation/freezed_annotation.dart';

import 'streaming_mode.dart';

part 'room_join_target.freezed.dart';
part 'room_join_target.g.dart';

@freezed
abstract class RoomJoinTarget with _$RoomJoinTarget {
  const factory RoomJoinTarget({
    @JsonKey(fromJson: streamingModeFromJson, toJson: streamingModeToJson)
    required StreamingMode mode,
    required String roomId,
    String? hostAddress,
    int? hostPort,
    String? serverUrl,
    String? pin,
    @Default(false) bool pinProtected,
  }) = _RoomJoinTarget;

  factory RoomJoinTarget.fromJson(Map<String, dynamic> json) =>
      _$RoomJoinTargetFromJson(json);
}
