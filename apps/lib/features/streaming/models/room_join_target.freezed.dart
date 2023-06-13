// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'room_join_target.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RoomJoinTarget {

@JsonKey(fromJson: streamingModeFromJson, toJson: streamingModeToJson) StreamingMode get mode; String get roomId; String? get hostAddress; int? get hostPort; String? get serverUrl; String? get pin; bool get pinProtected;
/// Create a copy of RoomJoinTarget
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoomJoinTargetCopyWith<RoomJoinTarget> get copyWith => _$RoomJoinTargetCopyWithImpl<RoomJoinTarget>(this as RoomJoinTarget, _$identity);

  /// Serializes this RoomJoinTarget to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoomJoinTarget&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.hostAddress, hostAddress) || other.hostAddress == hostAddress)&&(identical(other.hostPort, hostPort) || other.hostPort == hostPort)&&(identical(other.serverUrl, serverUrl) || other.serverUrl == serverUrl)&&(identical(other.pin, pin) || other.pin == pin)&&(identical(other.pinProtected, pinProtected) || other.pinProtected == pinProtected));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,mode,roomId,hostAddress,hostPort,serverUrl,pin,pinProtected);

@override
String toString() {
  return 'RoomJoinTarget(mode: $mode, roomId: $roomId, hostAddress: $hostAddress, hostPort: $hostPort, serverUrl: $serverUrl, pin: $pin, pinProtected: $pinProtected)';
}


}

/// @nodoc
abstract mixin class $RoomJoinTargetCopyWith<$Res>  {
  factory $RoomJoinTargetCopyWith(RoomJoinTarget value, $Res Function(RoomJoinTarget) _then) = _$RoomJoinTargetCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: streamingModeFromJson, toJson: streamingModeToJson) StreamingMode mode, String roomId, String? hostAddress, int? hostPort, String? serverUrl, String? pin, bool pinProtected
});




}
/// @nodoc
class _$RoomJoinTargetCopyWithImpl<$Res>
    implements $RoomJoinTargetCopyWith<$Res> {
  _$RoomJoinTargetCopyWithImpl(this._self, this._then);

  final RoomJoinTarget _self;
  final $Res Function(RoomJoinTarget) _then;

/// Create a copy of RoomJoinTarget
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mode = null,Object? roomId = null,Object? hostAddress = freezed,Object? hostPort = freezed,Object? serverUrl = freezed,Object? pin = freezed,Object? pinProtected = null,}) {
  return _then(_self.copyWith(
mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as StreamingMode,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,hostAddress: freezed == hostAddress ? _self.hostAddress : hostAddress // ignore: cast_nullable_to_non_nullable
as String?,hostPort: freezed == hostPort ? _self.hostPort : hostPort // ignore: cast_nullable_to_non_nullable
as int?,serverUrl: freezed == serverUrl ? _self.serverUrl : serverUrl // ignore: cast_nullable_to_non_nullable
as String?,pin: freezed == pin ? _self.pin : pin // ignore: cast_nullable_to_non_nullable
as String?,pinProtected: null == pinProtected ? _self.pinProtected : pinProtected // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [RoomJoinTarget].
extension RoomJoinTargetPatterns on RoomJoinTarget {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RoomJoinTarget value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RoomJoinTarget() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RoomJoinTarget value)  $default,){
final _that = this;
switch (_that) {
case _RoomJoinTarget():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RoomJoinTarget value)?  $default,){
final _that = this;
switch (_that) {
case _RoomJoinTarget() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: streamingModeFromJson, toJson: streamingModeToJson)  StreamingMode mode,  String roomId,  String? hostAddress,  int? hostPort,  String? serverUrl,  String? pin,  bool pinProtected)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RoomJoinTarget() when $default != null:
return $default(_that.mode,_that.roomId,_that.hostAddress,_that.hostPort,_that.serverUrl,_that.pin,_that.pinProtected);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: streamingModeFromJson, toJson: streamingModeToJson)  StreamingMode mode,  String roomId,  String? hostAddress,  int? hostPort,  String? serverUrl,  String? pin,  bool pinProtected)  $default,) {final _that = this;
switch (_that) {
case _RoomJoinTarget():
return $default(_that.mode,_that.roomId,_that.hostAddress,_that.hostPort,_that.serverUrl,_that.pin,_that.pinProtected);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: streamingModeFromJson, toJson: streamingModeToJson)  StreamingMode mode,  String roomId,  String? hostAddress,  int? hostPort,  String? serverUrl,  String? pin,  bool pinProtected)?  $default,) {final _that = this;
switch (_that) {
case _RoomJoinTarget() when $default != null:
return $default(_that.mode,_that.roomId,_that.hostAddress,_that.hostPort,_that.serverUrl,_that.pin,_that.pinProtected);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RoomJoinTarget implements RoomJoinTarget {
  const _RoomJoinTarget({@JsonKey(fromJson: streamingModeFromJson, toJson: streamingModeToJson) required this.mode, required this.roomId, this.hostAddress, this.hostPort, this.serverUrl, this.pin, this.pinProtected = false});
  factory _RoomJoinTarget.fromJson(Map<String, dynamic> json) => _$RoomJoinTargetFromJson(json);

@override@JsonKey(fromJson: streamingModeFromJson, toJson: streamingModeToJson) final  StreamingMode mode;
@override final  String roomId;
@override final  String? hostAddress;
@override final  int? hostPort;
@override final  String? serverUrl;
@override final  String? pin;
@override@JsonKey() final  bool pinProtected;

/// Create a copy of RoomJoinTarget
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RoomJoinTargetCopyWith<_RoomJoinTarget> get copyWith => __$RoomJoinTargetCopyWithImpl<_RoomJoinTarget>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RoomJoinTargetToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RoomJoinTarget&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.hostAddress, hostAddress) || other.hostAddress == hostAddress)&&(identical(other.hostPort, hostPort) || other.hostPort == hostPort)&&(identical(other.serverUrl, serverUrl) || other.serverUrl == serverUrl)&&(identical(other.pin, pin) || other.pin == pin)&&(identical(other.pinProtected, pinProtected) || other.pinProtected == pinProtected));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,mode,roomId,hostAddress,hostPort,serverUrl,pin,pinProtected);

