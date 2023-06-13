// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'join_qr_payload.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$JoinQrPayload {

 String get app; int get version;@JsonKey(fromJson: streamingModeFromJson, toJson: streamingModeToJson) StreamingMode get mode; String get roomId; String? get joinUrl; String? get hostAddress; int? get hostPort; String? get serverUrl; String? get pin; bool get pinProtected;
/// Create a copy of JoinQrPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JoinQrPayloadCopyWith<JoinQrPayload> get copyWith => _$JoinQrPayloadCopyWithImpl<JoinQrPayload>(this as JoinQrPayload, _$identity);

  /// Serializes this JoinQrPayload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JoinQrPayload&&(identical(other.app, app) || other.app == app)&&(identical(other.version, version) || other.version == version)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.joinUrl, joinUrl) || other.joinUrl == joinUrl)&&(identical(other.hostAddress, hostAddress) || other.hostAddress == hostAddress)&&(identical(other.hostPort, hostPort) || other.hostPort == hostPort)&&(identical(other.serverUrl, serverUrl) || other.serverUrl == serverUrl)&&(identical(other.pin, pin) || other.pin == pin)&&(identical(other.pinProtected, pinProtected) || other.pinProtected == pinProtected));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,app,version,mode,roomId,joinUrl,hostAddress,hostPort,serverUrl,pin,pinProtected);

@override
String toString() {
  return 'JoinQrPayload(app: $app, version: $version, mode: $mode, roomId: $roomId, joinUrl: $joinUrl, hostAddress: $hostAddress, hostPort: $hostPort, serverUrl: $serverUrl, pin: $pin, pinProtected: $pinProtected)';
}


}

