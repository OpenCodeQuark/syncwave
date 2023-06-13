// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'room_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RoomSummary {

 String get roomId; String get roomName; bool get pinProtected; int get participantCount;
/// Create a copy of RoomSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoomSummaryCopyWith<RoomSummary> get copyWith => _$RoomSummaryCopyWithImpl<RoomSummary>(this as RoomSummary, _$identity);

  /// Serializes this RoomSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoomSummary&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.roomName, roomName) || other.roomName == roomName)&&(identical(other.pinProtected, pinProtected) || other.pinProtected == pinProtected)&&(identical(other.participantCount, participantCount) || other.participantCount == participantCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,roomId,roomName,pinProtected,participantCount);

@override
String toString() {
  return 'RoomSummary(roomId: $roomId, roomName: $roomName, pinProtected: $pinProtected, participantCount: $participantCount)';
}


}

/// @nodoc
abstract mixin class $RoomSummaryCopyWith<$Res>  {
  factory $RoomSummaryCopyWith(RoomSummary value, $Res Function(RoomSummary) _then) = _$RoomSummaryCopyWithImpl;
@useResult
$Res call({
 String roomId, String roomName, bool pinProtected, int participantCount
});




}
/// @nodoc
class _$RoomSummaryCopyWithImpl<$Res>
    implements $RoomSummaryCopyWith<$Res> {
  _$RoomSummaryCopyWithImpl(this._self, this._then);

  final RoomSummary _self;
  final $Res Function(RoomSummary) _then;

/// Create a copy of RoomSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? roomId = null,Object? roomName = null,Object? pinProtected = null,Object? participantCount = null,}) {
  return _then(_self.copyWith(
roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,roomName: null == roomName ? _self.roomName : roomName // ignore: cast_nullable_to_non_nullable
as String,pinProtected: null == pinProtected ? _self.pinProtected : pinProtected // ignore: cast_nullable_to_non_nullable
as bool,participantCount: null == participantCount ? _self.participantCount : participantCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [RoomSummary].
extension RoomSummaryPatterns on RoomSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RoomSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RoomSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RoomSummary value)  $default,){
final _that = this;
switch (_that) {
case _RoomSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RoomSummary value)?  $default,){
final _that = this;
switch (_that) {
case _RoomSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String roomId,  String roomName,  bool pinProtected,  int participantCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RoomSummary() when $default != null:
return $default(_that.roomId,_that.roomName,_that.pinProtected,_that.participantCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String roomId,  String roomName,  bool pinProtected,  int participantCount)  $default,) {final _that = this;
switch (_that) {
case _RoomSummary():
return $default(_that.roomId,_that.roomName,_that.pinProtected,_that.participantCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String roomId,  String roomName,  bool pinProtected,  int participantCount)?  $default,) {final _that = this;
switch (_that) {
case _RoomSummary() when $default != null:
return $default(_that.roomId,_that.roomName,_that.pinProtected,_that.participantCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RoomSummary implements RoomSummary {
  const _RoomSummary({required this.roomId, required this.roomName, required this.pinProtected, required this.participantCount});
  factory _RoomSummary.fromJson(Map<String, dynamic> json) => _$RoomSummaryFromJson(json);

@override final  String roomId;
@override final  String roomName;
@override final  bool pinProtected;
@override final  int participantCount;

/// Create a copy of RoomSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RoomSummaryCopyWith<_RoomSummary> get copyWith => __$RoomSummaryCopyWithImpl<_RoomSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RoomSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RoomSummary&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.roomName, roomName) || other.roomName == roomName)&&(identical(other.pinProtected, pinProtected) || other.pinProtected == pinProtected)&&(identical(other.participantCount, participantCount) || other.participantCount == participantCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,roomId,roomName,pinProtected,participantCount);

@override
String toString() {
  return 'RoomSummary(roomId: $roomId, roomName: $roomName, pinProtected: $pinProtected, participantCount: $participantCount)';
}


}

/// @nodoc
abstract mixin class _$RoomSummaryCopyWith<$Res> implements $RoomSummaryCopyWith<$Res> {
  factory _$RoomSummaryCopyWith(_RoomSummary value, $Res Function(_RoomSummary) _then) = __$RoomSummaryCopyWithImpl;
@override @useResult
$Res call({
 String roomId, String roomName, bool pinProtected, int participantCount
});




}
/// @nodoc
class __$RoomSummaryCopyWithImpl<$Res>
    implements _$RoomSummaryCopyWith<$Res> {
  __$RoomSummaryCopyWithImpl(this._self, this._then);

  final _RoomSummary _self;
  final $Res Function(_RoomSummary) _then;

/// Create a copy of RoomSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? roomId = null,Object? roomName = null,Object? pinProtected = null,Object? participantCount = null,}) {
  return _then(_RoomSummary(
roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,roomName: null == roomName ? _self.roomName : roomName // ignore: cast_nullable_to_non_nullable
as String,pinProtected: null == pinProtected ? _self.pinProtected : pinProtected // ignore: cast_nullable_to_non_nullable
as bool,participantCount: null == participantCount ? _self.participantCount : participantCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
