/// Schema definition classes for database migrations.
///
/// These classes provide a database-agnostic way to represent
/// table structures for automatic migrations.
library;

/// Represents a database column type.
enum ColumnType { integer, text, real, blob, boolean, datetime }

/// Represents a single column in a database table.
class ColumnDefinition {
  /// The name of the column.
  final String name;

  /// The data type of the column.
  final ColumnType type;

  /// Whether the column is the primary key.
  final bool isPrimaryKey;

  /// Whether the column is auto-incrementing.
  final bool autoIncrement;

  /// Whether the column can be null.
  final bool nullable;

  /// Default value for the column.
  final dynamic defaultValue;

  /// Whether the column is unique.
  final bool unique;

  const ColumnDefinition({
    required this.name,
    required this.type,
    this.isPrimaryKey = false,
    this.autoIncrement = false,
    this.nullable = true,
    this.defaultValue,
    this.unique = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ColumnDefinition &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          type == other.type &&
          isPrimaryKey == other.isPrimaryKey &&
          autoIncrement == other.autoIncrement &&
          nullable == other.nullable &&
          defaultValue == other.defaultValue &&
          unique == other.unique;

  @override
  int get hashCode =>
      name.hashCode ^
      type.hashCode ^
      isPrimaryKey.hashCode ^
      autoIncrement.hashCode ^
      nullable.hashCode ^
      defaultValue.hashCode ^
      unique.hashCode;

  @override
  String toString() {
    return 'ColumnDefinition(name: $name, type: $type, isPrimaryKey: $isPrimaryKey, '
        'autoIncrement: $autoIncrement, nullable: $nullable, defaultValue: $defaultValue, '
        'unique: $unique)';
  }

  /// Creates a copy of this column definition with optional modifications.
  ColumnDefinition copyWith({
    String? name,
    ColumnType? type,
    bool? isPrimaryKey,
    bool? autoIncrement,
    bool? nullable,
    dynamic defaultValue,
    bool? unique,
  }) {
    return ColumnDefinition(
      name: name ?? this.name,
      type: type ?? this.type,
      isPrimaryKey: isPrimaryKey ?? this.isPrimaryKey,
      autoIncrement: autoIncrement ?? this.autoIncrement,
      nullable: nullable ?? this.nullable,
      defaultValue: defaultValue ?? this.defaultValue,
      unique: unique ?? this.unique,
    );
  }
}

/// Represents a database table schema.
class TableSchema {
  /// The name of the table.
  final String name;

  /// The columns in the table.
  final List<ColumnDefinition> columns;

  const TableSchema({required this.name, required this.columns});

  /// Gets a column by name.
  ColumnDefinition? getColumn(String name) {
    try {
      return columns.firstWhere((col) => col.name == name);
    } catch (e) {
      return null;
    }
  }

  /// Checks if a column exists in the table.
  bool hasColumn(String name) {
    return columns.any((col) => col.name == name);
  }

  /// Gets the primary key column, if any.
  ColumnDefinition? get primaryKey {
    try {
      return columns.firstWhere((col) => col.isPrimaryKey);
    } catch (e) {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TableSchema &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          _listEquals(columns, other.columns);

  @override
  int get hashCode => name.hashCode ^ columns.hashCode;

  @override
  String toString() {
    return 'TableSchema(name: $name, columns: ${columns.length})';
  }

  bool _listEquals(List a, List b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
