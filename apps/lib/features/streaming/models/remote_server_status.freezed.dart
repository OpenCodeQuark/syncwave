// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'remote_server_status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RemoteServerStatus {

 String? get normalizedWebSocketUrl; String? get statusUrl; bool get reachable; bool get isSyncWaveServer; bool get websocketConnected; bool get handshakeAccepted; bool get authenticationRequired; bool get authenticationFailed; String? get serverVersion; String? get protocolVersion; bool? get redisConnected; int? get activeRooms; int? get activeConnections; DateTime? get checkedAt; String? get message; String? get errorCode; RemoteServerConnectionState get state;
/// Create a copy of RemoteServerStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RemoteServerStatusCopyWith<RemoteServerStatus> get copyWith => _$RemoteServerStatusCopyWithImpl<RemoteServerStatus>(this as RemoteServerStatus, _$identity);

  /// Serializes this RemoteServerStatus to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RemoteServerStatus&&(identical(other.normalizedWebSocketUrl, normalizedWebSocketUrl) || other.normalizedWebSocketUrl == normalizedWebSocketUrl)&&(identical(other.statusUrl, statusUrl) || other.statusUrl == statusUrl)&&(identical(other.reachable, reachable) || other.reachable == reachable)&&(identical(other.isSyncWaveServer, isSyncWaveServer) || other.isSyncWaveServer == isSyncWaveServer)&&(identical(other.websocketConnected, websocketConnected) || other.websocketConnected == websocketConnected)&&(identical(other.handshakeAccepted, handshakeAccepted) || other.handshakeAccepted == handshakeAccepted)&&(identical(other.authenticationRequired, authenticationRequired) || other.authenticationRequired == authenticationRequired)&&(identical(other.authenticationFailed, authenticationFailed) || other.authenticationFailed == authenticationFailed)&&(identical(other.serverVersion, serverVersion) || other.serverVersion == serverVersion)&&(identical(other.protocolVersion, protocolVersion) || other.protocolVersion == protocolVersion)&&(identical(other.redisConnected, redisConnected) || other.redisConnected == redisConnected)&&(identical(other.activeRooms, activeRooms) || other.activeRooms == activeRooms)&&(identical(other.activeConnections, activeConnections) || other.activeConnections == activeConnections)&&(identical(other.checkedAt, checkedAt) || other.checkedAt == checkedAt)&&(identical(other.message, message) || other.message == message)&&(identical(other.errorCode, errorCode) || other.errorCode == errorCode)&&(identical(other.state, state) || other.state == state));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,normalizedWebSocketUrl,statusUrl,reachable,isSyncWaveServer,websocketConnected,handshakeAccepted,authenticationRequired,authenticationFailed,serverVersion,protocolVersion,redisConnected,activeRooms,activeConnections,checkedAt,message,errorCode,state);

@override
String toString() {
  return 'RemoteServerStatus(normalizedWebSocketUrl: $normalizedWebSocketUrl, statusUrl: $statusUrl, reachable: $reachable, isSyncWaveServer: $isSyncWaveServer, websocketConnected: $websocketConnected, handshakeAccepted: $handshakeAccepted, authenticationRequired: $authenticationRequired, authenticationFailed: $authenticationFailed, serverVersion: $serverVersion, protocolVersion: $protocolVersion, redisConnected: $redisConnected, activeRooms: $activeRooms, activeConnections: $activeConnections, checkedAt: $checkedAt, message: $message, errorCode: $errorCode, state: $state)';
}


}

