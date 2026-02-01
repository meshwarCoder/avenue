// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ai_action_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
AiAction _$AiActionFromJson(
  Map<String, dynamic> json
) {
        switch (json['type']) {
                  case 'createTask':
          return CreateTaskAction.fromJson(
            json
          );
                case 'updateTask':
          return UpdateTaskAction.fromJson(
            json
          );
                case 'deleteTask':
          return DeleteTaskAction.fromJson(
            json
          );
                case 'reorderDay':
          return ReorderDayAction.fromJson(
            json
          );
                case 'updateSettings':
          return UpdateSettingsAction.fromJson(
            json
          );
                case 'unknown':
          return UnknownAction.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'type',
  'AiAction',
  'Invalid union type "${json['type']}"!'
);
        }
      
}

/// @nodoc
mixin _$AiAction {



  /// Serializes this AiAction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AiAction);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AiAction()';
}


}

/// @nodoc
class $AiActionCopyWith<$Res>  {
$AiActionCopyWith(AiAction _, $Res Function(AiAction) __);
}


/// Adds pattern-matching-related methods to [AiAction].
extension AiActionPatterns on AiAction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CreateTaskAction value)?  createTask,TResult Function( UpdateTaskAction value)?  updateTask,TResult Function( DeleteTaskAction value)?  deleteTask,TResult Function( ReorderDayAction value)?  reorderDay,TResult Function( UpdateSettingsAction value)?  updateSettings,TResult Function( UnknownAction value)?  unknown,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CreateTaskAction() when createTask != null:
return createTask(_that);case UpdateTaskAction() when updateTask != null:
return updateTask(_that);case DeleteTaskAction() when deleteTask != null:
return deleteTask(_that);case ReorderDayAction() when reorderDay != null:
return reorderDay(_that);case UpdateSettingsAction() when updateSettings != null:
return updateSettings(_that);case UnknownAction() when unknown != null:
return unknown(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CreateTaskAction value)  createTask,required TResult Function( UpdateTaskAction value)  updateTask,required TResult Function( DeleteTaskAction value)  deleteTask,required TResult Function( ReorderDayAction value)  reorderDay,required TResult Function( UpdateSettingsAction value)  updateSettings,required TResult Function( UnknownAction value)  unknown,}){
final _that = this;
switch (_that) {
case CreateTaskAction():
return createTask(_that);case UpdateTaskAction():
return updateTask(_that);case DeleteTaskAction():
return deleteTask(_that);case ReorderDayAction():
return reorderDay(_that);case UpdateSettingsAction():
return updateSettings(_that);case UnknownAction():
return unknown(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CreateTaskAction value)?  createTask,TResult? Function( UpdateTaskAction value)?  updateTask,TResult? Function( DeleteTaskAction value)?  deleteTask,TResult? Function( ReorderDayAction value)?  reorderDay,TResult? Function( UpdateSettingsAction value)?  updateSettings,TResult? Function( UnknownAction value)?  unknown,}){
final _that = this;
switch (_that) {
case CreateTaskAction() when createTask != null:
return createTask(_that);case UpdateTaskAction() when updateTask != null:
return updateTask(_that);case DeleteTaskAction() when deleteTask != null:
return deleteTask(_that);case ReorderDayAction() when reorderDay != null:
return reorderDay(_that);case UpdateSettingsAction() when updateSettings != null:
return updateSettings(_that);case UnknownAction() when unknown != null:
return unknown(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String name,  DateTime date,  String? startTime,  String? endTime,  String importance,  String? note)?  createTask,TResult Function( String id,  String? name,  DateTime? date,  String? startTime,  String? endTime,  String? importance,  String? note,  bool? isDone)?  updateTask,TResult Function( String id)?  deleteTask,TResult Function( DateTime date,  List<String> taskIdsInOrder)?  reorderDay,TResult Function( String? theme,  String? language,  bool? notificationsEnabled)?  updateSettings,TResult Function( String rawResponse)?  unknown,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CreateTaskAction() when createTask != null:
return createTask(_that.name,_that.date,_that.startTime,_that.endTime,_that.importance,_that.note);case UpdateTaskAction() when updateTask != null:
return updateTask(_that.id,_that.name,_that.date,_that.startTime,_that.endTime,_that.importance,_that.note,_that.isDone);case DeleteTaskAction() when deleteTask != null:
return deleteTask(_that.id);case ReorderDayAction() when reorderDay != null:
return reorderDay(_that.date,_that.taskIdsInOrder);case UpdateSettingsAction() when updateSettings != null:
return updateSettings(_that.theme,_that.language,_that.notificationsEnabled);case UnknownAction() when unknown != null:
return unknown(_that.rawResponse);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String name,  DateTime date,  String? startTime,  String? endTime,  String importance,  String? note)  createTask,required TResult Function( String id,  String? name,  DateTime? date,  String? startTime,  String? endTime,  String? importance,  String? note,  bool? isDone)  updateTask,required TResult Function( String id)  deleteTask,required TResult Function( DateTime date,  List<String> taskIdsInOrder)  reorderDay,required TResult Function( String? theme,  String? language,  bool? notificationsEnabled)  updateSettings,required TResult Function( String rawResponse)  unknown,}) {final _that = this;
switch (_that) {
case CreateTaskAction():
return createTask(_that.name,_that.date,_that.startTime,_that.endTime,_that.importance,_that.note);case UpdateTaskAction():
return updateTask(_that.id,_that.name,_that.date,_that.startTime,_that.endTime,_that.importance,_that.note,_that.isDone);case DeleteTaskAction():
return deleteTask(_that.id);case ReorderDayAction():
return reorderDay(_that.date,_that.taskIdsInOrder);case UpdateSettingsAction():
return updateSettings(_that.theme,_that.language,_that.notificationsEnabled);case UnknownAction():
return unknown(_that.rawResponse);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String name,  DateTime date,  String? startTime,  String? endTime,  String importance,  String? note)?  createTask,TResult? Function( String id,  String? name,  DateTime? date,  String? startTime,  String? endTime,  String? importance,  String? note,  bool? isDone)?  updateTask,TResult? Function( String id)?  deleteTask,TResult? Function( DateTime date,  List<String> taskIdsInOrder)?  reorderDay,TResult? Function( String? theme,  String? language,  bool? notificationsEnabled)?  updateSettings,TResult? Function( String rawResponse)?  unknown,}) {final _that = this;
switch (_that) {
case CreateTaskAction() when createTask != null:
return createTask(_that.name,_that.date,_that.startTime,_that.endTime,_that.importance,_that.note);case UpdateTaskAction() when updateTask != null:
return updateTask(_that.id,_that.name,_that.date,_that.startTime,_that.endTime,_that.importance,_that.note,_that.isDone);case DeleteTaskAction() when deleteTask != null:
return deleteTask(_that.id);case ReorderDayAction() when reorderDay != null:
return reorderDay(_that.date,_that.taskIdsInOrder);case UpdateSettingsAction() when updateSettings != null:
return updateSettings(_that.theme,_that.language,_that.notificationsEnabled);case UnknownAction() when unknown != null:
return unknown(_that.rawResponse);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class CreateTaskAction implements AiAction {
  const CreateTaskAction({required this.name, required this.date, this.startTime, this.endTime, this.importance = 'Medium', this.note, final  String? $type}): $type = $type ?? 'createTask';
  factory CreateTaskAction.fromJson(Map<String, dynamic> json) => _$CreateTaskActionFromJson(json);

 final  String name;
 final  DateTime date;
 final  String? startTime;
 final  String? endTime;
@JsonKey() final  String importance;
 final  String? note;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of AiAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateTaskActionCopyWith<CreateTaskAction> get copyWith => _$CreateTaskActionCopyWithImpl<CreateTaskAction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CreateTaskActionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateTaskAction&&(identical(other.name, name) || other.name == name)&&(identical(other.date, date) || other.date == date)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.importance, importance) || other.importance == importance)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,date,startTime,endTime,importance,note);