@override
String toString() {
  return 'RoomJoinTarget(mode: $mode, roomId: $roomId, hostAddress: $hostAddress, hostPort: $hostPort, serverUrl: $serverUrl, pin: $pin, pinProtected: $pinProtected)';
}


}

/// @nodoc
abstract mixin class _$RoomJoinTargetCopyWith<$Res> implements $RoomJoinTargetCopyWith<$Res> {
  factory _$RoomJoinTargetCopyWith(_RoomJoinTarget value, $Res Function(_RoomJoinTarget) _then) = __$RoomJoinTargetCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: streamingModeFromJson, toJson: streamingModeToJson) StreamingMode mode, String roomId, String? hostAddress, int? hostPort, String? serverUrl, String? pin, bool pinProtected
});




}
/// @nodoc
class __$RoomJoinTargetCopyWithImpl<$Res>
    implements _$RoomJoinTargetCopyWith<$Res> {
  __$RoomJoinTargetCopyWithImpl(this._self, this._then);

  final _RoomJoinTarget _self;
  final $Res Function(_RoomJoinTarget) _then;

/// Create a copy of RoomJoinTarget
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? mode = null,Object? roomId = null,Object? hostAddress = freezed,Object? hostPort = freezed,Object? serverUrl = freezed,Object? pin = freezed,Object? pinProtected = null,}) {
  return _then(_RoomJoinTarget(
mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as StreamingMode,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,hostAddress: freezed == hostAddress ? _self.hostAddress : hostAddress // ignore: cast_nullable_to_non_nullable
as String?,hostPort: freezed == hostPort ? _self.hostPort : hostPort // ignore: cast_nullable_to_non_nullable
as int?,serverUrl: freezed == serverUrl ? _self.serverUrl : serverUrl // ignore: cast_nullable_to_non_nullable
as String?,pin: freezed == pin ? _self.pin : pin // ignore: cast_nullable_to_non_nullable
as String?,pinProtected: null == pinProtected ? _self.pinProtected : pinProtected // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
