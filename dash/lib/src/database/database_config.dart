import 'database_connector.dart';
import 'migration_config.dart';

/// Configuration for database connections.
///
/// Provides a fluent interface for configuring database connections
/// with different connectors and optional automatic migrations.
class DatabaseConfig {
  final DatabaseConnector connector;
  final Map<String, dynamic> options;
  final MigrationConfig? migrationConfig;

  DatabaseConfig({required this.connector, this.options = const {}, this.migrationConfig});

  /// Creates a configuration using the provided connector.
  factory DatabaseConfig.using(
    DatabaseConnector connector, {
    Map<String, dynamic>? options,
    MigrationConfig? migrations,
  }) {
    return DatabaseConfig(connector: connector, options: options ?? {}, migrationConfig: migrations);
  }

  /// Establishes the database connection and runs migrations if configured.
  Future<void> connect() async {
    await connector.connect();

    if (migrationConfig != null && migrationConfig!.autoMigrate) {
      await connector.runMigrations(migrationConfig!.schemas, verbose: migrationConfig!.verbose);
    }
  }

  /// Closes the database connection.
  Future<void> close() => connector.close();
}
