import 'package:dash/src/database/migrations/schema_definition.dart';

/// Abstract interface for inspecting database schema.
///
/// Implementations provide database-specific logic for
/// detecting existing tables and columns.
abstract class SchemaInspector {
  /// Checks if a table exists in the database.
  Future<bool> tableExists(String tableName);

  /// Gets the list of all tables in the database.
  Future<List<String>> getTables();

  /// Gets the schema for a specific table.
  ///
  /// Returns null if the table doesn't exist.
  Future<TableSchema?> getTableSchema(String tableName);

  /// Gets the list of columns in a table.
  ///
  /// Returns an empty list if the table doesn't exist.
  Future<List<String>> getTableColumns(String tableName);
}
