/// Abstract base class for database connectors.
///
/// All database connectors must implement this interface to provide
/// consistent database operations across different database systems.
abstract class DatabaseConnector {
  /// Establishes a connection to the database.
  Future<void> connect();

  /// Closes the database connection.
  Future<void> close();

  /// Executes a raw SQL query and returns the results.
  Future<List<Map<String, dynamic>>> query(String sql, [List<dynamic>? parameters]);

  /// Executes a raw SQL statement (INSERT, UPDATE, DELETE).
  /// Returns the number of affected rows.
  Future<int> execute(String sql, [List<dynamic>? parameters]);

  /// Inserts a record into the specified table.
  /// Returns the ID of the inserted record.
  Future<int> insert(String table, Map<String, dynamic> data);

  /// Updates records in the specified table.
  /// Returns the number of affected rows.
  Future<int> update(String table, Map<String, dynamic> data, {String? where, List<dynamic>? whereArgs});

  /// Deletes records from the specified table.
  /// Returns the number of affected rows.
  Future<int> delete(String table, {String? where, List<dynamic>? whereArgs});

  /// Begins a database transaction.
  Future<void> beginTransaction();

  /// Commits the current transaction.
  Future<void> commit();

  /// Rolls back the current transaction.
  Future<void> rollback();

  /// Returns true if currently connected to the database.
  bool get isConnected;

  /// Returns the type of this database connector.
  String get type;

  /// Runs automatic migrations for the given table schemas.
  ///
  /// This is an opt-in feature. If not overridden, it does nothing.
  Future<void> runMigrations(List<dynamic> schemas, {bool verbose = false}) async {
    // Default implementation does nothing
    // Connectors can override to provide migration support
  }
}
