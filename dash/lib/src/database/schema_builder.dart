import 'migrations/schema_definition.dart';

/// Helper class to build database schemas in a fluent, readable way.
///
/// Provides convenient methods for defining tables and columns
/// for automatic migrations.
///
/// Example:
/// ```dart
/// final schema = SchemaBuilder.table(
///   'users',
///   columns: [
///     SchemaBuilder.id(),
///     SchemaBuilder.text('name', nullable: false),
///     SchemaBuilder.text('email', unique: true),
///   ],
/// );
/// ```
class SchemaBuilder {
  /// Creates a table schema from column definitions.
  static TableSchema table(String name, {required List<ColumnDefinition> columns}) {
    return TableSchema(name: name, columns: columns);
  }

  /// Creates an auto-incrementing integer primary key column.
  ///
  /// Example:
  /// ```dart
  /// SchemaBuilder.id()  // Creates 'id' column
  /// SchemaBuilder.id('user_id')  // Creates 'user_id' column
  /// ```
  static ColumnDefinition id([String name = 'id']) {
    return ColumnDefinition(name: name, type: ColumnType.integer, isPrimaryKey: true, autoIncrement: true);
  }

  /// Creates a text/string column.
  ///
  /// Example:
  /// ```dart
  /// SchemaBuilder.text('name')
  /// SchemaBuilder.text('email', nullable: false, unique: true)
  /// SchemaBuilder.text('status', defaultValue: 'active')
  /// ```
  static ColumnDefinition text(String name, {bool nullable = true, bool unique = false, String? defaultValue}) {
    return ColumnDefinition(
      name: name,
      type: ColumnType.text,
      nullable: nullable,
      unique: unique,
      defaultValue: defaultValue,
    );
  }

  /// Creates an integer column.
  ///
  /// Example:
  /// ```dart
  /// SchemaBuilder.integer('age')
  /// SchemaBuilder.integer('count', defaultValue: 0)
  /// ```
  static ColumnDefinition integer(String name, {bool nullable = true, int? defaultValue}) {
    return ColumnDefinition(name: name, type: ColumnType.integer, nullable: nullable, defaultValue: defaultValue);
  }

  /// Creates a real/floating-point number column.
  ///
  /// Example:
  /// ```dart
  /// SchemaBuilder.real('price')
  /// SchemaBuilder.real('rating', defaultValue: 0.0)
  /// ```
  static ColumnDefinition real(String name, {bool nullable = true, double? defaultValue}) {
    return ColumnDefinition(name: name, type: ColumnType.real, nullable: nullable, defaultValue: defaultValue);
  }

  /// Creates a boolean column.
  ///
  /// Example:
  /// ```dart
  /// SchemaBuilder.boolean('is_active')
  /// SchemaBuilder.boolean('published', defaultValue: false)
  /// ```
  static ColumnDefinition boolean(String name, {bool nullable = true, bool? defaultValue}) {
    return ColumnDefinition(name: name, type: ColumnType.boolean, nullable: nullable, defaultValue: defaultValue);
  }

  /// Creates a datetime column.
  ///
  /// Example:
  /// ```dart
  /// SchemaBuilder.datetime('created_at')
  /// SchemaBuilder.datetime('published_at', nullable: false)
  /// ```
  static ColumnDefinition datetime(String name, {bool nullable = true}) {
    return ColumnDefinition(name: name, type: ColumnType.datetime, nullable: nullable);
  }

  /// Creates a blob/binary data column.
  ///
  /// Example:
  /// ```dart
  /// SchemaBuilder.blob('file_data')
  /// ```
  static ColumnDefinition blob(String name, {bool nullable = true}) {
    return ColumnDefinition(name: name, type: ColumnType.blob, nullable: nullable);
  }
}
