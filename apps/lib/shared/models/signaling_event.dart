import 'package:freezed_annotation/freezed_annotation.dart';

part 'signaling_event.freezed.dart';
part 'signaling_event.g.dart';

@freezed
abstract class SignalingEvent with _$SignalingEvent {
  const factory SignalingEvent({
    required String type,
    required String requestId,
    String? roomId,
    String? peerId,
    required int timestamp,
    @Default(<String, dynamic>{}) Map<String, dynamic> payload,
  }) = _SignalingEvent;

  factory SignalingEvent.fromJson(Map<String, dynamic> json) =>
      _$SignalingEventFromJson(json);
}