@override
String toString() {
  return 'AiAction.createTask(name: $name, date: $date, startTime: $startTime, endTime: $endTime, importance: $importance, note: $note)';
}


}

/// @nodoc
abstract mixin class $CreateTaskActionCopyWith<$Res> implements $AiActionCopyWith<$Res> {
  factory $CreateTaskActionCopyWith(CreateTaskAction value, $Res Function(CreateTaskAction) _then) = _$CreateTaskActionCopyWithImpl;
@useResult
$Res call({
 String name, DateTime date, String? startTime, String? endTime, String importance, String? note
});




}
/// @nodoc
class _$CreateTaskActionCopyWithImpl<$Res>
    implements $CreateTaskActionCopyWith<$Res> {
  _$CreateTaskActionCopyWithImpl(this._self, this._then);

  final CreateTaskAction _self;
  final $Res Function(CreateTaskAction) _then;

/// Create a copy of AiAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? name = null,Object? date = null,Object? startTime = freezed,Object? endTime = freezed,Object? importance = null,Object? note = freezed,}) {
  return _then(CreateTaskAction(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,startTime: freezed == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as String?,endTime: freezed == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as String?,importance: null == importance ? _self.importance : importance // ignore: cast_nullable_to_non_nullable
as String,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class UpdateTaskAction implements AiAction {
  const UpdateTaskAction({required this.id, this.name, this.date, this.startTime, this.endTime, this.importance, this.note, this.isDone, final  String? $type}): $type = $type ?? 'updateTask';
  factory UpdateTaskAction.fromJson(Map<String, dynamic> json) => _$UpdateTaskActionFromJson(json);

 final  String id;
 final  String? name;
 final  DateTime? date;
 final  String? startTime;
 final  String? endTime;
 final  String? importance;
 final  String? note;
 final  bool? isDone;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of AiAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateTaskActionCopyWith<UpdateTaskAction> get copyWith => _$UpdateTaskActionCopyWithImpl<UpdateTaskAction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UpdateTaskActionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateTaskAction&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.date, date) || other.date == date)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.importance, importance) || other.importance == importance)&&(identical(other.note, note) || other.note == note)&&(identical(other.isDone, isDone) || other.isDone == isDone));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,date,startTime,endTime,importance,note,isDone);

