import 'package:dash_board/src/cli/cli_logger.dart';

/// Enum representing supported database connector types.
///
/// Currently only SQLite is supported.
enum DatabaseConnectorType {
  /// SQLite database connector.
  sqlite,
}

/// Abstract base class for database connectors.
///
/// All database connectors must implement this interface to provide
/// consistent database operations across different database systems.
///
/// Query logging is built into the base class - all operations are
/// automatically logged when [QueryLog.isEnabled] is true, and also
/// logged to the CLI via [cliLogQuery].
abstract class DatabaseConnector {
  /// Establishes a connection to the database.
  Future<void> connect();

  /// Closes the database connection.
  Future<void> close();

  /// Executes a raw SQL query and returns the results.
  ///
  /// Subclasses should override [queryImpl] instead of this method.
  Future<List<Map<String, dynamic>>> query(String sql, [List<dynamic>? parameters]) async {
    final stopwatch = Stopwatch()..start();
    final results = await queryImpl(sql, parameters);
    stopwatch.stop();

    cliLogQuery(sql: sql, parameters: parameters, duration: stopwatch.elapsed, rowCount: results.length);

    return results;
  }

  /// Internal implementation of query. Override this in subclasses.
  Future<List<Map<String, dynamic>>> queryImpl(String sql, [List<dynamic>? parameters]);

  /// Executes a raw SQL statement (INSERT, UPDATE, DELETE).
  /// Returns the last inserted row ID or affected rows count.
  ///
  /// Subclasses should override [executeImpl] instead of this method.
  Future<int> execute(String sql, [List<dynamic>? parameters]) async {
    final stopwatch = Stopwatch()..start();
    final result = await executeImpl(sql, parameters);
    stopwatch.stop();

    cliLogQuery(sql: sql, parameters: parameters, duration: stopwatch.elapsed);

    return result;
  }

  /// Internal implementation of execute. Override this in subclasses.
  Future<int> executeImpl(String sql, [List<dynamic>? parameters]);

  /// Inserts a record into the specified table.
  /// Returns the ID of the inserted record.
  ///
  /// Subclasses should override [insertImpl] instead of this method.
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final stopwatch = Stopwatch()..start();
    final result = await insertImpl(table, data);
    stopwatch.stop();

    final columns = data.keys.toList();
    final placeholders = List.filled(columns.length, '?').join(', ');
    final sql = 'INSERT INTO $table (${columns.join(', ')}) VALUES ($placeholders)';

    cliLogQuery(sql: sql, parameters: data.values.toList(), duration: stopwatch.elapsed, rowCount: 1);

    return result;
  }

  /// Internal implementation of insert. Override this in subclasses.
  Future<int> insertImpl(String table, Map<String, dynamic> data);

  /// Updates records in the specified table.
  /// Returns the number of affected rows.
  ///
  /// Subclasses should override [updateImpl] instead of this method.
  Future<int> update(String table, Map<String, dynamic> data, {String? where, List<dynamic>? whereArgs}) async {
    final stopwatch = Stopwatch()..start();
    final result = await updateImpl(table, data, where: where, whereArgs: whereArgs);
    stopwatch.stop();

    final setClause = data.keys.map((col) => '$col = ?').join(', ');
    final sql = StringBuffer('UPDATE $table SET $setClause');
    if (where != null && where.isNotEmpty) {
      sql.write(' WHERE $where');
    }

    final allParams = [...data.values, ...?whereArgs];

    cliLogQuery(sql: sql.toString(), parameters: allParams, duration: stopwatch.elapsed, rowCount: result);

    return result;
  }

  /// Internal implementation of update. Override this in subclasses.
  Future<int> updateImpl(String table, Map<String, dynamic> data, {String? where, List<dynamic>? whereArgs});

  /// Deletes records from the specified table.
  /// Returns the number of affected rows.
  ///
  /// Subclasses should override [deleteImpl] instead of this method.
  Future<int> delete(String table, {String? where, List<dynamic>? whereArgs}) async {
    final stopwatch = Stopwatch()..start();
    final result = await deleteImpl(table, where: where, whereArgs: whereArgs);
    stopwatch.stop();

    final sql = StringBuffer('DELETE FROM $table');
    if (where != null && where.isNotEmpty) {
      sql.write(' WHERE $where');
    }

    cliLogQuery(sql: sql.toString(), parameters: whereArgs, duration: stopwatch.elapsed, rowCount: result);

    return result;
  }

  /// Internal implementation of delete. Override this in subclasses.
  Future<int> deleteImpl(String table, {String? where, List<dynamic>? whereArgs});

  /// Begins a database transaction.
  Future<void> beginTransaction();

  /// Commits the current transaction.
  Future<void> commit();

  /// Rolls back the current transaction.
  Future<void> rollback();

  /// Returns true if currently connected to the database.
  bool get isConnected;

  /// Returns the type of this database connector.
  DatabaseConnectorType get type;

  /// Returns a SQL expression that truncates a datetime column to the given granularity.
  ///
  /// This is used for GROUP BY operations that aggregate by time periods.
  /// Each connector should override this to use native date functions.
  ///
  /// [column] is the datetime column name.
  /// [granularity] is one of: 'hour', 'day', 'week', 'month', 'year'.
  ///
  /// Example usage:
  /// ```dart
  /// final expr = connector.dateTrunc('created_at', 'day');
  /// // SQLite: date(created_at)
  /// // MySQL: DATE(created_at)
  /// // PostgreSQL: DATE_TRUNC('day', created_at)
  /// ```
  String dateTrunc(String column, String granularity);

  /// Runs automatic migrations for the given table schemas.
  ///
  /// This is an opt-in feature. If not overridden, it does nothing.
  Future<void> runMigrations(List<dynamic> schemas, {bool verbose = false}) async {
    // Default implementation does nothing
    // Connectors can override to provide migration support
  }
}
