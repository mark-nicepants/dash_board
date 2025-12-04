import 'package:collection/collection.dart';
import 'package:dash/src/context/request_context.dart';
import 'package:dash/src/database/database_connector.dart';
import 'package:dash/src/database/migrations/schema_definition.dart';
import 'package:dash/src/events/events.dart';
import 'package:dash/src/model/annotations.dart';
import 'package:dash/src/model/model_query_builder.dart';
import 'package:dash/src/model/soft_deletes.dart';
import 'package:dash/src/resource.dart';
import 'package:dash/src/service_locator.dart';
import 'package:dash/src/validation/validation.dart';

/// Base class for all Dash models.
///
/// Models represent database tables and provide an Eloquent-like API
/// for querying and manipulating data.
///
/// Example:
/// ```dart
/// class User extends Model {
///   @override
///   String get table => 'users';
///
///   int? id;
///   String? name;
///   String? email;
///
///   User({this.id, this.name, this.email});
///
///   @override
///   Map<String, dynamic> toMap() => {
///     if (id != null) 'id': id,
///     'name': name,
///     'email': email,
///   };
///
///   @override
///   void fromMap(Map<String, dynamic> map) {
///     id = map['id'] as int?;
///     name = map['name'] as String?;
///     email = map['email'] as String?;
///   }
/// }
///
/// // Usage:
/// final users = await User.query().where('role', 'admin').get();
/// final user = User(name: 'John', email: 'john@example.com');
/// await user.save();
/// ```
abstract class Model {
  /// The database connector instance.
  /// Must be set before using models.
  static DatabaseConnector? _connector;

  /// Sets the database connector for all models.
  static void setConnector(DatabaseConnector connector) {
    _connector = connector;
  }

  /// Gets the database connector.
  static DatabaseConnector get connector {
    if (_connector == null) {
      throw StateError('Database connector not set. Call Model.setConnector() first.');
    }
    return _connector!;
  }

  // ===== Automatic Timestamp Fields =====

  /// The timestamp when this model was created.
  /// Automatically populated when [timestamps] is true.
  DateTime? createdAt;

  /// The timestamp when this model was last updated.
  /// Automatically populated when [timestamps] is true.
  DateTime? updatedAt;

  /// The table name for this model.
  String get table;

  /// The primary key column name.
  String get primaryKey => 'id';

  /// Whether the primary key is auto-incrementing.
  bool get incrementing => true;

  /// Indicates if the model should timestamp (created_at, updated_at).
  bool get timestamps => true;

  /// The name of the "created at" column.
  String get createdAtColumn => 'created_at';

  /// The name of the "updated at" column.
  String get updatedAtColumn => 'updated_at';

  Resource get resource {
    throw UnimplementedError('Model.resource must be overridden in subclasses to return the associated Resource.');
  }

  TableSchema get schema {
    throw UnimplementedError('Model.schema must be overridden in subclasses to return the table schema.');
  }

  /// Gets the primary key value of this model instance.
  dynamic getKey();

  /// Sets the primary key value of this model instance.
  void setKey(dynamic value);

  /// Converts the model to a map for database operations.
  Map<String, dynamic> toMap();

  /// Populates the model from a database map.
  void fromMap(Map<String, dynamic> map);

  /// Returns a list of all database column names for this model.
  /// This is generated automatically by the @DashModel annotation.
  List<String> getFields();

  /// Stores loaded belongsTo/hasOne relationship models.
  final Map<String, Model> _loadedRelations = {};

  /// Stores loaded hasMany relationship lists.
  final Map<String, List<Model>> _loadedHasManyRelations = {};

  /// Stores loaded hasMany relationship IDs (for form pre-population).
  final Map<String, List<dynamic>> _loadedHasManyIds = {};

  /// Returns the value of a relationship by name.
  /// Override this in generated code to provide relationship access.
  /// Returns null if the relationship doesn't exist or isn't loaded.
  Model? getRelation(String name) => _loadedRelations[name];

  /// Sets a loaded relationship by name.
  void setRelation(String name, Model value) {
    _loadedRelations[name] = value;
  }

  /// Gets loaded hasMany relationship models.
  List<Model> getHasManyRelation(String name) => _loadedHasManyRelations[name] ?? [];