@override
String toString() {
  return 'AiAction.updateTask(id: $id, name: $name, date: $date, startTime: $startTime, endTime: $endTime, importance: $importance, note: $note, isDone: $isDone)';
}


}

/// @nodoc
abstract mixin class $UpdateTaskActionCopyWith<$Res> implements $AiActionCopyWith<$Res> {
  factory $UpdateTaskActionCopyWith(UpdateTaskAction value, $Res Function(UpdateTaskAction) _then) = _$UpdateTaskActionCopyWithImpl;
@useResult
$Res call({
 String id, String? name, DateTime? date, String? startTime, String? endTime, String? importance, String? note, bool? isDone
});




}
/// @nodoc
class _$UpdateTaskActionCopyWithImpl<$Res>
    implements $UpdateTaskActionCopyWith<$Res> {
  _$UpdateTaskActionCopyWithImpl(this._self, this._then);

  final UpdateTaskAction _self;
  final $Res Function(UpdateTaskAction) _then;

/// Create a copy of AiAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = freezed,Object? date = freezed,Object? startTime = freezed,Object? endTime = freezed,Object? importance = freezed,Object? note = freezed,Object? isDone = freezed,}) {
  return _then(UpdateTaskAction(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,date: freezed == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime?,startTime: freezed == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as String?,endTime: freezed == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as String?,importance: freezed == importance ? _self.importance : importance // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,isDone: freezed == isDone ? _self.isDone : isDone // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class DeleteTaskAction implements AiAction {
  const DeleteTaskAction({required this.id, final  String? $type}): $type = $type ?? 'deleteTask';
  factory DeleteTaskAction.fromJson(Map<String, dynamic> json) => _$DeleteTaskActionFromJson(json);

 final  String id;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of AiAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeleteTaskActionCopyWith<DeleteTaskAction> get copyWith => _$DeleteTaskActionCopyWithImpl<DeleteTaskAction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DeleteTaskActionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeleteTaskAction&&(identical(other.id, id) || other.id == id));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id);

@override
String toString() {
  return 'AiAction.deleteTask(id: $id)';
}


}

