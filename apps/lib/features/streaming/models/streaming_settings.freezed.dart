// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'streaming_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StreamingSettings {

 bool get internetStreamingEnabled; String? get signalingServerUrl; bool get serverConnectionPinConfigured;
/// Create a copy of StreamingSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StreamingSettingsCopyWith<StreamingSettings> get copyWith => _$StreamingSettingsCopyWithImpl<StreamingSettings>(this as StreamingSettings, _$identity);

  /// Serializes this StreamingSettings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StreamingSettings&&(identical(other.internetStreamingEnabled, internetStreamingEnabled) || other.internetStreamingEnabled == internetStreamingEnabled)&&(identical(other.signalingServerUrl, signalingServerUrl) || other.signalingServerUrl == signalingServerUrl)&&(identical(other.serverConnectionPinConfigured, serverConnectionPinConfigured) || other.serverConnectionPinConfigured == serverConnectionPinConfigured));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,internetStreamingEnabled,signalingServerUrl,serverConnectionPinConfigured);

@override
String toString() {
  return 'StreamingSettings(internetStreamingEnabled: $internetStreamingEnabled, signalingServerUrl: $signalingServerUrl, serverConnectionPinConfigured: $serverConnectionPinConfigured)';
}


}

/// @nodoc
abstract mixin class $StreamingSettingsCopyWith<$Res>  {
  factory $StreamingSettingsCopyWith(StreamingSettings value, $Res Function(StreamingSettings) _then) = _$StreamingSettingsCopyWithImpl;
@useResult
$Res call({
 bool internetStreamingEnabled, String? signalingServerUrl, bool serverConnectionPinConfigured
});




}
/// @nodoc
class _$StreamingSettingsCopyWithImpl<$Res>
    implements $StreamingSettingsCopyWith<$Res> {
  _$StreamingSettingsCopyWithImpl(this._self, this._then);

  final StreamingSettings _self;
  final $Res Function(StreamingSettings) _then;

/// Create a copy of StreamingSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? internetStreamingEnabled = null,Object? signalingServerUrl = freezed,Object? serverConnectionPinConfigured = null,}) {
  return _then(_self.copyWith(
internetStreamingEnabled: null == internetStreamingEnabled ? _self.internetStreamingEnabled : internetStreamingEnabled // ignore: cast_nullable_to_non_nullable
as bool,signalingServerUrl: freezed == signalingServerUrl ? _self.signalingServerUrl : signalingServerUrl // ignore: cast_nullable_to_non_nullable
as String?,serverConnectionPinConfigured: null == serverConnectionPinConfigured ? _self.serverConnectionPinConfigured : serverConnectionPinConfigured // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [StreamingSettings].
extension StreamingSettingsPatterns on StreamingSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StreamingSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StreamingSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StreamingSettings value)  $default,){
final _that = this;
switch (_that) {
case _StreamingSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StreamingSettings value)?  $default,){
final _that = this;
switch (_that) {
case _StreamingSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool internetStreamingEnabled,  String? signalingServerUrl,  bool serverConnectionPinConfigured)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StreamingSettings() when $default != null:
return $default(_that.internetStreamingEnabled,_that.signalingServerUrl,_that.serverConnectionPinConfigured);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool internetStreamingEnabled,  String? signalingServerUrl,  bool serverConnectionPinConfigured)  $default,) {final _that = this;
switch (_that) {
case _StreamingSettings():
return $default(_that.internetStreamingEnabled,_that.signalingServerUrl,_that.serverConnectionPinConfigured);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool internetStreamingEnabled,  String? signalingServerUrl,  bool serverConnectionPinConfigured)?  $default,) {final _that = this;
switch (_that) {
case _StreamingSettings() when $default != null:
return $default(_that.internetStreamingEnabled,_that.signalingServerUrl,_that.serverConnectionPinConfigured);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StreamingSettings implements StreamingSettings {
  const _StreamingSettings({this.internetStreamingEnabled = false, this.signalingServerUrl, this.serverConnectionPinConfigured = false});
  factory _StreamingSettings.fromJson(Map<String, dynamic> json) => _$StreamingSettingsFromJson(json);

@override@JsonKey() final  bool internetStreamingEnabled;
@override final  String? signalingServerUrl;
@override@JsonKey() final  bool serverConnectionPinConfigured;

/// Create a copy of StreamingSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StreamingSettingsCopyWith<_StreamingSettings> get copyWith => __$StreamingSettingsCopyWithImpl<_StreamingSettings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StreamingSettingsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StreamingSettings&&(identical(other.internetStreamingEnabled, internetStreamingEnabled) || other.internetStreamingEnabled == internetStreamingEnabled)&&(identical(other.signalingServerUrl, signalingServerUrl) || other.signalingServerUrl == signalingServerUrl)&&(identical(other.serverConnectionPinConfigured, serverConnectionPinConfigured) || other.serverConnectionPinConfigured == serverConnectionPinConfigured));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,internetStreamingEnabled,signalingServerUrl,serverConnectionPinConfigured);

@override
String toString() {
  return 'StreamingSettings(internetStreamingEnabled: $internetStreamingEnabled, signalingServerUrl: $signalingServerUrl, serverConnectionPinConfigured: $serverConnectionPinConfigured)';
}


}

/// @nodoc
abstract mixin class _$StreamingSettingsCopyWith<$Res> implements $StreamingSettingsCopyWith<$Res> {
  factory _$StreamingSettingsCopyWith(_StreamingSettings value, $Res Function(_StreamingSettings) _then) = __$StreamingSettingsCopyWithImpl;
@override @useResult
$Res call({
 bool internetStreamingEnabled, String? signalingServerUrl, bool serverConnectionPinConfigured
});




}
/// @nodoc
class __$StreamingSettingsCopyWithImpl<$Res>
    implements _$StreamingSettingsCopyWith<$Res> {
  __$StreamingSettingsCopyWithImpl(this._self, this._then);

  final _StreamingSettings _self;
  final $Res Function(_StreamingSettings) _then;

/// Create a copy of StreamingSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? internetStreamingEnabled = null,Object? signalingServerUrl = freezed,Object? serverConnectionPinConfigured = null,}) {
  return _then(_StreamingSettings(
internetStreamingEnabled: null == internetStreamingEnabled ? _self.internetStreamingEnabled : internetStreamingEnabled // ignore: cast_nullable_to_non_nullable
as bool,signalingServerUrl: freezed == signalingServerUrl ? _self.signalingServerUrl : signalingServerUrl // ignore: cast_nullable_to_non_nullable
as String?,serverConnectionPinConfigured: null == serverConnectionPinConfigured ? _self.serverConnectionPinConfigured : serverConnectionPinConfigured // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
