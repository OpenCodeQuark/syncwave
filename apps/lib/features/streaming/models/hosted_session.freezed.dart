// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'hosted_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HostedSession {

 String get roomId; String get roomName;@JsonKey(fromJson: streamingModeFromJson, toJson: streamingModeToJson) StreamingMode get mode; String? get hostAddress; int? get hostPort; String? get serverUrl; String? get pin; bool get pinProtected;
/// Create a copy of HostedSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HostedSessionCopyWith<HostedSession> get copyWith => _$HostedSessionCopyWithImpl<HostedSession>(this as HostedSession, _$identity);

  /// Serializes this HostedSession to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HostedSession&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.roomName, roomName) || other.roomName == roomName)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.hostAddress, hostAddress) || other.hostAddress == hostAddress)&&(identical(other.hostPort, hostPort) || other.hostPort == hostPort)&&(identical(other.serverUrl, serverUrl) || other.serverUrl == serverUrl)&&(identical(other.pin, pin) || other.pin == pin)&&(identical(other.pinProtected, pinProtected) || other.pinProtected == pinProtected));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,roomId,roomName,mode,hostAddress,hostPort,serverUrl,pin,pinProtected);

@override
String toString() {
  return 'HostedSession(roomId: $roomId, roomName: $roomName, mode: $mode, hostAddress: $hostAddress, hostPort: $hostPort, serverUrl: $serverUrl, pin: $pin, pinProtected: $pinProtected)';
}


}

