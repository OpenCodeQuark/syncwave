// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hosted_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HostedSession _$HostedSessionFromJson(Map<String, dynamic> json) =>
    _HostedSession(
      roomId: json['roomId'] as String,
      roomName: json['roomName'] as String,
      mode: streamingModeFromJson(json['mode'] as String),
      hostAddress: json['hostAddress'] as String?,
      hostPort: (json['hostPort'] as num?)?.toInt(),
      serverUrl: json['serverUrl'] as String?,
      wanRoomId: json['wanRoomId'] as String?,
      pin: json['pin'] as String?,
      roomPinProtected: json['roomPinProtected'] as bool? ?? false,
      audioSourceEnabled: json['audioSourceEnabled'] as bool? ?? true,
      microphoneEnabled: json['microphoneEnabled'] as bool? ?? false,
    );

Map<String, dynamic> _$HostedSessionToJson(_HostedSession instance) =>
    <String, dynamic>{
      'roomId': instance.roomId,
      'roomName': instance.roomName,
      'mode': streamingModeToJson(instance.mode),
      'hostAddress': instance.hostAddress,
      'hostPort': instance.hostPort,
      'serverUrl': instance.serverUrl,
      'wanRoomId': instance.wanRoomId,
      'pin': instance.pin,
      'roomPinProtected': instance.roomPinProtected,
      'audioSourceEnabled': instance.audioSourceEnabled,
      'microphoneEnabled': instance.microphoneEnabled,
    };
