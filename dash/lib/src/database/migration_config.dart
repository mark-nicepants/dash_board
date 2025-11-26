import 'package:dash/src/database/migrations/schema_definition.dart';
import 'package:dash/src/service_locator.dart';

/// Configuration for automatic database migrations.
///
/// Use this to enable automatic table and column creation
/// based on model definitions.
class MigrationConfig {
  /// Whether to automatically run migrations.
  final bool autoMigrate;

  /// The table schemas to migrate.
  final List<TableSchema> schemas;

  /// Whether to log migration statements.
  final bool verbose;

  const MigrationConfig({this.autoMigrate = false, this.schemas = const [], this.verbose = false});

  /// Creates a migration config with auto-migration enabled.
  factory MigrationConfig.enable({required List<TableSchema> schemas, bool verbose = false}) {
    return MigrationConfig(autoMigrate: true, schemas: schemas, verbose: verbose);
  }

  /// Creates a migration config with auto-migration disabled.
  factory MigrationConfig.disable() {
    return const MigrationConfig(autoMigrate: false);
  }

  /// Creates a migration config from a list of resources.
  ///
  /// Automatically extracts table schemas from each resource's model.
  /// This is the easiest way to set up migrations - just pass your resources!
  ///
  /// Example:
  /// ```dart
  /// final panel = Panel()
  ///   ..registerResources([UserResource(), PostResource()])
  ///   ..database(
  ///     DatabaseConfig.using(
  ///       SqliteConnector('app.db'),
  ///       migrations: MigrationConfig.fromResources(
  ///         [UserResource(), PostResource()],
  ///         verbose: true,
  ///       ),
  ///     ),
  ///   );
  /// ```
  factory MigrationConfig.fromResources({bool verbose = false}) {
    final schemas = <TableSchema>[];

    for (final resource in buildRegisteredResources()) {
      final schema = resource.schema();
      if (schema != null) {
        schemas.add(schema);
      } else if (verbose) {
        print('⚠️  No schema provided for ${resource.model}');
      }
    }

    if (verbose) {
      if (schemas.isEmpty) {
        print('⚠️  No schemas discovered from registered resources');
      } else {
        print('📋 Loaded ${schemas.length} schema(s) from resources');
      }
    }

    return MigrationConfig(autoMigrate: true, schemas: schemas, verbose: verbose);
  }
}