/// @nodoc
abstract mixin class $DeleteTaskActionCopyWith<$Res> implements $AiActionCopyWith<$Res> {
  factory $DeleteTaskActionCopyWith(DeleteTaskAction value, $Res Function(DeleteTaskAction) _then) = _$DeleteTaskActionCopyWithImpl;
@useResult
$Res call({
 String id
});




}
/// @nodoc
class _$DeleteTaskActionCopyWithImpl<$Res>
    implements $DeleteTaskActionCopyWith<$Res> {
  _$DeleteTaskActionCopyWithImpl(this._self, this._then);

  final DeleteTaskAction _self;
  final $Res Function(DeleteTaskAction) _then;

/// Create a copy of AiAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,}) {
  return _then(DeleteTaskAction(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class ReorderDayAction implements AiAction {
  const ReorderDayAction({required this.date, required final  List<String> taskIdsInOrder, final  String? $type}): _taskIdsInOrder = taskIdsInOrder,$type = $type ?? 'reorderDay';
  factory ReorderDayAction.fromJson(Map<String, dynamic> json) => _$ReorderDayActionFromJson(json);

 final  DateTime date;
 final  List<String> _taskIdsInOrder;
 List<String> get taskIdsInOrder {
  if (_taskIdsInOrder is EqualUnmodifiableListView) return _taskIdsInOrder;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_taskIdsInOrder);
}


@JsonKey(name: 'type')
final String $type;


/// Create a copy of AiAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReorderDayActionCopyWith<ReorderDayAction> get copyWith => _$ReorderDayActionCopyWithImpl<ReorderDayAction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReorderDayActionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReorderDayAction&&(identical(other.date, date) || other.date == date)&&const DeepCollectionEquality().equals(other._taskIdsInOrder, _taskIdsInOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,const DeepCollectionEquality().hash(_taskIdsInOrder));

@override
String toString() {
  return 'AiAction.reorderDay(date: $date, taskIdsInOrder: $taskIdsInOrder)';
}


}

/// @nodoc
abstract mixin class $ReorderDayActionCopyWith<$Res> implements $AiActionCopyWith<$Res> {
  factory $ReorderDayActionCopyWith(ReorderDayAction value, $Res Function(ReorderDayAction) _then) = _$ReorderDayActionCopyWithImpl;
@useResult
$Res call({
 DateTime date, List<String> taskIdsInOrder
});




}
/// @nodoc
class _$ReorderDayActionCopyWithImpl<$Res>
    implements $ReorderDayActionCopyWith<$Res> {
  _$ReorderDayActionCopyWithImpl(this._self, this._then);

  final ReorderDayAction _self;
  final $Res Function(ReorderDayAction) _then;

/// Create a copy of AiAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? date = null,Object? taskIdsInOrder = null,}) {
  return _then(ReorderDayAction(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,taskIdsInOrder: null == taskIdsInOrder ? _self._taskIdsInOrder : taskIdsInOrder // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc
@JsonSerializable()

class UpdateSettingsAction implements AiAction {
  const UpdateSettingsAction({this.theme, this.language, this.notificationsEnabled, final  String? $type}): $type = $type ?? 'updateSettings';
  factory UpdateSettingsAction.fromJson(Map<String, dynamic> json) => _$UpdateSettingsActionFromJson(json);

 final  String? theme;
 final  String? language;
 final  bool? notificationsEnabled;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of AiAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateSettingsActionCopyWith<UpdateSettingsAction> get copyWith => _$UpdateSettingsActionCopyWithImpl<UpdateSettingsAction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UpdateSettingsActionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateSettingsAction&&(identical(other.theme, theme) || other.theme == theme)&&(identical(other.language, language) || other.language == language)&&(identical(other.notificationsEnabled, notificationsEnabled) || other.notificationsEnabled == notificationsEnabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,theme,language,notificationsEnabled);

@override
String toString() {
  return 'AiAction.updateSettings(theme: $theme, language: $language, notificationsEnabled: $notificationsEnabled)';
}


}

/// @nodoc
abstract mixin class $UpdateSettingsActionCopyWith<$Res> implements $AiActionCopyWith<$Res> {
  factory $UpdateSettingsActionCopyWith(UpdateSettingsAction value, $Res Function(UpdateSettingsAction) _then) = _$UpdateSettingsActionCopyWithImpl;
@useResult
$Res call({
 String? theme, String? language, bool? notificationsEnabled
});




}
/// @nodoc
class _$UpdateSettingsActionCopyWithImpl<$Res>
    implements $UpdateSettingsActionCopyWith<$Res> {
  _$UpdateSettingsActionCopyWithImpl(this._self, this._then);

  final UpdateSettingsAction _self;
  final $Res Function(UpdateSettingsAction) _then;

/// Create a copy of AiAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? theme = freezed,Object? language = freezed,Object? notificationsEnabled = freezed,}) {
  return _then(UpdateSettingsAction(
theme: freezed == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as String?,language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String?,notificationsEnabled: freezed == notificationsEnabled ? _self.notificationsEnabled : notificationsEnabled // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class UnknownAction implements AiAction {
  const UnknownAction({required this.rawResponse, final  String? $type}): $type = $type ?? 'unknown';
  factory UnknownAction.fromJson(Map<String, dynamic> json) => _$UnknownActionFromJson(json);

 final  String rawResponse;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of AiAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnknownActionCopyWith<UnknownAction> get copyWith => _$UnknownActionCopyWithImpl<UnknownAction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UnknownActionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnknownAction&&(identical(other.rawResponse, rawResponse) || other.rawResponse == rawResponse));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rawResponse);

@override
String toString() {
  return 'AiAction.unknown(rawResponse: $rawResponse)';
}


}

/// @nodoc
abstract mixin class $UnknownActionCopyWith<$Res> implements $AiActionCopyWith<$Res> {
  factory $UnknownActionCopyWith(UnknownAction value, $Res Function(UnknownAction) _then) = _$UnknownActionCopyWithImpl;
@useResult
$Res call({
 String rawResponse
});




}
/// @nodoc
class _$UnknownActionCopyWithImpl<$Res>
    implements $UnknownActionCopyWith<$Res> {
  _$UnknownActionCopyWithImpl(this._self, this._then);

  final UnknownAction _self;
  final $Res Function(UnknownAction) _then;

/// Create a copy of AiAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? rawResponse = null,}) {
  return _then(UnknownAction(
rawResponse: null == rawResponse ? _self.rawResponse : rawResponse // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
