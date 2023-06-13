// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'signaling_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SignalingEvent {

 String get type; String get requestId; String? get roomId; String? get peerId; int get timestamp; Map<String, dynamic> get payload;
/// Create a copy of SignalingEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SignalingEventCopyWith<SignalingEvent> get copyWith => _$SignalingEventCopyWithImpl<SignalingEvent>(this as SignalingEvent, _$identity);

  /// Serializes this SignalingEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignalingEvent&&(identical(other.type, type) || other.type == type)&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.peerId, peerId) || other.peerId == peerId)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&const DeepCollectionEquality().equals(other.payload, payload));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,requestId,roomId,peerId,timestamp,const DeepCollectionEquality().hash(payload));

@override
String toString() {
  return 'SignalingEvent(type: $type, requestId: $requestId, roomId: $roomId, peerId: $peerId, timestamp: $timestamp, payload: $payload)';
}


}

/// @nodoc
abstract mixin class $SignalingEventCopyWith<$Res>  {
  factory $SignalingEventCopyWith(SignalingEvent value, $Res Function(SignalingEvent) _then) = _$SignalingEventCopyWithImpl;
@useResult
$Res call({
 String type, String requestId, String? roomId, String? peerId, int timestamp, Map<String, dynamic> payload
});




}
/// @nodoc
class _$SignalingEventCopyWithImpl<$Res>
    implements $SignalingEventCopyWith<$Res> {
  _$SignalingEventCopyWithImpl(this._self, this._then);

  final SignalingEvent _self;
  final $Res Function(SignalingEvent) _then;

/// Create a copy of SignalingEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? requestId = null,Object? roomId = freezed,Object? peerId = freezed,Object? timestamp = null,Object? payload = null,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,roomId: freezed == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String?,peerId: freezed == peerId ? _self.peerId : peerId // ignore: cast_nullable_to_non_nullable
as String?,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as int,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [SignalingEvent].
extension SignalingEventPatterns on SignalingEvent {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SignalingEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SignalingEvent() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SignalingEvent value)  $default,){
final _that = this;
switch (_that) {
case _SignalingEvent():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SignalingEvent value)?  $default,){
final _that = this;
switch (_that) {
case _SignalingEvent() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String type,  String requestId,  String? roomId,  String? peerId,  int timestamp,  Map<String, dynamic> payload)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SignalingEvent() when $default != null:
return $default(_that.type,_that.requestId,_that.roomId,_that.peerId,_that.timestamp,_that.payload);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String type,  String requestId,  String? roomId,  String? peerId,  int timestamp,  Map<String, dynamic> payload)  $default,) {final _that = this;
switch (_that) {
case _SignalingEvent():
return $default(_that.type,_that.requestId,_that.roomId,_that.peerId,_that.timestamp,_that.payload);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String type,  String requestId,  String? roomId,  String? peerId,  int timestamp,  Map<String, dynamic> payload)?  $default,) {final _that = this;
switch (_that) {
case _SignalingEvent() when $default != null:
return $default(_that.type,_that.requestId,_that.roomId,_that.peerId,_that.timestamp,_that.payload);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SignalingEvent implements SignalingEvent {
  const _SignalingEvent({required this.type, required this.requestId, this.roomId, this.peerId, required this.timestamp, final  Map<String, dynamic> payload = const <String, dynamic>{}}): _payload = payload;
  factory _SignalingEvent.fromJson(Map<String, dynamic> json) => _$SignalingEventFromJson(json);

@override final  String type;
@override final  String requestId;
@override final  String? roomId;
@override final  String? peerId;
@override final  int timestamp;
 final  Map<String, dynamic> _payload;
@override@JsonKey() Map<String, dynamic> get payload {
  if (_payload is EqualUnmodifiableMapView) return _payload;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_payload);
}


/// Create a copy of SignalingEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SignalingEventCopyWith<_SignalingEvent> get copyWith => __$SignalingEventCopyWithImpl<_SignalingEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SignalingEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SignalingEvent&&(identical(other.type, type) || other.type == type)&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.peerId, peerId) || other.peerId == peerId)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&const DeepCollectionEquality().equals(other._payload, _payload));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,requestId,roomId,peerId,timestamp,const DeepCollectionEquality().hash(_payload));

@override
String toString() {
  return 'SignalingEvent(type: $type, requestId: $requestId, roomId: $roomId, peerId: $peerId, timestamp: $timestamp, payload: $payload)';
}


}

/// @nodoc
abstract mixin class _$SignalingEventCopyWith<$Res> implements $SignalingEventCopyWith<$Res> {
  factory _$SignalingEventCopyWith(_SignalingEvent value, $Res Function(_SignalingEvent) _then) = __$SignalingEventCopyWithImpl;
@override @useResult
$Res call({
 String type, String requestId, String? roomId, String? peerId, int timestamp, Map<String, dynamic> payload
});




}
/// @nodoc
class __$SignalingEventCopyWithImpl<$Res>
    implements _$SignalingEventCopyWith<$Res> {
  __$SignalingEventCopyWithImpl(this._self, this._then);

  final _SignalingEvent _self;
  final $Res Function(_SignalingEvent) _then;

/// Create a copy of SignalingEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? requestId = null,Object? roomId = freezed,Object? peerId = freezed,Object? timestamp = null,Object? payload = null,}) {
  return _then(_SignalingEvent(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,roomId: freezed == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String?,peerId: freezed == peerId ? _self.peerId : peerId // ignore: cast_nullable_to_non_nullable
as String?,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as int,payload: null == payload ? _self._payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

// dart format on
