// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'remote_server_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RemoteServerStatus _$RemoteServerStatusFromJson(Map<String, dynamic> json) =>
    _RemoteServerStatus(
      normalizedWebSocketUrl: json['normalizedWebSocketUrl'] as String?,
      statusUrl: json['statusUrl'] as String?,
      reachable: json['reachable'] as bool? ?? false,
      isSyncWaveServer: json['isSyncWaveServer'] as bool? ?? false,
      websocketConnected: json['websocketConnected'] as bool? ?? false,
      handshakeAccepted: json['handshakeAccepted'] as bool? ?? false,
      authenticationRequired: json['authenticationRequired'] as bool? ?? false,
      authenticationFailed: json['authenticationFailed'] as bool? ?? false,
      serverVersion: json['serverVersion'] as String?,
      protocolVersion: json['protocolVersion'] as String?,
      redisConnected: json['redisConnected'] as bool?,
      activeRooms: (json['activeRooms'] as num?)?.toInt(),
      activeConnections: (json['activeConnections'] as num?)?.toInt(),
      checkedAt: json['checkedAt'] == null
          ? null
          : DateTime.parse(json['checkedAt'] as String),
      message: json['message'] as String?,
      errorCode: json['errorCode'] as String?,
      state:
          $enumDecodeNullable(
            _$RemoteServerConnectionStateEnumMap,
            json['state'],
          ) ??
          RemoteServerConnectionState.notConfigured,
    );

Map<String, dynamic> _$RemoteServerStatusToJson(_RemoteServerStatus instance) =>
    <String, dynamic>{
      'normalizedWebSocketUrl': instance.normalizedWebSocketUrl,
      'statusUrl': instance.statusUrl,
      'reachable': instance.reachable,
      'isSyncWaveServer': instance.isSyncWaveServer,
      'websocketConnected': instance.websocketConnected,
      'handshakeAccepted': instance.handshakeAccepted,
      'authenticationRequired': instance.authenticationRequired,
      'authenticationFailed': instance.authenticationFailed,
      'serverVersion': instance.serverVersion,
      'protocolVersion': instance.protocolVersion,
      'redisConnected': instance.redisConnected,
      'activeRooms': instance.activeRooms,
      'activeConnections': instance.activeConnections,
      'checkedAt': instance.checkedAt?.toIso8601String(),
      'message': instance.message,
      'errorCode': instance.errorCode,
      'state': _$RemoteServerConnectionStateEnumMap[instance.state]!,
    };

const _$RemoteServerConnectionStateEnumMap = {
  RemoteServerConnectionState.notConfigured: 'notConfigured',
  RemoteServerConnectionState.invalidUrl: 'invalidUrl',
  RemoteServerConnectionState.checking: 'checking',
  RemoteServerConnectionState.serverReachable: 'serverReachable',
  RemoteServerConnectionState.serverOnlineNotConnected:
      'serverOnlineNotConnected',
  RemoteServerConnectionState.connected: 'connected',
  RemoteServerConnectionState.disconnected: 'disconnected',
  RemoteServerConnectionState.authenticationRequired: 'authenticationRequired',
  RemoteServerConnectionState.authenticationFailed: 'authenticationFailed',
  RemoteServerConnectionState.websocketFailed: 'websocketFailed',
  RemoteServerConnectionState.notSyncWaveServer: 'notSyncWaveServer',
};
