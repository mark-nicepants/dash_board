import 'package:dash/src/database/migrations/schema_definition.dart';
import 'package:dash/src/panel/panel_config.dart';

/// Configuration for automatic database migrations.
///
/// Use this to enable automatic table and column creation
/// based on model definitions.
class MigrationConfig {
  /// Whether to automatically run migrations.
  final bool autoMigrate;

  /// The table schemas to migrate.
  /// If null, schemas will be resolved from PanelConfig during boot.
  final List<TableSchema>? _schemas;

  /// Whether to log migration statements.
  final bool verbose;

  /// Whether to resolve schemas from PanelConfig at boot time.
  final bool _resolveFromConfig;

  const MigrationConfig({this.autoMigrate = false, List<TableSchema>? schemas, this.verbose = false})
    : _schemas = schemas,
      _resolveFromConfig = false;

  const MigrationConfig._deferred({required this.autoMigrate, required this.verbose})
    : _schemas = null,
      _resolveFromConfig = true;

  /// Gets the schemas, resolving from config if needed.
  List<TableSchema> getSchemas([PanelConfig? config]) {
    if (_resolveFromConfig && config != null) {
      final schemas = <TableSchema>[];

      // Gather schemas from registered resources
      for (final resource in config.resources) {
        schemas.add(resource.schema);
      }

      // Include additional schemas registered by plugins
      schemas.addAll(config.additionalSchemas);

      if (verbose) {
        if (schemas.isEmpty) {
          print('⚠️  No schemas discovered from registered resources');
        } else {
          final resourceCount = schemas.length - config.additionalSchemas.length;
          print('📋 Loaded $resourceCount schema(s) from resources');
          if (config.additionalSchemas.isNotEmpty) {
            print('📋 Loaded ${config.additionalSchemas.length} additional schema(s) from plugins');
          }
        }
      }

      return schemas;
    }
    return _schemas ?? [];
  }

  /// Creates a migration config with auto-migration enabled.
  factory MigrationConfig.enable({required List<TableSchema> schemas, bool verbose = false}) {
    return MigrationConfig(autoMigrate: true, schemas: schemas, verbose: verbose);
  }

  /// Creates a migration config with auto-migration disabled.
  factory MigrationConfig.disable() {
    return const MigrationConfig(autoMigrate: false);
  }

  /// Creates a migration config that resolves schemas from registered resources at boot time.
  ///
  /// This is the recommended way to set up migrations when using the config loader,
  /// as resources may not be registered yet when the config is loaded.
  ///
  /// Example:
  /// ```dart
  /// final panel = Panel()
  ///   ..registerResources([UserResource(), PostResource()])
  ///   ..database(
  ///     DatabaseConfig.using(
  ///       SqliteConnector('app.db'),
  ///       migrations: MigrationConfig.fromResources(verbose: true),
  ///     ),
  ///   );
  /// ```
  factory MigrationConfig.fromResources({bool verbose = false}) {
    return MigrationConfig._deferred(autoMigrate: true, verbose: verbose);
  }
}
