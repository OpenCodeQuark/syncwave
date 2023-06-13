import 'package:freezed_annotation/freezed_annotation.dart';

import 'streaming_mode.dart';

part 'hosted_session.freezed.dart';
part 'hosted_session.g.dart';

@freezed
abstract class HostedSession with _$HostedSession {
  const factory HostedSession({
    required String roomId,
    required String roomName,
    @JsonKey(fromJson: streamingModeFromJson, toJson: streamingModeToJson)
    required StreamingMode mode,
    String? hostAddress,
    int? hostPort,
    String? serverUrl,
    String? pin,
    @Default(false) bool pinProtected,
  }) = _HostedSession;

  factory HostedSession.fromJson(Map<String, dynamic> json) =>
      _$HostedSessionFromJson(json);
}
