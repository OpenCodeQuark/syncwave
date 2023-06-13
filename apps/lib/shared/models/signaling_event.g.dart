// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signaling_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SignalingEvent _$SignalingEventFromJson(Map<String, dynamic> json) =>
    _SignalingEvent(
      type: json['type'] as String,
      requestId: json['requestId'] as String,
      roomId: json['roomId'] as String?,
      peerId: json['peerId'] as String?,
      timestamp: (json['timestamp'] as num).toInt(),
      payload:
          json['payload'] as Map<String, dynamic>? ?? const <String, dynamic>{},
    );

Map<String, dynamic> _$SignalingEventToJson(_SignalingEvent instance) =>
    <String, dynamic>{
      'type': instance.type,
      'requestId': instance.requestId,
      'roomId': instance.roomId,
      'peerId': instance.peerId,
      'timestamp': instance.timestamp,
      'payload': instance.payload,
    };