/// @nodoc
abstract mixin class $RemoteServerStatusCopyWith<$Res>  {
  factory $RemoteServerStatusCopyWith(RemoteServerStatus value, $Res Function(RemoteServerStatus) _then) = _$RemoteServerStatusCopyWithImpl;
@useResult
$Res call({
 String? normalizedWebSocketUrl, String? statusUrl, bool reachable, bool isSyncWaveServer, bool websocketConnected, bool handshakeAccepted, bool authenticationRequired, bool authenticationFailed, String? serverVersion, String? protocolVersion, bool? redisConnected, int? activeRooms, int? activeConnections, DateTime? checkedAt, String? message, String? errorCode, RemoteServerConnectionState state
});




}
/// @nodoc
class _$RemoteServerStatusCopyWithImpl<$Res>
    implements $RemoteServerStatusCopyWith<$Res> {
  _$RemoteServerStatusCopyWithImpl(this._self, this._then);

  final RemoteServerStatus _self;
  final $Res Function(RemoteServerStatus) _then;

/// Create a copy of RemoteServerStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? normalizedWebSocketUrl = freezed,Object? statusUrl = freezed,Object? reachable = null,Object? isSyncWaveServer = null,Object? websocketConnected = null,Object? handshakeAccepted = null,Object? authenticationRequired = null,Object? authenticationFailed = null,Object? serverVersion = freezed,Object? protocolVersion = freezed,Object? redisConnected = freezed,Object? activeRooms = freezed,Object? activeConnections = freezed,Object? checkedAt = freezed,Object? message = freezed,Object? errorCode = freezed,Object? state = null,}) {
  return _then(_self.copyWith(
normalizedWebSocketUrl: freezed == normalizedWebSocketUrl ? _self.normalizedWebSocketUrl : normalizedWebSocketUrl // ignore: cast_nullable_to_non_nullable
as String?,statusUrl: freezed == statusUrl ? _self.statusUrl : statusUrl // ignore: cast_nullable_to_non_nullable
as String?,reachable: null == reachable ? _self.reachable : reachable // ignore: cast_nullable_to_non_nullable
as bool,isSyncWaveServer: null == isSyncWaveServer ? _self.isSyncWaveServer : isSyncWaveServer // ignore: cast_nullable_to_non_nullable
as bool,websocketConnected: null == websocketConnected ? _self.websocketConnected : websocketConnected // ignore: cast_nullable_to_non_nullable
as bool,handshakeAccepted: null == handshakeAccepted ? _self.handshakeAccepted : handshakeAccepted // ignore: cast_nullable_to_non_nullable
as bool,authenticationRequired: null == authenticationRequired ? _self.authenticationRequired : authenticationRequired // ignore: cast_nullable_to_non_nullable
as bool,authenticationFailed: null == authenticationFailed ? _self.authenticationFailed : authenticationFailed // ignore: cast_nullable_to_non_nullable
as bool,serverVersion: freezed == serverVersion ? _self.serverVersion : serverVersion // ignore: cast_nullable_to_non_nullable
as String?,protocolVersion: freezed == protocolVersion ? _self.protocolVersion : protocolVersion // ignore: cast_nullable_to_non_nullable
as String?,redisConnected: freezed == redisConnected ? _self.redisConnected : redisConnected // ignore: cast_nullable_to_non_nullable
as bool?,activeRooms: freezed == activeRooms ? _self.activeRooms : activeRooms // ignore: cast_nullable_to_non_nullable
as int?,activeConnections: freezed == activeConnections ? _self.activeConnections : activeConnections // ignore: cast_nullable_to_non_nullable
as int?,checkedAt: freezed == checkedAt ? _self.checkedAt : checkedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,errorCode: freezed == errorCode ? _self.errorCode : errorCode // ignore: cast_nullable_to_non_nullable
as String?,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as RemoteServerConnectionState,
  ));
}

}


