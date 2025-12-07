import 'package:dash_board/src/database/migrations/migration_builder.dart';
import 'package:dash_board/src/database/migrations/schema_definition.dart';

/// SQLite-specific implementation of MigrationBuilder.
///
/// Generates SQLite-compatible SQL statements for creating
/// and altering tables.
class SqliteMigrationBuilder implements MigrationBuilder {
  @override
  String buildCreateTable(TableSchema schema) {
    final buffer = StringBuffer();
    buffer.writeln('CREATE TABLE IF NOT EXISTS ${schema.name} (');

    final columnDefs = <String>[];

    for (final column in schema.columns) {
      columnDefs.add(_buildColumnDefinition(column));
    }

    buffer.write(columnDefs.join(',\n  '));
    buffer.writeln('\n)');

    return buffer.toString();
  }

  @override
  String buildAddColumn(String tableName, ColumnDefinition column) {
    return 'ALTER TABLE $tableName ADD COLUMN ${_buildColumnDefinition(column)}';
  }

  @override
  List<String> buildAddColumns(String tableName, List<ColumnDefinition> columns) {
    return columns.map((col) => buildAddColumn(tableName, col)).toList();
  }

  /// Builds a column definition string for SQLite.
  String _buildColumnDefinition(ColumnDefinition column) {
    final parts = <String>['  ${column.name}'];

    // Add type
    parts.add(_mapColumnType(column.type));

    // Add primary key
    if (column.isPrimaryKey) {
      parts.add('PRIMARY KEY');
      if (column.autoIncrement) {
        parts.add('AUTOINCREMENT');
      }
    }

    // Add not null constraint
    if (!column.nullable && !column.isPrimaryKey) {
      parts.add('NOT NULL');
    }

    // Add unique constraint
    if (column.unique && !column.isPrimaryKey) {
      parts.add('UNIQUE');
    }

    // Add default value
    if (column.defaultValue != null) {
      parts.add('DEFAULT ${_formatDefaultValue(column.defaultValue)}');
    }

    return parts.join(' ');
  }

  /// Maps a ColumnType to SQLite type.
  String _mapColumnType(ColumnType type) {
    switch (type) {
      case ColumnType.integer:
        return 'INTEGER';
      case ColumnType.text:
        return 'TEXT';
      case ColumnType.real:
        return 'REAL';
      case ColumnType.blob:
        return 'BLOB';
      case ColumnType.boolean:
        return 'INTEGER'; // SQLite doesn't have a boolean type
      case ColumnType.datetime:
        return 'TEXT'; // Store datetime as ISO8601 string
    }
  }

  /// Formats a default value for SQL.
  String _formatDefaultValue(dynamic value) {
    if (value is String) {
      return "'${value.replaceAll("'", "''")}'"; // Escape single quotes
    } else if (value is bool) {
      return value ? '1' : '0'; // SQLite uses 1/0 for booleans
    } else if (value is DateTime) {
      return "'${value.toIso8601String()}'";
    } else {
      return value.toString();
    }
  }

  @override
  String buildCreateIndex(String tableName, IndexDefinition index) {
    final uniqueKeyword = index.unique ? 'UNIQUE ' : '';
    final columns = index.columns.join(', ');
    return 'CREATE ${uniqueKeyword}INDEX IF NOT EXISTS ${index.name} ON $tableName($columns)';
  }

  @override
  List<String> buildCreateIndexes(String tableName, List<IndexDefinition> indexes) {
    return indexes.map((idx) => buildCreateIndex(tableName, idx)).toList();
  }
}
