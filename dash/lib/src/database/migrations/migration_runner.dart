import '../database_connector.dart';
import 'migration_builder.dart';
import 'schema_definition.dart';
import 'schema_inspector.dart';

/// Orchestrates the execution of database migrations.
///
/// The MigrationRunner compares the desired schema with the actual
/// database schema and executes the necessary migrations.
class MigrationRunner {
  final DatabaseConnector connector;
  final SchemaInspector inspector;
  final MigrationBuilder builder;

  MigrationRunner({required this.connector, required this.inspector, required this.builder});

  /// Runs migrations for the given table schemas.
  ///
  /// For each table:
  /// - If the table doesn't exist, creates it
  /// - If the table exists, adds any missing columns
  ///
  /// Returns a list of executed SQL statements.
  Future<List<String>> runMigrations(List<TableSchema> schemas) async {
    final executedStatements = <String>[];

    for (final schema in schemas) {
      final statements = await _migrateTable(schema);
      executedStatements.addAll(statements);
    }

    return executedStatements;
  }

  /// Migrates a single table.
  Future<List<String>> _migrateTable(TableSchema schema) async {
    final statements = <String>[];

    final exists = await inspector.tableExists(schema.name);

    if (!exists) {
      // Create the table
      final sql = builder.buildCreateTable(schema);
      await connector.execute(sql);
      statements.add(sql);
    } else {
      // Add missing columns
      final existingColumns = await inspector.getTableColumns(schema.name);
      final missingColumns = schema.columns.where((col) => !existingColumns.contains(col.name)).toList();

      if (missingColumns.isNotEmpty) {
        final alterStatements = builder.buildAddColumns(schema.name, missingColumns);

        for (final sql in alterStatements) {
          await connector.execute(sql);
          statements.add(sql);
        }
      }
    }

    return statements;
  }

  /// Checks if a table needs migration.
  ///
  /// Returns true if the table doesn't exist or is missing columns.
  Future<bool> needsMigration(TableSchema schema) async {
    final exists = await inspector.tableExists(schema.name);

    if (!exists) {
      return true;
    }

    final existingColumns = await inspector.getTableColumns(schema.name);
    return schema.columns.any((col) => !existingColumns.contains(col.name));
  }

  /// Gets a list of missing columns for a table.
  Future<List<ColumnDefinition>> getMissingColumns(TableSchema schema) async {
    final exists = await inspector.tableExists(schema.name);

    if (!exists) {
      return schema.columns;
    }

    final existingColumns = await inspector.getTableColumns(schema.name);
    return schema.columns.where((col) => !existingColumns.contains(col.name)).toList();
  }
}
