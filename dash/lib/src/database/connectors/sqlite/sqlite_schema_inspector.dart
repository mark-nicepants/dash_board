import 'package:dash_board/src/database/migrations/schema_definition.dart';
import 'package:dash_board/src/database/migrations/schema_inspector.dart';
import 'package:sqlite3/sqlite3.dart';

/// SQLite-specific implementation of SchemaInspector.
///
/// Uses SQLite system tables to inspect database schema.
class SqliteSchemaInspector implements SchemaInspector {
  final Database database;

  SqliteSchemaInspector(this.database);

  @override
  Future<bool> tableExists(String tableName) async {
    final result = database.select("SELECT name FROM sqlite_master WHERE type='table' AND name=?", [tableName]);
    return result.isNotEmpty;
  }

  @override
  Future<List<String>> getTables() async {
    final result = database.select("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'");
    return result.map((row) => row['name'] as String).toList();
  }

  @override
  Future<TableSchema?> getTableSchema(String tableName) async {
    if (!await tableExists(tableName)) {
      return null;
    }

    final result = database.select('PRAGMA table_info($tableName)');

    final columns = <ColumnDefinition>[];

    for (final row in result) {
      final name = row['name'] as String;
      final type = _parseColumnType(row['type'] as String);
      final notNull = (row['notnull'] as int) == 1;
      final defaultValue = row['dflt_value'];
      final isPrimaryKey = (row['pk'] as int) > 0;

      columns.add(
        ColumnDefinition(
          name: name,
          type: type,
          isPrimaryKey: isPrimaryKey,
          nullable: !notNull,
          defaultValue: defaultValue,
        ),
      );
    }

    return TableSchema(name: tableName, columns: columns);
  }

  @override
  Future<List<String>> getTableColumns(String tableName) async {
    final schema = await getTableSchema(tableName);
    if (schema == null) {
      return [];
    }
    return schema.columns.map((col) => col.name).toList();
  }

  /// Parses a SQLite column type string to ColumnType.
  ColumnType _parseColumnType(String sqliteType) {
    final type = sqliteType.toUpperCase();

    if (type.contains('INT')) {
      return ColumnType.integer;
    } else if (type.contains('TEXT') || type.contains('CHAR') || type.contains('CLOB')) {
      return ColumnType.text;
    } else if (type.contains('REAL') || type.contains('DOUBLE') || type.contains('FLOAT')) {
      return ColumnType.real;
    } else if (type.contains('BLOB')) {
      return ColumnType.blob;
    } else {
      // Default to TEXT for unknown types
      return ColumnType.text;
    }
  }

  @override
  Future<bool> indexExists(String indexName) async {
    final result = database.select("SELECT name FROM sqlite_master WHERE type='index' AND name=?", [indexName]);
    return result.isNotEmpty;
  }

  @override
  Future<List<String>> getTableIndexes(String tableName) async {
    final result = database.select(
      "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name=? AND name NOT LIKE 'sqlite_%'",
      [tableName],
    );
    return result.map((row) => row['name'] as String).toList();
  }
}
