import '../database/database_connector.dart';
import '../validation/validation.dart';
import 'model_query_builder.dart';
import 'soft_deletes.dart';

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

  // ===== Helper Methods for Subclasses =====

  /// Safely casts a value to the specified type.
  /// Returns null if the value cannot be cast.
  T? getAs<T>(dynamic value) {
    if (value == null) return null;
    try {
      return value as T;
    } catch (e) {
      // Log warning in development
      return null;
    }
  }

  /// Safely gets a value from a map and casts it to the specified type.
  T? getFromMap<T>(Map<String, dynamic> map, String key) {
    return getAs<T>(map[key]);
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

  /// Saves the model to the database.
  Future<bool> save() async {
    await onSaving();

    final isCreating = getKey() == null;

    if (isCreating) {
      await onCreating();
    } else {
      await onUpdating();
    }

    // Validate after lifecycle hooks (so defaults can be set)
    validateOrFail();

    final data = toMap();

    if (timestamps) {
      final now = DateTime.now().toIso8601String();
      if (isCreating) {
        data[createdAtColumn] = now;
      }
      data[updatedAtColumn] = now;
    }

    if (isCreating) {
      // Insert
      final id = await connector.insert(table, data);
      if (incrementing) {
        setKey(id);
      }
      await onCreated();
      await onSaved();
      return true;
    } else {
      // Update
      final updated = await connector.update(table, data, where: '$primaryKey = ?', whereArgs: [getKey()]);
      final success = updated > 0;
      if (success) {
        await onUpdated();
        await onSaved();
      }
      return success;
    }
  }

  /// Deletes the model from the database.
  /// If the model uses SoftDeletes, performs a soft delete instead.
  Future<bool> delete() async {
    if (getKey() == null) {
      throw StateError('Cannot delete a model without a primary key value.');
    }

    // Check if this model uses soft deletes
    if (this is SoftDeletes) {
      return (this as dynamic).softDelete();
    }

    await onDeleting();

    final deleted = await connector.delete(table, where: '$primaryKey = ?', whereArgs: [getKey()]);

    final success = deleted > 0;
    if (success) {
      await onDeleted();
    }
    return success;
  }

  /// Performs a soft delete (sets deleted_at timestamp).
  /// Only available if the model uses SoftDeletes mixin.
  Future<bool> softDelete() async {
    if (this is! SoftDeletes) {
      throw StateError('Model does not use SoftDeletes mixin.');
    }

    await onDeleting();

    final mixin = this as SoftDeletes;
    (this as dynamic).deletedAt = DateTime.now();

    final data = {mixin.deletedAtColumn: DateTime.now().toIso8601String()};
    final updated = await connector.update(table, data, where: '$primaryKey = ?', whereArgs: [getKey()]);

    final success = updated > 0;
    if (success) {
      await onDeleted();
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

    fromMap(result.first);
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
