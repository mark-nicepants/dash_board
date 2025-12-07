import 'dart:io';

import 'package:dash_board/dash_board.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

/// Configuration loader for Dash CLI.
///
/// Uses [PanelConfigLoader] from Dash for config file discovery,
/// but provides CLI-specific configuration classes.
///
/// Loads configuration from:
/// 1. panel.yml/panel.yaml in current directory
/// 2. panel.yml/panel.yaml in schemas/ directory
/// 3. dash.yaml in current directory (legacy)
/// 4. Command-line arguments (highest priority)
class ConfigLoader {
  /// Load configuration from the current project.
  ///
  /// Uses [PanelConfigLoader.findPanelConfig] for discovery.
  static DashConfig load({String? configPath}) {
    // Use Dash's config finder if no explicit path provided
    final panelConfigPath = configPath ?? PanelConfigLoader.findPanelConfig();

    if (panelConfigPath != null && File(panelConfigPath).existsSync()) {
      return _loadFromFile(panelConfigPath);
    }

    // Fall back to legacy dash.yaml
    final cwd = Directory.current.path;
    final dashConfigPath = path.join(cwd, 'dash.yaml');
    if (File(dashConfigPath).existsSync()) {
      return _loadFromFile(dashConfigPath);
    }

    // Try pubspec.yaml
    final pubspecPath = path.join(cwd, 'pubspec.yaml');
    if (File(pubspecPath).existsSync()) {
      final pubspec = _loadYamlFile(pubspecPath);
      if (pubspec != null && pubspec['dash'] != null) {
        return DashConfig.fromYaml(pubspec['dash'] as YamlMap);
      }
    }

    // Return default config
    return DashConfig.defaults();
  }

  static DashConfig _loadFromFile(String filePath) {
    final yaml = _loadYamlFile(filePath);
    if (yaml == null) {
      return DashConfig.defaults();
    }
    return DashConfig.fromYaml(yaml);
  }

  static YamlMap? _loadYamlFile(String filePath) {
    try {
      final content = File(filePath).readAsStringSync();
      return loadYaml(content) as YamlMap?;
    } catch (_) {
      return null;
    }
  }

  /// Find the project root by looking for pubspec.yaml.
  static String? findProjectRoot([String? startPath]) {
    var current = Directory(startPath ?? Directory.current.path);

    while (current.path != current.parent.path) {
      final pubspec = File(path.join(current.path, 'pubspec.yaml'));
      if (pubspec.existsSync()) {
        return current.path;
      }
      current = current.parent;
    }

    return null;
  }

  /// Get the package name from pubspec.yaml.
  static String? getPackageName([String? projectRoot]) {
    final root = projectRoot ?? findProjectRoot();
    if (root == null) return null;

    final pubspecPath = path.join(root, 'pubspec.yaml');
    final yaml = _loadYamlFile(pubspecPath);
    return yaml?['name'] as String?;
  }
}

/// Database configuration.
class DatabaseConfig {
  const DatabaseConfig({
    required this.driver,
    required this.path,
    this.host,
    this.port,
    this.database,
    this.username,
    this.password,
  });

  /// Default SQLite configuration.
  factory DatabaseConfig.defaults() => const DatabaseConfig(driver: 'sqlite', path: 'storage/app.db');

  /// Load database configuration from YAML.
  factory DatabaseConfig.fromYaml(YamlMap? yaml) {
    if (yaml == null) return DatabaseConfig.defaults();

    final driver = yaml['driver'] as String? ?? 'sqlite';

    // For SQLite, path is relative to storage directory
    String dbPath;
    if (driver == 'sqlite') {
      final configPath = yaml['path'] as String? ?? 'app.db';
      // If path doesn't include storage, prepend it
      if (configPath.startsWith('storage/') || configPath.startsWith('/')) {
        dbPath = configPath;
      } else {
        dbPath = 'storage/$configPath';
      }
    } else {
      dbPath = yaml['path'] as String? ?? '';
    }

    return DatabaseConfig(
      driver: driver,
      path: dbPath,
      host: yaml['host'] as String?,
      port: yaml['port'] as int?,
      database: yaml['database'] as String?,
      username: yaml['username'] as String?,
      password: yaml['password'] as String?,
    );
  }

  /// The database driver (sqlite, postgres, mysql).
  final String driver;

  /// Path to database file (for SQLite) or socket path.
  final String path;

  /// Database host (for postgres, mysql).
  final String? host;

  /// Database port (for postgres, mysql).
  final int? port;

  /// Database name (for postgres, mysql).
  final String? database;

  /// Database username (for postgres, mysql).
  final String? username;

  /// Database password (for postgres, mysql).
  final String? password;

  /// Convert to a map suitable for DatabaseConnectorFactory.
  Map<String, dynamic> toMap() {
    return {
      'driver': driver,
      'path': path,
      'host': host,
      'port': port,
      'database': database,
      'username': username,
      'password': password,
    };
  }
}

/// Dash CLI configuration.
class DashConfig {
  const DashConfig({
    required this.databaseConfig,
    required this.schemasPath,
    required this.outputPath,
    required this.serverUrl,
    required this.serverPort,
    required this.basePath,
  });

  /// Default configuration.
  factory DashConfig.defaults() => DashConfig(
    databaseConfig: DatabaseConfig.defaults(),
    schemasPath: 'schemas/models',
    outputPath: 'lib',
    serverUrl: 'http://localhost',
    serverPort: 8080,
    basePath: '/admin',
  );

  /// Load configuration from YAML.
  factory DashConfig.fromYaml(YamlMap yaml) {
    final defaults = DashConfig.defaults();

    // Parse database config from 'database' key
    final dbConfig = DatabaseConfig.fromYaml(yaml['database'] as YamlMap?);

    // Parse panel config if present
    final panelConfig = yaml['panel'] as YamlMap?;
    final basePath = panelConfig?['path'] as String? ?? defaults.basePath;

    // Parse server config if present
    final serverConfig = yaml['server'] as YamlMap?;

    return DashConfig(
      databaseConfig: dbConfig,
      schemasPath: yaml['schemas']?['path'] as String? ?? defaults.schemasPath,
      outputPath: yaml['output']?['path'] as String? ?? defaults.outputPath,
      serverUrl: serverConfig?['url'] as String? ?? defaults.serverUrl,
      serverPort: serverConfig?['port'] as int? ?? defaults.serverPort,
      basePath: basePath,
    );
  }

  /// Database configuration.
  final DatabaseConfig databaseConfig;

  /// Path to the database file (convenience getter).
  String get databasePath => databaseConfig.path;

  /// Database driver type.
  String get databaseDriver => databaseConfig.driver;

  /// Path to schema YAML files.
  final String schemasPath;

  /// Output path for generated code.
  final String outputPath;

  /// Server URL for API commands.
  final String serverUrl;

  /// Server port.
  final int serverPort;

  /// Admin panel base path.
  final String basePath;

  /// Get the full server URL.
  String get fullServerUrl => '$serverUrl:$serverPort$basePath';

  /// Get the API URL for CLI commands.
  String get apiUrl => '$serverUrl:$serverPort$basePath/_cli';
}
