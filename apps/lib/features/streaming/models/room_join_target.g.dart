// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_join_target.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RoomJoinTarget _$RoomJoinTargetFromJson(Map<String, dynamic> json) =>
    _RoomJoinTarget(
      mode: streamingModeFromJson(json['mode'] as String),
      roomId: json['roomId'] as String,
      hostAddress: json['hostAddress'] as String?,
      hostPort: (json['hostPort'] as num?)?.toInt(),
      serverUrl: json['serverUrl'] as String?,
      pin: json['pin'] as String?,
      pinProtected: json['pinProtected'] as bool? ?? false,
    );

Map<String, dynamic> _$RoomJoinTargetToJson(_RoomJoinTarget instance) =>
    <String, dynamic>{
      'mode': streamingModeToJson(instance.mode),
      'roomId': instance.roomId,
      'hostAddress': instance.hostAddress,
      'hostPort': instance.hostPort,
      'serverUrl': instance.serverUrl,
      'pin': instance.pin,
      'pinProtected': instance.pinProtected,
    };
