import 'dart:io';

import 'package:dash/src/database/database_connector.dart';
import 'package:dash/src/database/migrations/builders/sqlite_migration_builder.dart';
import 'package:dash/src/database/migrations/inspectors/sqlite_schema_inspector.dart';
import 'package:dash/src/database/migrations/migration_runner.dart';
import 'package:dash/src/database/migrations/schema_definition.dart';
import 'package:sqlite3/sqlite3.dart';

/// SQLite database connector implementation.
///
/// Provides SQLite database connectivity and operations using the sqlite3 package.
/// Supports both file-based and in-memory databases.
///
/// Example:
/// ```dart
/// final connector = SqliteConnector('app.db');
/// await connector.connect();
/// final results = await connector.query('SELECT * FROM users');
/// ```
class SqliteConnector extends DatabaseConnector {
  final String path;
  Database? _database;
  bool _inTransaction = false;

  /// Creates a new SQLite connector.
  ///
  /// [path] can be a file path or ':memory:' for an in-memory database.
  SqliteConnector(this.path);

  @override
  String get type => 'sqlite';

  @override
  bool get isConnected => _database != null;

  @override
  Future<void> connect() async {
    if (_database != null) {
      return; // Already connected
    }

    // Create directory if it doesn't exist and not in-memory
    if (path != ':memory:') {
      final file = File(path);
      final dir = file.parent;
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    }

    _database = sqlite3.open(path);
  }

  @override
  Future<void> close() async {
    _database?.close();
    _database = null;
  }

  @override
  Future<List<Map<String, dynamic>>> queryImpl(String sql, [List<dynamic>? parameters]) async {
    _ensureConnected();
    final result = _database!.select(sql, parameters ?? []);
    return result.map((row) => row).toList();
  }

  @override
  Future<int> executeImpl(String sql, [List<dynamic>? parameters]) async {
    _ensureConnected();
    _database!.execute(sql, parameters ?? []);
    return _database!.lastInsertRowId;
  }

  @override
  Future<int> insertImpl(String table, Map<String, dynamic> data) async {
    _ensureConnected();

    if (data.isEmpty) {
      throw ArgumentError('Data map cannot be empty');
    }

    final columns = data.keys.toList();
    final values = data.values.toList();
    final placeholders = List.filled(columns.length, '?').join(', ');

    final sql =
        '''
      INSERT INTO $table (${columns.join(', ')})
      VALUES ($placeholders)
    ''';

    _database!.execute(sql, values);
    return _database!.lastInsertRowId;
  }

  @override
  Future<int> updateImpl(String table, Map<String, dynamic> data, {String? where, List<dynamic>? whereArgs}) async {
    _ensureConnected();

    if (data.isEmpty) {
      throw ArgumentError('Data map cannot be empty');
    }

    final columns = data.keys.toList();
    final values = data.values.toList();
    final setClause = columns.map((col) => '$col = ?').join(', ');

    final sql = StringBuffer('UPDATE $table SET $setClause');

    if (where != null && where.isNotEmpty) {
      sql.write(' WHERE $where');
      if (whereArgs != null) {
        values.addAll(whereArgs);
      }
    }

    _database!.execute(sql.toString(), values);
    return _database!.updatedRows;
  }

  @override
  Future<int> deleteImpl(String table, {String? where, List<dynamic>? whereArgs}) async {
    _ensureConnected();

    final sql = StringBuffer('DELETE FROM $table');

    if (where != null && where.isNotEmpty) {
      sql.write(' WHERE $where');
    }

    _database!.execute(sql.toString(), whereArgs ?? []);
    return _database!.updatedRows;
  }

  @override
  Future<void> beginTransaction() async {
    _ensureConnected();

    if (_inTransaction) {
      throw StateError('Transaction already in progress');
    }

    _database!.execute('BEGIN TRANSACTION');
    _inTransaction = true;
  }

  @override
  Future<void> commit() async {
    _ensureConnected();

    if (!_inTransaction) {
      throw StateError('No transaction in progress');
    }

    _database!.execute('COMMIT');
    _inTransaction = false;
  }

  @override
  Future<void> rollback() async {
    _ensureConnected();

    if (!_inTransaction) {
      throw StateError('No transaction in progress');
    }

    _database!.execute('ROLLBACK');
    _inTransaction = false;
  }

  /// Ensures a database connection exists.
  void _ensureConnected() {
    if (_database == null) {
      throw StateError('Database not connected. Call connect() first.');
    }
  }

  /// Executes raw SQL without returning results.
  /// Useful for DDL statements like CREATE TABLE.
  Future<void> executeRaw(String sql) async {
    _ensureConnected();
    _database!.execute(sql);
  }

  @override
  Future<void> runMigrations(List<dynamic> schemas, {bool verbose = false}) async {
    _ensureConnected();

    if (schemas.isEmpty) return;

    // Cast to TableSchema list
    final tableSchemas = schemas.cast<TableSchema>();

    final inspector = SqliteSchemaInspector(_database!);
    final builder = SqliteMigrationBuilder();
    final runner = MigrationRunner(connector: this, inspector: inspector, builder: builder);

    final statements = await runner.runMigrations(tableSchemas);

    if (verbose && statements.isNotEmpty) {
      print('🔄 Executed ${statements.length} migration(s):');
      for (final statement in statements) {
        print('  ✓ ${statement.replaceAll('\n', ' ').trim()}');
      }
    }
  }

  /// Creates a schema inspector for this SQLite connection.
  ///
  /// This is useful for testing and advanced use cases.
  SqliteSchemaInspector createSchemaInspector() {
    _ensureConnected();
    return SqliteSchemaInspector(_database!);
  }
}