/// @nodoc
abstract mixin class $JoinQrPayloadCopyWith<$Res>  {
  factory $JoinQrPayloadCopyWith(JoinQrPayload value, $Res Function(JoinQrPayload) _then) = _$JoinQrPayloadCopyWithImpl;
@useResult
$Res call({
 String app, int version,@JsonKey(fromJson: streamingModeFromJson, toJson: streamingModeToJson) StreamingMode mode, String roomId, String? joinUrl, String? hostAddress, int? hostPort, String? serverUrl, String? pin, bool pinProtected
});




}
/// @nodoc
class _$JoinQrPayloadCopyWithImpl<$Res>
    implements $JoinQrPayloadCopyWith<$Res> {
  _$JoinQrPayloadCopyWithImpl(this._self, this._then);

  final JoinQrPayload _self;
  final $Res Function(JoinQrPayload) _then;

/// Create a copy of JoinQrPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? app = null,Object? version = null,Object? mode = null,Object? roomId = null,Object? joinUrl = freezed,Object? hostAddress = freezed,Object? hostPort = freezed,Object? serverUrl = freezed,Object? pin = freezed,Object? pinProtected = null,}) {
  return _then(_self.copyWith(
app: null == app ? _self.app : app // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as StreamingMode,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,joinUrl: freezed == joinUrl ? _self.joinUrl : joinUrl // ignore: cast_nullable_to_non_nullable
as String?,hostAddress: freezed == hostAddress ? _self.hostAddress : hostAddress // ignore: cast_nullable_to_non_nullable
as String?,hostPort: freezed == hostPort ? _self.hostPort : hostPort // ignore: cast_nullable_to_non_nullable
as int?,serverUrl: freezed == serverUrl ? _self.serverUrl : serverUrl // ignore: cast_nullable_to_non_nullable
as String?,pin: freezed == pin ? _self.pin : pin // ignore: cast_nullable_to_non_nullable
as String?,pinProtected: null == pinProtected ? _self.pinProtected : pinProtected // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [JoinQrPayload].
extension JoinQrPayloadPatterns on JoinQrPayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JoinQrPayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JoinQrPayload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JoinQrPayload value)  $default,){
final _that = this;
switch (_that) {
case _JoinQrPayload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JoinQrPayload value)?  $default,){
final _that = this;
switch (_that) {
case _JoinQrPayload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String app,  int version, @JsonKey(fromJson: streamingModeFromJson, toJson: streamingModeToJson)  StreamingMode mode,  String roomId,  String? joinUrl,  String? hostAddress,  int? hostPort,  String? serverUrl,  String? pin,  bool pinProtected)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JoinQrPayload() when $default != null:
return $default(_that.app,_that.version,_that.mode,_that.roomId,_that.joinUrl,_that.hostAddress,_that.hostPort,_that.serverUrl,_that.pin,_that.pinProtected);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String app,  int version, @JsonKey(fromJson: streamingModeFromJson, toJson: streamingModeToJson)  StreamingMode mode,  String roomId,  String? joinUrl,  String? hostAddress,  int? hostPort,  String? serverUrl,  String? pin,  bool pinProtected)  $default,) {final _that = this;
switch (_that) {
case _JoinQrPayload():
return $default(_that.app,_that.version,_that.mode,_that.roomId,_that.joinUrl,_that.hostAddress,_that.hostPort,_that.serverUrl,_that.pin,_that.pinProtected);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String app,  int version, @JsonKey(fromJson: streamingModeFromJson, toJson: streamingModeToJson)  StreamingMode mode,  String roomId,  String? joinUrl,  String? hostAddress,  int? hostPort,  String? serverUrl,  String? pin,  bool pinProtected)?  $default,) {final _that = this;
switch (_that) {
case _JoinQrPayload() when $default != null:
return $default(_that.app,_that.version,_that.mode,_that.roomId,_that.joinUrl,_that.hostAddress,_that.hostPort,_that.serverUrl,_that.pin,_that.pinProtected);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _JoinQrPayload implements JoinQrPayload {
  const _JoinQrPayload({this.app = 'syncwave', this.version = 1, @JsonKey(fromJson: streamingModeFromJson, toJson: streamingModeToJson) required this.mode, required this.roomId, this.joinUrl, this.hostAddress, this.hostPort, this.serverUrl, this.pin, this.pinProtected = false});
  factory _JoinQrPayload.fromJson(Map<String, dynamic> json) => _$JoinQrPayloadFromJson(json);

@override@JsonKey() final  String app;
@override@JsonKey() final  int version;
@override@JsonKey(fromJson: streamingModeFromJson, toJson: streamingModeToJson) final  StreamingMode mode;
@override final  String roomId;
@override final  String? joinUrl;
@override final  String? hostAddress;
@override final  int? hostPort;
@override final  String? serverUrl;
@override final  String? pin;
@override@JsonKey() final  bool pinProtected;

/// Create a copy of JoinQrPayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JoinQrPayloadCopyWith<_JoinQrPayload> get copyWith => __$JoinQrPayloadCopyWithImpl<_JoinQrPayload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JoinQrPayloadToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JoinQrPayload&&(identical(other.app, app) || other.app == app)&&(identical(other.version, version) || other.version == version)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.joinUrl, joinUrl) || other.joinUrl == joinUrl)&&(identical(other.hostAddress, hostAddress) || other.hostAddress == hostAddress)&&(identical(other.hostPort, hostPort) || other.hostPort == hostPort)&&(identical(other.serverUrl, serverUrl) || other.serverUrl == serverUrl)&&(identical(other.pin, pin) || other.pin == pin)&&(identical(other.pinProtected, pinProtected) || other.pinProtected == pinProtected));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,app,version,mode,roomId,joinUrl,hostAddress,hostPort,serverUrl,pin,pinProtected);

@override
String toString() {
  return 'JoinQrPayload(app: $app, version: $version, mode: $mode, roomId: $roomId, joinUrl: $joinUrl, hostAddress: $hostAddress, hostPort: $hostPort, serverUrl: $serverUrl, pin: $pin, pinProtected: $pinProtected)';
}


}

/// @nodoc
abstract mixin class _$JoinQrPayloadCopyWith<$Res> implements $JoinQrPayloadCopyWith<$Res> {
  factory _$JoinQrPayloadCopyWith(_JoinQrPayload value, $Res Function(_JoinQrPayload) _then) = __$JoinQrPayloadCopyWithImpl;
@override @useResult
$Res call({
 String app, int version,@JsonKey(fromJson: streamingModeFromJson, toJson: streamingModeToJson) StreamingMode mode, String roomId, String? joinUrl, String? hostAddress, int? hostPort, String? serverUrl, String? pin, bool pinProtected
});




}
/// @nodoc
class __$JoinQrPayloadCopyWithImpl<$Res>
    implements _$JoinQrPayloadCopyWith<$Res> {
  __$JoinQrPayloadCopyWithImpl(this._self, this._then);

  final _JoinQrPayload _self;
  final $Res Function(_JoinQrPayload) _then;

/// Create a copy of JoinQrPayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? app = null,Object? version = null,Object? mode = null,Object? roomId = null,Object? joinUrl = freezed,Object? hostAddress = freezed,Object? hostPort = freezed,Object? serverUrl = freezed,Object? pin = freezed,Object? pinProtected = null,}) {
  return _then(_JoinQrPayload(
app: null == app ? _self.app : app // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as StreamingMode,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,joinUrl: freezed == joinUrl ? _self.joinUrl : joinUrl // ignore: cast_nullable_to_non_nullable
as String?,hostAddress: freezed == hostAddress ? _self.hostAddress : hostAddress // ignore: cast_nullable_to_non_nullable
as String?,hostPort: freezed == hostPort ? _self.hostPort : hostPort // ignore: cast_nullable_to_non_nullable
as int?,serverUrl: freezed == serverUrl ? _self.serverUrl : serverUrl // ignore: cast_nullable_to_non_nullable
as String?,pin: freezed == pin ? _self.pin : pin // ignore: cast_nullable_to_non_nullable
as String?,pinProtected: null == pinProtected ? _self.pinProtected : pinProtected // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
