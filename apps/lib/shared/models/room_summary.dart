import 'package:freezed_annotation/freezed_annotation.dart';

part 'room_summary.freezed.dart';
part 'room_summary.g.dart';

@freezed
abstract class RoomSummary with _$RoomSummary {
  const factory RoomSummary({
    required String roomId,
    required String roomName,
    required bool pinProtected,
    required int participantCount,
  }) = _RoomSummary;

  factory RoomSummary.fromJson(Map<String, dynamic> json) =>
      _$RoomSummaryFromJson(json);
}
