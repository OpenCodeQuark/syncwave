import 'package:freezed_annotation/freezed_annotation.dart';

import 'remote_server_connection_state.dart';

part 'remote_server_status.freezed.dart';
part 'remote_server_status.g.dart';

@freezed
abstract class RemoteServerStatus with _$RemoteServerStatus {
  const factory RemoteServerStatus({
    String? normalizedWebSocketUrl,
    String? statusUrl,
    @Default(false) bool reachable,
    @Default(false) bool isSyncWaveServer,
    @Default(false) bool websocketConnected,
    @Default(false) bool handshakeAccepted,
    @Default(false) bool authenticationRequired,
    @Default(false) bool authenticationFailed,
    String? serverVersion,
    String? protocolVersion,
    bool? redisConnected,
    int? activeRooms,
    int? activeConnections,
    DateTime? checkedAt,
    String? message,
    String? errorCode,
    @Default(RemoteServerConnectionState.notConfigured)
    RemoteServerConnectionState state,
  }) = _RemoteServerStatus;

  factory RemoteServerStatus.fromJson(Map<String, dynamic> json) =>
      _$RemoteServerStatusFromJson(json);
}

extension RemoteServerStatusX on RemoteServerStatus {
  bool get internetBroadcastReady {
    return reachable &&
        isSyncWaveServer &&
        websocketConnected &&
        handshakeAccepted &&
        !authenticationRequired &&
        !authenticationFailed;
  }
}
