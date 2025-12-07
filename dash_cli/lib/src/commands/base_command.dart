import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dash_panel_cli/src/commands/completion_configuration.dart';
import 'package:dash_panel_cli/src/generators/schema_parser.dart';
import 'package:dash_panel_cli/src/utils/config_loader.dart';
import 'package:dash_panel/dash_panel.dart';
import 'package:path/path.dart' as path;

/// Base class for all Dash CLI commands.
///
/// Provides common functionality:
/// - Configuration loading from panel.yaml
/// - Database connection factory
/// - Schema file discovery
/// - Completion configuration
abstract class BaseCommand extends Command<int> with CompletionConfigurable {
  DashConfig? _config;

  /// Get the loaded configuration.
  ///
  /// Lazily loads from panel.yaml or defaults.
  DashConfig get config => _config ??= ConfigLoader.load();

  /// Get a database connector based on configuration.
  ///
  /// [databasePath] - Override the configured database path
  ///
  /// Returns a [DatabaseConnector] appropriate for the configured driver.
  /// The connector is already connected when returned.
  Future<DatabaseConnector> getDatabase({String? databasePath}) async {
    final effectivePath = databasePath ?? config.databasePath;

    // Verify database file exists for SQLite
    if (config.databaseDriver == 'sqlite' && !File(effectivePath).existsSync()) {
      throw FileSystemException('Database not found', effectivePath);
    }

    // Create connector based on driver type
    final DatabaseConnector connector;
    switch (config.databaseDriver) {
      case 'sqlite':
        connector = SqliteConnector(effectivePath);
      default:
        throw UnsupportedError('Unknown database driver: ${config.databaseDriver}');
    }

    await connector.connect();
    return connector;
  }

  /// Load all schema files from the schemas directory.
  ///
  /// [schemasPath] - Override the configured schemas path
  /// [recursive] - Whether to search subdirectories (default: true)
  ///
  /// Returns a map of lowercase model name to parsed schema.
  Map<String, ParsedSchema> loadSchemas({String? schemasPath, bool recursive = true}) {
    final effectivePath = schemasPath ?? config.schemasPath;
    final dir = Directory(effectivePath);

    if (!dir.existsSync()) {
      throw FileSystemException('Schemas directory not found', effectivePath);
    }

    final parser = SchemaParser();
    final schemas = <String, ParsedSchema>{};

    // Get all schema files, recursively if requested
    final entities = recursive ? dir.listSync(recursive: true) : dir.listSync();
    final schemaFiles = entities.whereType<File>().where((f) => f.path.endsWith('.yaml') || f.path.endsWith('.yml'));

    for (final file in schemaFiles) {
      try {
        final schema = parser.parseFile(file.path);
        schemas[schema.modelName.toLowerCase()] = schema;
      } catch (_) {
        // Skip files that fail to parse (e.g., panel.yaml, non-schema files)
      }
    }

    return schemas;
  }

  /// Get schema for a specific model.
  ///
  /// [modelName] - The model name (case-insensitive)
  /// [schemasPath] - Override the configured schemas path
  ///
  /// Returns the parsed schema or null if not found.
  ParsedSchema? getSchema(String modelName, {String? schemasPath}) {
    final schemas = loadSchemas(schemasPath: schemasPath);
    return schemas[modelName.toLowerCase()];
  }

  /// List available model names from schema files.
  List<String> listModelNames({String? schemasPath}) {
    final schemas = loadSchemas(schemasPath: schemasPath);
    return schemas.values.map((s) => s.modelName).toList();
  }

  /// Convert a string to snake_case.
  String toSnakeCase(String input) {
    return input
        .replaceAllMapped(RegExp(r'[A-Z]'), (match) => '_${match.group(0)!.toLowerCase()}')
        .replaceFirst(RegExp(r'^_'), '');
  }

  /// Get the absolute path for a relative path.
  String getAbsolutePath(String relativePath) {
    if (path.isAbsolute(relativePath)) {
      return relativePath;
    }
    return path.join(Directory.current.path, relativePath);
  }

  @override
  CompletionConfiguration? getCompletionConfig() {
    // Subclasses should override this to provide completion config
    return null;
  }
}

/// Adds common database-related options to commands.
mixin DatabaseCommandMixin on BaseCommand {
  /// Add the standard database options to argParser.
  void addDatabaseOptions() {
    argParser.addOption('database', abbr: 'd', help: 'Path to database file');
  }

  /// Get the effective database path from args or config.
  String get effectiveDatabasePath {
    final argPath = argResults?['database'] as String?;
    return argPath ?? config.databasePath;
  }
}

/// Adds common schema-related options to commands.
mixin SchemaCommandMixin on BaseCommand {
  /// Add the standard schema options to argParser.
  void addSchemaOptions() {
    argParser.addOption('schemas', abbr: 's', help: 'Path to directory containing schema YAML files');
  }

  /// Get the effective schemas path from args or config.
  String get effectiveSchemasPath {
    final argPath = argResults?['schemas'] as String?;
    return argPath ?? config.schemasPath;
  }
}
