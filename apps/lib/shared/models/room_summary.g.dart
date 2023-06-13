// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RoomSummary _$RoomSummaryFromJson(Map<String, dynamic> json) => _RoomSummary(
  roomId: json['roomId'] as String,
  roomName: json['roomName'] as String,
  pinProtected: json['pinProtected'] as bool,
  participantCount: (json['participantCount'] as num).toInt(),
);

Map<String, dynamic> _$RoomSummaryToJson(_RoomSummary instance) =>
    <String, dynamic>{
      'roomId': instance.roomId,
      'roomName': instance.roomName,
      'pinProtected': instance.pinProtected,
      'participantCount': instance.participantCount,
    };
