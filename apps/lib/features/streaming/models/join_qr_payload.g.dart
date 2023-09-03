// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'join_qr_payload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_JoinQrPayload _$JoinQrPayloadFromJson(Map<String, dynamic> json) =>
    _JoinQrPayload(
      app: json['app'] as String? ?? 'syncwave',
      version: (json['version'] as num?)?.toInt() ?? 1,
      appVersion: json['appVersion'] as String?,
      mode: streamingModeFromJson(json['mode'] as String),
      roomId: json['roomId'] as String,
      protocolVersion: json['protocolVersion'] as String?,
      joinUrl: json['joinUrl'] as String?,
      joinPath: json['joinPath'] as String?,
      wsPath: json['wsPath'] as String?,
      host: _readHost(json, 'host') as String?,
      port: (_readPort(json, 'port') as num?)?.toInt(),
      hostAddress: json['hostAddress'] as String?,
      hostPort: (json['hostPort'] as num?)?.toInt(),
      serverUrl: json['serverUrl'] as String?,
      pin: json['pin'] as String?,
      roomPinProtected: _readRoomPinProtected(json, 'roomPinProtected') == null
          ? false
          : _boolFromDynamic(_readRoomPinProtected(json, 'roomPinProtected')),
    );

Map<String, dynamic> _$JoinQrPayloadToJson(_JoinQrPayload instance) =>
    <String, dynamic>{
      'app': instance.app,
      'version': instance.version,
      'appVersion': instance.appVersion,
      'mode': streamingModeToJson(instance.mode),
      'roomId': instance.roomId,
      'protocolVersion': instance.protocolVersion,
      'joinUrl': instance.joinUrl,
      'joinPath': instance.joinPath,
      'wsPath': instance.wsPath,
      'host': instance.host,
      'port': instance.port,
      'hostAddress': instance.hostAddress,
      'hostPort': instance.hostPort,
      'serverUrl': instance.serverUrl,
      'pin': instance.pin,
      'roomPinProtected': instance.roomPinProtected,
    };