  /// Sets loaded hasMany relationship models.
  void setHasManyRelation(String name, List<Model> values) {
    _loadedHasManyRelations[name] = values;
  }

  /// Gets loaded hasMany relationship IDs.
  List<dynamic> getHasManyIds(String name) => _loadedHasManyIds[name] ?? [];

  /// Sets loaded hasMany relationship IDs.
  void setHasManyIds(String name, List<dynamic> values) {
    _loadedHasManyIds[name] = values;
  }

  /// Returns metadata about relationships defined on this model.
  /// Override this in generated code to provide relationship metadata.
  List<RelationshipMeta> getRelationships() => [];

  Future<T?> loadRelationship<T extends Model>(String relationName, dynamic relationId) async {
    final relationShipMeta = getRelationships().firstWhereOrNull((rel) => rel.name == relationName);
    if (relationShipMeta == null) {
      throw StateError('Relationship "$relationName" not defined on model $runtimeType.');
    }

    final cache = getRelation(relationName);
    if (cache != null) {
      return cache as T;
    }

    final resource = resourceFromSlug(relationShipMeta.relatedModelType) as Resource<T>;
    final relation = await resource.query().find(relationId);
    if (relation != null) {
      setRelation(relationName, relation);

      return relation;
    }

    return null;
  }

  // ===== HasMany Relationship Methods =====

  /// Gets the RelationshipMeta for a hasMany relationship by name.
  /// Throws if the relationship doesn't exist or isn't a hasMany type.
  RelationshipMeta _getHasManyMeta(String relationName) {
    final meta = getRelationships().firstWhereOrNull((rel) => rel.name == relationName);
    if (meta == null) {
      throw StateError('Relationship "$relationName" not defined on model $runtimeType.');
    }
    if (!meta.usesPivotTable) {
      throw StateError('Relationship "$relationName" is not a hasMany (pivot table) relationship.');
    }
    return meta;
  }

  /// Loads the IDs of related models for a hasMany relationship.
  /// Results are cached in [_loadedHasManyIds].
  Future<List<dynamic>> loadHasManyIds(String relationName) async {
    if (getKey() == null) return [];

    // Check cache first
    if (_loadedHasManyIds.containsKey(relationName)) {
      return _loadedHasManyIds[relationName]!;
    }

    final meta = _getHasManyMeta(relationName);
    final pivotTable = meta.pivotTable!;
    final localKey = meta.pivotLocalKey!;
    final relatedKey = meta.pivotRelatedKey!;

    final rows = await connector.query('SELECT $relatedKey FROM $pivotTable WHERE $localKey = ?', [getKey()]);

    final ids = rows.map((r) => r[relatedKey]).toList();
    _loadedHasManyIds[relationName] = ids;
    return ids;
  }

  /// Attaches related model IDs to this model via a hasMany pivot table.
  Future<void> attachMany(String relationName, List<dynamic> ids) async {
    if (getKey() == null) {
      throw StateError('Cannot attach relationships without a primary key.');
    }
    if (ids.isEmpty) return;

    final meta = _getHasManyMeta(relationName);
    final pivotTable = meta.pivotTable!;
    final localKey = meta.pivotLocalKey!;
    final relatedKey = meta.pivotRelatedKey!;

    for (final id in ids) {
      await connector.insert(pivotTable, {localKey: getKey(), relatedKey: id});
    }

    // Invalidate cache
    _loadedHasManyIds.remove(relationName);
  }

  /// Detaches related model IDs from this model via a hasMany pivot table.
  Future<void> detachMany(String relationName, List<dynamic> ids) async {
    if (getKey() == null) return;
    if (ids.isEmpty) return;

    final meta = _getHasManyMeta(relationName);
    final pivotTable = meta.pivotTable!;
    final localKey = meta.pivotLocalKey!;
    final relatedKey = meta.pivotRelatedKey!;

    for (final id in ids) {
      await connector.delete(pivotTable, where: '$localKey = ? AND $relatedKey = ?', whereArgs: [getKey(), id]);
    }

    // Invalidate cache
    _loadedHasManyIds.remove(relationName);
  }

