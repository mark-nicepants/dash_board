import 'package:dash_board/src/database/database_connector.dart';

/// Extension providing CLI-specific utility methods for DatabaseConnector.
///
/// These methods are commonly needed by CLI tools for database inspection,
/// schema viewing, and data management tasks.
///
/// Currently only SQLite is supported.
extension DatabaseConnectorCli on DatabaseConnector {
  /// Get list of all table names in the database.
  ///
  /// Returns user tables, excluding system tables.
  Future<List<String>> getTables() async {
    _ensureSqlite();
    final results = await query(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name",
    );
    return results.map((r) => r['name'] as String).toList();
  }

  /// Get column information for a table.
  ///
  /// Returns a list of maps with column metadata:
  /// - name: Column name
  /// - type: Column type
  /// - nullable: Whether column allows NULL (bool)
  /// - primaryKey: Whether column is primary key (bool)
  /// - defaultValue: Default value if any
  Future<List<Map<String, dynamic>>> getTableInfo(String table) async {
    _ensureSqlite();
    final results = await query('PRAGMA table_info("$table")');
    return results.map((row) {
      return {
        'name': row['name'],
        'type': row['type'],
        'nullable': row['notnull'] == 0,
        'primaryKey': row['pk'] == 1,
        'defaultValue': row['dflt_value'],
      };
    }).toList();
  }

  /// Get foreign key information for a table.
  ///
  /// Returns a list of maps with:
  /// - from: Local column name
  /// - table: Referenced table name
  /// - to: Referenced column name
  Future<List<Map<String, dynamic>>> getForeignKeys(String table) async {
    _ensureSqlite();
    final results = await query('PRAGMA foreign_key_list("$table")');
    return results.map((row) {
      return {'from': row['from'], 'table': row['table'], 'to': row['to']};
    }).toList();
  }

  /// Get index information for a table.
  ///
  /// Returns a list of maps with:
  /// - name: Index name
  /// - unique: Whether index is unique (bool)
  /// - columns: List of column names
  Future<List<Map<String, dynamic>>> getIndexes(String table) async {
    _ensureSqlite();
    final indexList = await query('PRAGMA index_list("$table")');
    final indexes = <Map<String, dynamic>>[];

    for (final idx in indexList) {
      final indexName = idx['name'] as String;
      final indexInfo = await query('PRAGMA index_info("$indexName")');
      final columns = indexInfo.map((r) => r['name'] as String).toList();

      indexes.add({'name': indexName, 'unique': idx['unique'] == 1, 'columns': columns});
    }
    return indexes;
  }

  /// Get row count for a table.
  Future<int> getRowCount(String table) async {
    final results = await query('SELECT COUNT(*) as count FROM "$table"');
    if (results.isEmpty) return 0;
    return results.first['count'] as int;
  }

  /// Check if a table exists.
  Future<bool> tableExists(String table) async {
    final tables = await getTables();
    return tables.contains(table);
  }

  /// Get all values from a column (useful for foreign key lookups).
  ///
  /// [table] - The table name
  /// [column] - The column to fetch
  /// [limit] - Maximum number of values to return
  Future<List<dynamic>> getColumnValues(String table, String column, {int limit = 1000}) async {
    final results = await query('SELECT "$column" FROM "$table" LIMIT $limit');
    return results.map((r) => r[column]).toList();
  }

  /// Disable foreign key checks (useful for bulk operations).
  ///
  /// Call [enableForeignKeys] when done.
  Future<void> disableForeignKeys() async {
    _ensureSqlite();
    await execute('PRAGMA foreign_keys = OFF');
  }

  /// Enable foreign key checks.
  Future<void> enableForeignKeys() async {
    _ensureSqlite();
    await execute('PRAGMA foreign_keys = ON');
  }

  /// Reclaim unused space (SQLite VACUUM).
  Future<void> vacuum() async {
    _ensureSqlite();
    await execute('VACUUM');
  }

  /// Clear all data from a table (DELETE FROM).
  ///
  /// Returns the number of rows deleted.
  Future<int> clearTable(String table) async {
    final count = await getRowCount(table);
    await delete(table);
    return count;
  }

  /// Ensures the connector is SQLite. Throws if not.
  void _ensureSqlite() {
    if (type != DatabaseConnectorType.sqlite) {
      throw UnsupportedError('Only SQLite is currently supported. Got: \$type');
    }
  }
}
