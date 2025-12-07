import 'package:dash_board/src/events/event.dart';
import 'package:dash_board/src/model/model.dart';

/// Event fired when a model is about to be created (before save).
///
/// This event is dispatched before the model is inserted into the database.
/// Listeners can use this to:
/// - Validate data before insertion
/// - Set default values
/// - Log creation attempts
///
/// Example:
/// ```dart
/// dispatcher.listen<ModelCreatingEvent>((event) {
///   print('About to create ${event.model.table} record');
/// });
/// ```
class ModelCreatingEvent extends Event {
  /// The model being created.
  final Model model;

  ModelCreatingEvent(this.model);

  @override
  String get name => '${model.table}.creating';

  @override
  Map<String, dynamic> toPayload() => {'table': model.table, 'data': model.toMap()};
}

/// Event fired after a model is created.
///
/// This event is dispatched after the model is successfully inserted
/// into the database and has received its primary key.
///
/// Example:
/// ```dart
/// dispatcher.listen<ModelCreatedEvent>((event) {
///   print('Created ${event.model.table} with ID: ${event.model.getKey()}');
/// });
/// ```
class ModelCreatedEvent extends Event {
  /// The model that was created.
  final Model model;

  /// Optional user ID who caused this event.
  final dynamic causerId;

  ModelCreatedEvent(this.model, {this.causerId});

  @override
  String get name => '${model.table}.created';

  @override
  bool get broadcastToFrontend => true;

  @override
  Map<String, dynamic> toPayload() => {
    'table': model.table,
    'id': model.getKey(),
    'data': model.toMap(),
    if (causerId != null) 'causer_id': causerId,
  };
}

/// Event fired when a model is about to be updated (with before state).
///
/// This event captures the state of the model before the update,
/// allowing listeners to compare before/after values.
///
/// Example:
/// ```dart
/// dispatcher.listen<ModelUpdatingEvent>((event) {
///   print('Before update: ${event.beforeState}');
///   print('After update: ${event.model.toMap()}');
/// });
/// ```
class ModelUpdatingEvent extends Event {
  /// The model being updated.
  final Model model;

  /// The state of the model before the update.
  final Map<String, dynamic> beforeState;

  ModelUpdatingEvent(this.model, this.beforeState);

  @override
  String get name => '${model.table}.updating';

  @override
  Map<String, dynamic> toPayload() => {
    'table': model.table,
    'id': model.getKey(),
    'before': beforeState,
    'after': model.toMap(),
  };

  /// Computes the changes between before and after state.
  Map<String, dynamic> getChanges() {
    final after = model.toMap();
    final changes = <String, dynamic>{};

    for (final key in after.keys) {
      final beforeValue = beforeState[key];
      final afterValue = after[key];

      if (beforeValue != afterValue) {
        changes[key] = {'before': beforeValue, 'after': afterValue};
      }
    }

    return changes;
  }
}

/// Event fired after a model is updated.
///
/// This event includes the computed changes between the before
/// and after state for easy access.
///
/// Example:
/// ```dart
/// dispatcher.listen<ModelUpdatedEvent>((event) {
///   print('Updated ${event.model.table}');
///   if (event.changes != null) {
///     print('Changes: ${event.changes}');
///   }
/// });
/// ```
class ModelUpdatedEvent extends Event {
  /// The model that was updated.
  final Model model;

  /// The changes that were made (field -> {before, after}).
  final Map<String, dynamic>? changes;

  /// The state before the update.
  final Map<String, dynamic>? beforeState;

  /// Optional user ID who caused this event.
  final dynamic causerId;

  ModelUpdatedEvent(this.model, {this.changes, this.beforeState, this.causerId});

  @override
  String get name => '${model.table}.updated';

  @override
  bool get broadcastToFrontend => true;

  @override
  Map<String, dynamic> toPayload() => {
    'table': model.table,
    'id': model.getKey(),
    'data': model.toMap(),
    if (changes != null) 'changes': changes,
    if (beforeState != null) 'before': beforeState,
    if (causerId != null) 'causer_id': causerId,
  };
}

/// Event fired when a model is about to be deleted.
///
/// This event is dispatched before the model is removed from the database.
/// Listeners can use this to:
/// - Prevent deletion based on business rules
/// - Clean up related data
/// - Log deletion attempts
///
/// Example:
/// ```dart
/// dispatcher.listen<ModelDeletingEvent>((event) {
///   print('About to delete ${event.model.table} ID: ${event.model.getKey()}');
/// });
/// ```
class ModelDeletingEvent extends Event {
  /// The model being deleted.
  final Model model;

  ModelDeletingEvent(this.model);

  @override
  String get name => '${model.table}.deleting';

  @override
  Map<String, dynamic> toPayload() => {'table': model.table, 'id': model.getKey(), 'data': model.toMap()};
}

/// Event fired after a model is deleted.
///
/// This event includes the data of the deleted record for audit purposes.
///
/// Example:
/// ```dart
/// dispatcher.listen<ModelDeletedEvent>((event) {
///   print('Deleted ${event.table} ID: ${event.modelId}');
///   print('Deleted data: ${event.deletedData}');
/// });
/// ```
class ModelDeletedEvent extends Event {
  /// The table name of the deleted model.
  final String table;

  /// The ID of the deleted model.
  final dynamic modelId;

  /// The data of the model at the time of deletion.
  final Map<String, dynamic> deletedData;

  /// The model type name (e.g., 'User', 'Post').
  final String modelType;

  /// Optional user ID who caused this event.
  final dynamic causerId;

  ModelDeletedEvent({
    required this.table,
    required this.modelId,
    required this.deletedData,
    required this.modelType,
    this.causerId,
  });

  /// Creates a ModelDeletedEvent from a model before it's deleted.
  factory ModelDeletedEvent.fromModel(Model model, {dynamic causerId}) {
    return ModelDeletedEvent(
      table: model.table,
      modelId: model.getKey(),
      deletedData: model.toMap(),
      modelType: model.runtimeType.toString(),
      causerId: causerId,
    );
  }

  @override
  String get name => '$table.deleted';

  @override
  bool get broadcastToFrontend => true;

  @override
  Map<String, dynamic> toPayload() => {
    'table': table,
    'id': modelId,
    'data': deletedData,
    'model_type': modelType,
    if (causerId != null) 'causer_id': causerId,
  };
}

/// Event fired after a model is saved (created or updated).
///
/// This is a convenience event that fires after both create and update
/// operations. Use this when you need to respond to any save operation.
///
/// Example:
/// ```dart
/// dispatcher.listen<ModelSavedEvent>((event) {
///   print('Model saved: ${event.model.table}');
///   print('Was creating: ${event.wasCreating}');
/// });
/// ```
class ModelSavedEvent extends Event {
  /// The model that was saved.
  final Model model;

  /// Whether this was a create operation (vs update).
  final bool wasCreating;

  /// Optional user ID who caused this event.
  final dynamic causerId;

  ModelSavedEvent(this.model, {required this.wasCreating, this.causerId});

  @override
  String get name => '${model.table}.saved';

  @override
  bool get broadcastToFrontend => true;

  @override
  Map<String, dynamic> toPayload() => {
    'table': model.table,
    'id': model.getKey(),
    'data': model.toMap(),
    'was_creating': wasCreating,
    if (causerId != null) 'causer_id': causerId,
  };
}