  /// Syncs a hasMany relationship to exactly the given IDs.
  /// Removes relationships not in the list and adds missing ones.
  Future<void> syncMany(String relationName, List<dynamic> ids) async {
    if (getKey() == null) {
      throw StateError('Cannot sync relationships without a primary key.');
    }

    final meta = _getHasManyMeta(relationName);
    final pivotTable = meta.pivotTable!;
    final localKey = meta.pivotLocalKey!;
    final relatedKey = meta.pivotRelatedKey!;

    // Get existing related IDs
    final existingRows = await connector.query('SELECT $relatedKey FROM $pivotTable WHERE $localKey = ?', [getKey()]);
    final existingIds = existingRows.map((r) => r[relatedKey]).toSet();

    // Calculate changes
    final newIds = ids.toSet();
    final toDetach = existingIds.difference(newIds);
    final toAttach = newIds.difference(existingIds);

    // Apply changes
    if (toDetach.isNotEmpty) {
      await detachMany(relationName, toDetach.toList());
    }
    if (toAttach.isNotEmpty) {
      await attachMany(relationName, toAttach.toList());
    }

    // Update cache
    _loadedHasManyIds[relationName] = ids;
  }

  // ===== Helper Methods for Subclasses =====

  /// Safely gets a value from a map and casts it to the specified type.
  T? getFromMap<T>(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) return null;
    try {
      return value as T;
    } catch (e) {
      // Log warning in development
      return null;
    }
  }

  /// Parses a DateTime from various formats.
  /// Handles DateTime objects, ISO8601 strings, and null values.
  DateTime? parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  /// Parses a list from a map value.
  List<T> parseList<T>(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.cast<T>();
    return [];
  }

  /// Converts a Dart field name (camelCase) to database column name (snake_case).
  String toSnakeCase(String fieldName) {
    return fieldName.replaceAllMapped(RegExp(r'[A-Z]'), (match) => '_${match.group(0)!.toLowerCase()}');
  }

  /// Converts a database column name (snake_case) to Dart field name (camelCase).
  String toCamelCase(String columnName) {
    return columnName.replaceAllMapped(RegExp(r'_([a-z])'), (match) => match.group(1)!.toUpperCase());
  }

  // ===== Validation =====

  /// Validation rules for the model.
  /// Override this to define validation rules for your model.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Map<String, List<ValidationRule>> get rules => {
  ///   'email': [Required(), Email()],
  ///   'name': [Required(), MinLength(3)],
  ///   'age': [Numeric(), Min(18)],
  /// };
  /// ```
  Map<String, List<ValidationRule>> get rules => {};

  /// Validates the model against defined rules.
  /// Returns a map of field names to error messages.
  Map<String, List<String>> validate() {
    final errors = <String, List<String>>{};
    final data = toMap();

    rules.forEach((field, fieldRules) {
      final value = data[field];
      final fieldErrors = <String>[];

      for (final rule in fieldRules) {
        final error = rule.validate(field, value);
        if (error != null) {
          fieldErrors.add(error);
        }
      }

      if (fieldErrors.isNotEmpty) {
        errors[field] = fieldErrors;
      }
    });

    return errors;
  }

  /// Validates the model and throws an exception if validation fails.
  void validateOrFail() {
    final errors = validate();
    if (errors.isNotEmpty) {
      throw ValidationException(errors);
    }
  }

  // ===== Mass Assignment Protection =====

  /// List of attributes that are mass assignable.
  /// If empty, all attributes except guarded are fillable.
  List<String> get fillable => [];

  /// List of attributes that are not mass assignable.
  List<String> get guarded => [];

  /// Fills the model with the given attributes, respecting fillable/guarded.
  void fill(Map<String, dynamic> attributes) {
    final safeAttributes = <String, dynamic>{};

    for (final entry in attributes.entries) {
      final key = entry.key;

      // Check fillable whitelist
      if (fillable.isNotEmpty) {
        if (fillable.contains(key)) {
          safeAttributes[key] = entry.value;
        }
        continue;
      }

      // Check guarded blacklist
      if (!guarded.contains(key)) {
        safeAttributes[key] = entry.value;
      }
    }

    fromMap(safeAttributes);
  }

  // ===== Model Lifecycle Hooks =====

  /// Called before creating a new model.
  Future<void> onCreating() async {}

  /// Called after creating a new model.
  Future<void> onCreated() async {}

  /// Called before updating a model.
  Future<void> onUpdating() async {}

  /// Called after updating a model.
  Future<void> onUpdated() async {}

  /// Called before saving a model (create or update).
  Future<void> onSaving() async {}

  /// Called after saving a model (create or update).
  Future<void> onSaved() async {}

  /// Called before deleting a model.
  Future<void> onDeleting() async {}

  /// Called after deleting a model.
  Future<void> onDeleted() async {}

  /// Creates a new query builder for this model.
  static ModelQueryBuilder<T> query<T extends Model>() {
    return ModelQueryBuilder<T>(connector);
  }

  /// Finds a model by its primary key.
  static Future<T?> find<T extends Model>(dynamic id) async {
    return query<T>().find(id);
  }

  /// Gets all models from the table.
  static Future<List<T>> all<T extends Model>() async {
    return query<T>().get();
  }

  /// Creates a new model and saves it to the database.
  static Future<T> create<T extends Model>(T model, Map<String, dynamic> attributes) async {
    model.fromMap(attributes);
    await model.save();
    return model;
  }

  /// Dispatches an event with the current request's session ID attached.
  ///
  /// This method reads the session ID from the current [RequestContext] zone,
  /// ensuring that events are properly attributed to the user/session that
  /// caused them. This is critical for:
  /// - Session-scoped SSE broadcasting (events only go to the right user)
  /// - Activity logging (tracking who made changes)
  /// - Security (preventing cross-session data leakage)
  Future<void> _dispatchWithSession(Event event) async {
    await EventDispatcher.instance.dispatch(event, RequestContext.sessionId!);
  }

  /// Saves the model to the database.
  ///
  /// This method dispatches the following events:
  /// - [ModelCreatingEvent] / [ModelUpdatingEvent] before the operation
  /// - [ModelCreatedEvent] / [ModelUpdatedEvent] after the operation
  /// - [ModelSavedEvent] after any save operation
  Future<bool> save() async {
    await onSaving();

    final isCreating = getKey() == null;

    // Capture state before update for change tracking
    Map<String, dynamic>? beforeState;
    if (!isCreating) {
      beforeState = Map<String, dynamic>.from(toMap());
    }

    if (isCreating) {
      await _dispatchWithSession(ModelCreatingEvent(this));
      await onCreating();
    } else {
      await _dispatchWithSession(ModelUpdatingEvent(this, beforeState!));
      await onUpdating();
    }

    // Validate after lifecycle hooks (so defaults can be set)
    validateOrFail();

    final data = toMap();

    if (timestamps) {
      final now = DateTime.now();
      final nowIso = now.toIso8601String();
      if (isCreating) {
        data[createdAtColumn] = nowIso;
        createdAt = now;
      }
      data[updatedAtColumn] = nowIso;
      updatedAt = now;
    }

    if (isCreating) {
      // Insert
      final id = await connector.insert(table, data);
      if (incrementing) {
        setKey(id);
      }
      await onCreated();
      await onSaved();
      await _dispatchWithSession(ModelCreatedEvent(this));
      await _dispatchWithSession(ModelSavedEvent(this, wasCreating: true));
      return true;
    } else {
      // Update
      final updated = await connector.update(table, data, where: '$primaryKey = ?', whereArgs: [getKey()]);
      final success = updated > 0;
      if (success) {
        await onUpdated();
        await onSaved();

        // Compute changes for the event
        final changes = _computeChanges(beforeState!, toMap());
        await _dispatchWithSession(ModelUpdatedEvent(this, changes: changes, beforeState: beforeState));
        await _dispatchWithSession(ModelSavedEvent(this, wasCreating: false));
      }
      return success;
    }
  }

  /// Computes the differences between two maps.
  Map<String, dynamic> _computeChanges(Map<String, dynamic> before, Map<String, dynamic> after) {
    final changes = <String, dynamic>{};

    for (final key in after.keys) {
      final beforeValue = before[key];
      final afterValue = after[key];

      if (beforeValue != afterValue) {
        changes[key] = {'before': beforeValue, 'after': afterValue};
      }
    }

    return changes;
  }

  /// Deletes the model from the database.
  /// If the model uses SoftDeletes, performs a soft delete instead.
  ///
  /// This method dispatches the following events:
  /// - [ModelDeletingEvent] before the operation
  /// - [ModelDeletedEvent] after the operation
  Future<bool> delete() async {
    if (getKey() == null) {
      throw StateError('Cannot delete a model without a primary key value.');
    }

    // Check if this model uses soft deletes
    if (this is SoftDeletes) {
      return (this as dynamic).softDelete();
    }

    // Capture data before deletion for the event
    final deletedData = Map<String, dynamic>.from(toMap());
    final modelId = getKey();

    await _dispatchWithSession(ModelDeletingEvent(this));
    await onDeleting();

    final deleted = await connector.delete(table, where: '$primaryKey = ?', whereArgs: [getKey()]);

    final success = deleted > 0;
    if (success) {
      await onDeleted();
      await _dispatchWithSession(
        ModelDeletedEvent(table: table, modelId: modelId, deletedData: deletedData, modelType: runtimeType.toString()),
      );
    }
    return success;
  }

  /// Performs a soft delete (sets deleted_at timestamp).
  /// Only available if the model uses SoftDeletes mixin.
  ///
  /// This method dispatches the following events:
  /// - [ModelDeletingEvent] before the operation
  /// - [ModelDeletedEvent] after the operation
  Future<bool> softDelete() async {
    if (this is! SoftDeletes) {
      throw StateError('Model does not use SoftDeletes mixin.');
    }

    // Capture data before deletion for the event
    final deletedData = Map<String, dynamic>.from(toMap());
    final modelId = getKey();

    await _dispatchWithSession(ModelDeletingEvent(this));
    await onDeleting();

    final mixin = this as SoftDeletes;
    (this as dynamic).deletedAt = DateTime.now();

    final data = {mixin.deletedAtColumn: DateTime.now().toIso8601String()};
    final updated = await connector.update(table, data, where: '$primaryKey = ?', whereArgs: [getKey()]);

    final success = updated > 0;
    if (success) {
      await onDeleted();
      await _dispatchWithSession(
        ModelDeletedEvent(table: table, modelId: modelId, deletedData: deletedData, modelType: runtimeType.toString()),
      );
    }
    return success;
  }

  /// Restores a soft deleted model.
  Future<bool> restore() async {
    if (this is! SoftDeletes) {
      throw StateError('Model does not use SoftDeletes mixin.');
    }

    final mixin = this as SoftDeletes;
    (this as dynamic).deletedAt = null;

    final data = {mixin.deletedAtColumn: null};
    final updated = await connector.update(table, data, where: '$primaryKey = ?', whereArgs: [getKey()]);

    return updated > 0;
  }

  /// Permanently deletes the model from the database, bypassing soft deletes.
  Future<bool> forceDelete() async {
    if (getKey() == null) {
      throw StateError('Cannot delete a model without a primary key value.');
    }

    await onDeleting();

    final deleted = await connector.delete(table, where: '$primaryKey = ?', whereArgs: [getKey()]);

    final success = deleted > 0;
    if (success) {
      await onDeleted();
    }
    return success;
  }

  /// Refreshes the model from the database.
  Future<void> refresh() async {
    if (getKey() == null) {
      throw StateError('Cannot refresh a model without a primary key value.');
    }

    final result = await connector.query('SELECT * FROM $table WHERE $primaryKey = ?', [getKey()]);

    if (result.isEmpty) {
      throw StateError('Model not found in database.');
    }

    final row = result.first;
    fromMap(row);

    // Populate base class timestamps
    if (timestamps) {
      createdAt = parseDateTime(row[createdAtColumn]);
      updatedAt = parseDateTime(row[updatedAtColumn]);
    }
  }

  /// Updates the model with the given attributes.
  Future<bool> update(Map<String, dynamic> attributes) async {
    fromMap(attributes);
    return await save();
  }

  @override
  String toString() {
    return '$runtimeType(${toMap()})';
  }
}