/// Adds pattern-matching-related methods to [RemoteServerStatus].
extension RemoteServerStatusPatterns on RemoteServerStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RemoteServerStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RemoteServerStatus() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RemoteServerStatus value)  $default,){
final _that = this;
switch (_that) {
case _RemoteServerStatus():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RemoteServerStatus value)?  $default,){
final _that = this;
switch (_that) {
case _RemoteServerStatus() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? normalizedWebSocketUrl,  String? statusUrl,  bool reachable,  bool isSyncWaveServer,  bool websocketConnected,  bool handshakeAccepted,  bool authenticationRequired,  bool authenticationFailed,  String? serverVersion,  String? protocolVersion,  bool? redisConnected,  int? activeRooms,  int? activeConnections,  DateTime? checkedAt,  String? message,  String? errorCode,  RemoteServerConnectionState state)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RemoteServerStatus() when $default != null:
return $default(_that.normalizedWebSocketUrl,_that.statusUrl,_that.reachable,_that.isSyncWaveServer,_that.websocketConnected,_that.handshakeAccepted,_that.authenticationRequired,_that.authenticationFailed,_that.serverVersion,_that.protocolVersion,_that.redisConnected,_that.activeRooms,_that.activeConnections,_that.checkedAt,_that.message,_that.errorCode,_that.state);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? normalizedWebSocketUrl,  String? statusUrl,  bool reachable,  bool isSyncWaveServer,  bool websocketConnected,  bool handshakeAccepted,  bool authenticationRequired,  bool authenticationFailed,  String? serverVersion,  String? protocolVersion,  bool? redisConnected,  int? activeRooms,  int? activeConnections,  DateTime? checkedAt,  String? message,  String? errorCode,  RemoteServerConnectionState state)  $default,) {final _that = this;
switch (_that) {
case _RemoteServerStatus():
return $default(_that.normalizedWebSocketUrl,_that.statusUrl,_that.reachable,_that.isSyncWaveServer,_that.websocketConnected,_that.handshakeAccepted,_that.authenticationRequired,_that.authenticationFailed,_that.serverVersion,_that.protocolVersion,_that.redisConnected,_that.activeRooms,_that.activeConnections,_that.checkedAt,_that.message,_that.errorCode,_that.state);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? normalizedWebSocketUrl,  String? statusUrl,  bool reachable,  bool isSyncWaveServer,  bool websocketConnected,  bool handshakeAccepted,  bool authenticationRequired,  bool authenticationFailed,  String? serverVersion,  String? protocolVersion,  bool? redisConnected,  int? activeRooms,  int? activeConnections,  DateTime? checkedAt,  String? message,  String? errorCode,  RemoteServerConnectionState state)?  $default,) {final _that = this;
switch (_that) {
case _RemoteServerStatus() when $default != null:
return $default(_that.normalizedWebSocketUrl,_that.statusUrl,_that.reachable,_that.isSyncWaveServer,_that.websocketConnected,_that.handshakeAccepted,_that.authenticationRequired,_that.authenticationFailed,_that.serverVersion,_that.protocolVersion,_that.redisConnected,_that.activeRooms,_that.activeConnections,_that.checkedAt,_that.message,_that.errorCode,_that.state);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RemoteServerStatus implements RemoteServerStatus {
  const _RemoteServerStatus({this.normalizedWebSocketUrl, this.statusUrl, this.reachable = false, this.isSyncWaveServer = false, this.websocketConnected = false, this.handshakeAccepted = false, this.authenticationRequired = false, this.authenticationFailed = false, this.serverVersion, this.protocolVersion, this.redisConnected, this.activeRooms, this.activeConnections, this.checkedAt, this.message, this.errorCode, this.state = RemoteServerConnectionState.notConfigured});
  factory _RemoteServerStatus.fromJson(Map<String, dynamic> json) => _$RemoteServerStatusFromJson(json);

@override final  String? normalizedWebSocketUrl;
@override final  String? statusUrl;
@override@JsonKey() final  bool reachable;
@override@JsonKey() final  bool isSyncWaveServer;
@override@JsonKey() final  bool websocketConnected;
@override@JsonKey() final  bool handshakeAccepted;
@override@JsonKey() final  bool authenticationRequired;
@override@JsonKey() final  bool authenticationFailed;
@override final  String? serverVersion;
@override final  String? protocolVersion;
@override final  bool? redisConnected;
@override final  int? activeRooms;
@override final  int? activeConnections;
@override final  DateTime? checkedAt;
@override final  String? message;
@override final  String? errorCode;
@override@JsonKey() final  RemoteServerConnectionState state;

/// Create a copy of RemoteServerStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RemoteServerStatusCopyWith<_RemoteServerStatus> get copyWith => __$RemoteServerStatusCopyWithImpl<_RemoteServerStatus>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RemoteServerStatusToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RemoteServerStatus&&(identical(other.normalizedWebSocketUrl, normalizedWebSocketUrl) || other.normalizedWebSocketUrl == normalizedWebSocketUrl)&&(identical(other.statusUrl, statusUrl) || other.statusUrl == statusUrl)&&(identical(other.reachable, reachable) || other.reachable == reachable)&&(identical(other.isSyncWaveServer, isSyncWaveServer) || other.isSyncWaveServer == isSyncWaveServer)&&(identical(other.websocketConnected, websocketConnected) || other.websocketConnected == websocketConnected)&&(identical(other.handshakeAccepted, handshakeAccepted) || other.handshakeAccepted == handshakeAccepted)&&(identical(other.authenticationRequired, authenticationRequired) || other.authenticationRequired == authenticationRequired)&&(identical(other.authenticationFailed, authenticationFailed) || other.authenticationFailed == authenticationFailed)&&(identical(other.serverVersion, serverVersion) || other.serverVersion == serverVersion)&&(identical(other.protocolVersion, protocolVersion) || other.protocolVersion == protocolVersion)&&(identical(other.redisConnected, redisConnected) || other.redisConnected == redisConnected)&&(identical(other.activeRooms, activeRooms) || other.activeRooms == activeRooms)&&(identical(other.activeConnections, activeConnections) || other.activeConnections == activeConnections)&&(identical(other.checkedAt, checkedAt) || other.checkedAt == checkedAt)&&(identical(other.message, message) || other.message == message)&&(identical(other.errorCode, errorCode) || other.errorCode == errorCode)&&(identical(other.state, state) || other.state == state));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,normalizedWebSocketUrl,statusUrl,reachable,isSyncWaveServer,websocketConnected,handshakeAccepted,authenticationRequired,authenticationFailed,serverVersion,protocolVersion,redisConnected,activeRooms,activeConnections,checkedAt,message,errorCode,state);

@override
String toString() {
  return 'RemoteServerStatus(normalizedWebSocketUrl: $normalizedWebSocketUrl, statusUrl: $statusUrl, reachable: $reachable, isSyncWaveServer: $isSyncWaveServer, websocketConnected: $websocketConnected, handshakeAccepted: $handshakeAccepted, authenticationRequired: $authenticationRequired, authenticationFailed: $authenticationFailed, serverVersion: $serverVersion, protocolVersion: $protocolVersion, redisConnected: $redisConnected, activeRooms: $activeRooms, activeConnections: $activeConnections, checkedAt: $checkedAt, message: $message, errorCode: $errorCode, state: $state)';
}


}

/// @nodoc
abstract mixin class _$RemoteServerStatusCopyWith<$Res> implements $RemoteServerStatusCopyWith<$Res> {
  factory _$RemoteServerStatusCopyWith(_RemoteServerStatus value, $Res Function(_RemoteServerStatus) _then) = __$RemoteServerStatusCopyWithImpl;
@override @useResult
$Res call({
 String? normalizedWebSocketUrl, String? statusUrl, bool reachable, bool isSyncWaveServer, bool websocketConnected, bool handshakeAccepted, bool authenticationRequired, bool authenticationFailed, String? serverVersion, String? protocolVersion, bool? redisConnected, int? activeRooms, int? activeConnections, DateTime? checkedAt, String? message, String? errorCode, RemoteServerConnectionState state
});




}
/// @nodoc
class __$RemoteServerStatusCopyWithImpl<$Res>
    implements _$RemoteServerStatusCopyWith<$Res> {
  __$RemoteServerStatusCopyWithImpl(this._self, this._then);

  final _RemoteServerStatus _self;
  final $Res Function(_RemoteServerStatus) _then;

/// Create a copy of RemoteServerStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? normalizedWebSocketUrl = freezed,Object? statusUrl = freezed,Object? reachable = null,Object? isSyncWaveServer = null,Object? websocketConnected = null,Object? handshakeAccepted = null,Object? authenticationRequired = null,Object? authenticationFailed = null,Object? serverVersion = freezed,Object? protocolVersion = freezed,Object? redisConnected = freezed,Object? activeRooms = freezed,Object? activeConnections = freezed,Object? checkedAt = freezed,Object? message = freezed,Object? errorCode = freezed,Object? state = null,}) {
  return _then(_RemoteServerStatus(
normalizedWebSocketUrl: freezed == normalizedWebSocketUrl ? _self.normalizedWebSocketUrl : normalizedWebSocketUrl // ignore: cast_nullable_to_non_nullable
as String?,statusUrl: freezed == statusUrl ? _self.statusUrl : statusUrl // ignore: cast_nullable_to_non_nullable
as String?,reachable: null == reachable ? _self.reachable : reachable // ignore: cast_nullable_to_non_nullable
as bool,isSyncWaveServer: null == isSyncWaveServer ? _self.isSyncWaveServer : isSyncWaveServer // ignore: cast_nullable_to_non_nullable
as bool,websocketConnected: null == websocketConnected ? _self.websocketConnected : websocketConnected // ignore: cast_nullable_to_non_nullable
as bool,handshakeAccepted: null == handshakeAccepted ? _self.handshakeAccepted : handshakeAccepted // ignore: cast_nullable_to_non_nullable
as bool,authenticationRequired: null == authenticationRequired ? _self.authenticationRequired : authenticationRequired // ignore: cast_nullable_to_non_nullable
as bool,authenticationFailed: null == authenticationFailed ? _self.authenticationFailed : authenticationFailed // ignore: cast_nullable_to_non_nullable
as bool,serverVersion: freezed == serverVersion ? _self.serverVersion : serverVersion // ignore: cast_nullable_to_non_nullable
as String?,protocolVersion: freezed == protocolVersion ? _self.protocolVersion : protocolVersion // ignore: cast_nullable_to_non_nullable
as String?,redisConnected: freezed == redisConnected ? _self.redisConnected : redisConnected // ignore: cast_nullable_to_non_nullable
as bool?,activeRooms: freezed == activeRooms ? _self.activeRooms : activeRooms // ignore: cast_nullable_to_non_nullable
as int?,activeConnections: freezed == activeConnections ? _self.activeConnections : activeConnections // ignore: cast_nullable_to_non_nullable
as int?,checkedAt: freezed == checkedAt ? _self.checkedAt : checkedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,errorCode: freezed == errorCode ? _self.errorCode : errorCode // ignore: cast_nullable_to_non_nullable
as String?,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as RemoteServerConnectionState,
  ));
}


}

// dart format on
