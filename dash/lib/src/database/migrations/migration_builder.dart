import 'package:dash/src/database/migrations/schema_definition.dart';

/// Abstract interface for building database migrations.
///
/// Implementations generate database-specific SQL for creating
/// and altering tables.
abstract class MigrationBuilder {
  /// Generates a CREATE TABLE statement.
  String buildCreateTable(TableSchema schema);

  /// Generates an ALTER TABLE ADD COLUMN statement.
  String buildAddColumn(String tableName, ColumnDefinition column);

  /// Generates statements to add multiple columns to a table.
  List<String> buildAddColumns(String tableName, List<ColumnDefinition> columns);
}