/// @nodoc
abstract mixin class $HostedSessionCopyWith<$Res>  {
  factory $HostedSessionCopyWith(HostedSession value, $Res Function(HostedSession) _then) = _$HostedSessionCopyWithImpl;
@useResult
$Res call({
 String roomId, String roomName,@JsonKey(fromJson: streamingModeFromJson, toJson: streamingModeToJson) StreamingMode mode, String? hostAddress, int? hostPort, String? serverUrl, String? pin, bool pinProtected
});




}
/// @nodoc
class _$HostedSessionCopyWithImpl<$Res>
    implements $HostedSessionCopyWith<$Res> {
  _$HostedSessionCopyWithImpl(this._self, this._then);

  final HostedSession _self;
  final $Res Function(HostedSession) _then;

/// Create a copy of HostedSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? roomId = null,Object? roomName = null,Object? mode = null,Object? hostAddress = freezed,Object? hostPort = freezed,Object? serverUrl = freezed,Object? pin = freezed,Object? pinProtected = null,}) {
  return _then(_self.copyWith(
roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,roomName: null == roomName ? _self.roomName : roomName // ignore: cast_nullable_to_non_nullable
as String,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as StreamingMode,hostAddress: freezed == hostAddress ? _self.hostAddress : hostAddress // ignore: cast_nullable_to_non_nullable
as String?,hostPort: freezed == hostPort ? _self.hostPort : hostPort // ignore: cast_nullable_to_non_nullable
as int?,serverUrl: freezed == serverUrl ? _self.serverUrl : serverUrl // ignore: cast_nullable_to_non_nullable
as String?,pin: freezed == pin ? _self.pin : pin // ignore: cast_nullable_to_non_nullable
as String?,pinProtected: null == pinProtected ? _self.pinProtected : pinProtected // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [HostedSession].
extension HostedSessionPatterns on HostedSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HostedSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HostedSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HostedSession value)  $default,){
final _that = this;
switch (_that) {
case _HostedSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HostedSession value)?  $default,){
final _that = this;
switch (_that) {
case _HostedSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String roomId,  String roomName, @JsonKey(fromJson: streamingModeFromJson, toJson: streamingModeToJson)  StreamingMode mode,  String? hostAddress,  int? hostPort,  String? serverUrl,  String? pin,  bool pinProtected)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HostedSession() when $default != null:
return $default(_that.roomId,_that.roomName,_that.mode,_that.hostAddress,_that.hostPort,_that.serverUrl,_that.pin,_that.pinProtected);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String roomId,  String roomName, @JsonKey(fromJson: streamingModeFromJson, toJson: streamingModeToJson)  StreamingMode mode,  String? hostAddress,  int? hostPort,  String? serverUrl,  String? pin,  bool pinProtected)  $default,) {final _that = this;
switch (_that) {
case _HostedSession():
return $default(_that.roomId,_that.roomName,_that.mode,_that.hostAddress,_that.hostPort,_that.serverUrl,_that.pin,_that.pinProtected);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String roomId,  String roomName, @JsonKey(fromJson: streamingModeFromJson, toJson: streamingModeToJson)  StreamingMode mode,  String? hostAddress,  int? hostPort,  String? serverUrl,  String? pin,  bool pinProtected)?  $default,) {final _that = this;
switch (_that) {
case _HostedSession() when $default != null:
return $default(_that.roomId,_that.roomName,_that.mode,_that.hostAddress,_that.hostPort,_that.serverUrl,_that.pin,_that.pinProtected);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HostedSession implements HostedSession {
  const _HostedSession({required this.roomId, required this.roomName, @JsonKey(fromJson: streamingModeFromJson, toJson: streamingModeToJson) required this.mode, this.hostAddress, this.hostPort, this.serverUrl, this.pin, this.pinProtected = false});
  factory _HostedSession.fromJson(Map<String, dynamic> json) => _$HostedSessionFromJson(json);

@override final  String roomId;
@override final  String roomName;
@override@JsonKey(fromJson: streamingModeFromJson, toJson: streamingModeToJson) final  StreamingMode mode;
@override final  String? hostAddress;
@override final  int? hostPort;
@override final  String? serverUrl;
@override final  String? pin;
@override@JsonKey() final  bool pinProtected;

/// Create a copy of HostedSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HostedSessionCopyWith<_HostedSession> get copyWith => __$HostedSessionCopyWithImpl<_HostedSession>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HostedSessionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HostedSession&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.roomName, roomName) || other.roomName == roomName)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.hostAddress, hostAddress) || other.hostAddress == hostAddress)&&(identical(other.hostPort, hostPort) || other.hostPort == hostPort)&&(identical(other.serverUrl, serverUrl) || other.serverUrl == serverUrl)&&(identical(other.pin, pin) || other.pin == pin)&&(identical(other.pinProtected, pinProtected) || other.pinProtected == pinProtected));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,roomId,roomName,mode,hostAddress,hostPort,serverUrl,pin,pinProtected);

@override
String toString() {
  return 'HostedSession(roomId: $roomId, roomName: $roomName, mode: $mode, hostAddress: $hostAddress, hostPort: $hostPort, serverUrl: $serverUrl, pin: $pin, pinProtected: $pinProtected)';
}


}

/// @nodoc
abstract mixin class _$HostedSessionCopyWith<$Res> implements $HostedSessionCopyWith<$Res> {
  factory _$HostedSessionCopyWith(_HostedSession value, $Res Function(_HostedSession) _then) = __$HostedSessionCopyWithImpl;
@override @useResult
$Res call({
 String roomId, String roomName,@JsonKey(fromJson: streamingModeFromJson, toJson: streamingModeToJson) StreamingMode mode, String? hostAddress, int? hostPort, String? serverUrl, String? pin, bool pinProtected
});




}
/// @nodoc
class __$HostedSessionCopyWithImpl<$Res>
    implements _$HostedSessionCopyWith<$Res> {
  __$HostedSessionCopyWithImpl(this._self, this._then);

  final _HostedSession _self;
  final $Res Function(_HostedSession) _then;

/// Create a copy of HostedSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? roomId = null,Object? roomName = null,Object? mode = null,Object? hostAddress = freezed,Object? hostPort = freezed,Object? serverUrl = freezed,Object? pin = freezed,Object? pinProtected = null,}) {
  return _then(_HostedSession(
roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,roomName: null == roomName ? _self.roomName : roomName // ignore: cast_nullable_to_non_nullable
as String,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as StreamingMode,hostAddress: freezed == hostAddress ? _self.hostAddress : hostAddress // ignore: cast_nullable_to_non_nullable
as String?,hostPort: freezed == hostPort ? _self.hostPort : hostPort // ignore: cast_nullable_to_non_nullable
as int?,serverUrl: freezed == serverUrl ? _self.serverUrl : serverUrl // ignore: cast_nullable_to_non_nullable
as String?,pin: freezed == pin ? _self.pin : pin // ignore: cast_nullable_to_non_nullable
as String?,pinProtected: null == pinProtected ? _self.pinProtected : pinProtected // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
