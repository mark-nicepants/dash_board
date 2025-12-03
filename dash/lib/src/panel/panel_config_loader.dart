import 'dart:io';

import 'package:dash/src/auth/session_store.dart';
import 'package:dash/src/database/connectors/sqlite_connector.dart';
import 'package:dash/src/database/database_config.dart';
import 'package:dash/src/database/database_connector.dart';
import 'package:dash/src/database/migrations/migration_config.dart';
import 'package:dash/src/panel/panel.dart';
import 'package:dash/src/storage/storage.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Configuration data loaded from a panel YAML file.
///
/// Provides a typed wrapper around the YAML configuration.
class PanelConfigData {
  final String id;
  final String path;
  final StorageConfigData? storage;
  final SessionConfigData? session;
  final DbConfigData? database;

  const PanelConfigData({this.id = 'admin', this.path = '/admin', this.storage, this.session, this.database});

  factory PanelConfigData.fromYaml(Map<String, dynamic> yaml) {
    final panelSection = yaml['panel'] as Map<String, dynamic>?;
    final storageSection = yaml['storage'] as Map<String, dynamic>?;
    final sessionSection = yaml['session'] as Map<String, dynamic>?;
    final databaseSection = yaml['database'] as Map<String, dynamic>?;

    return PanelConfigData(
      id: panelSection?['id'] as String? ?? 'admin',
      path: panelSection?['path'] as String? ?? '/admin',
      storage: storageSection != null ? StorageConfigData.fromYaml(storageSection) : null,
      session: sessionSection != null ? SessionConfigData.fromYaml(sessionSection) : null,
      database: databaseSection != null ? DbConfigData.fromYaml(databaseSection) : null,
    );
  }
}

/// Storage configuration data.
class StorageConfigData {
  final String basePath;
  final String defaultDisk;
  final Map<String, DiskConfigData> disks;

  const StorageConfigData({this.basePath = 'storage', this.defaultDisk = 'public', this.disks = const {}});

  factory StorageConfigData.fromYaml(Map<String, dynamic> yaml) {
    final disksYaml = yaml['disks'] as Map<String, dynamic>?;
    final disks = <String, DiskConfigData>{};

    if (disksYaml != null) {
      for (final entry in disksYaml.entries) {
        disks[entry.key] = DiskConfigData.fromYaml(entry.value as Map<String, dynamic>);
      }
    }

    return StorageConfigData(
      basePath: yaml['basePath'] as String? ?? 'storage',
      defaultDisk: yaml['defaultDisk'] as String? ?? 'public',
      disks: disks,
    );
  }
}

/// Individual disk configuration data.
class DiskConfigData {
  final String driver;
  final String? path;
  final String? urlPrefix;
  final String visibility;

  const DiskConfigData({this.driver = 'local', this.path, this.urlPrefix, this.visibility = 'public'});

  factory DiskConfigData.fromYaml(Map<String, dynamic> yaml) {
    return DiskConfigData(
      driver: yaml['driver'] as String? ?? 'local',
      path: yaml['path'] as String?,
      urlPrefix: yaml['urlPrefix'] as String?,
      visibility: yaml['visibility'] as String? ?? 'public',
    );
  }
}

/// Session configuration data.
class SessionConfigData {
  final String driver;
  final String path;

  const SessionConfigData({this.driver = 'file', this.path = 'sessions'});

  factory SessionConfigData.fromYaml(Map<String, dynamic> yaml) {
    return SessionConfigData(driver: yaml['driver'] as String? ?? 'file', path: yaml['path'] as String? ?? 'sessions');
  }
}

/// Database configuration data.
class DbConfigData {
  final String driver;
  final String? path;
  final String? host;
  final int? port;
  final String? database;
  final String? username;
  final String? password;
  final bool autoMigrate;
  final bool verbose;

  const DbConfigData({
    required this.driver,
    this.path,
    this.host,
    this.port,
    this.database,
    this.username,
    this.password,
    this.autoMigrate = true,
    this.verbose = false,
  });

  factory DbConfigData.fromYaml(Map<String, dynamic> yaml) {
    final migrationsYaml = yaml['migrations'] as Map<String, dynamic>?;

    return DbConfigData(
      driver: yaml['driver'] as String,
      path: yaml['path'] as String?,
      host: yaml['host'] as String?,
      port: yaml['port'] as int?,
      database: yaml['database'] as String?,
      username: yaml['username'] as String?,
      password: yaml['password'] as String?,
      autoMigrate: migrationsYaml?['auto'] as bool? ?? true,
      verbose: migrationsYaml?['verbose'] as bool? ?? false,
    );
  }
}

/// Loader utility for panel YAML configuration files.
///
/// Loads and parses a YAML configuration file and applies it to a Panel.
///
/// Example:
/// ```dart
/// final panel = Panel()..applyConfig('schemas/panel.yaml');
/// ```
class PanelConfigLoader {
  /// Loads a panel configuration from a YAML file asynchronously.
  static Future<PanelConfigData> load(String configPath) async {
    final file = File(configPath);
    if (!await file.exists()) {
      throw StateError('Panel config file not found: $configPath');
    }

    final content = await file.readAsString();
    final yaml = loadYaml(content) as YamlMap;

    return PanelConfigData.fromYaml(_yamlMapToMap(yaml));
  }

  /// Loads a panel configuration from a YAML file synchronously.
  static PanelConfigData loadSync(String configPath) {
    final file = File(configPath);
    if (!file.existsSync()) {
      throw StateError('Panel config file not found: $configPath');
    }

    final content = file.readAsStringSync();
    final yaml = loadYaml(content) as YamlMap;

    return PanelConfigData.fromYaml(_yamlMapToMap(yaml));
  }

  /// Converts a YamlMap to a regular Map recursively.
  static Map<String, dynamic> _yamlMapToMap(YamlMap yaml) {
    final result = <String, dynamic>{};
    for (final entry in yaml.entries) {
      final key = entry.key as String;
      final value = entry.value;
      if (value is YamlMap) {
        result[key] = _yamlMapToMap(value);
      } else if (value is YamlList) {
        result[key] = value.toList();
      } else {
        result[key] = value;
      }
    }
    return result;
  }
}

/// Extension on Panel to apply configuration from a YAML file path.
extension PanelConfigExtension on Panel {
  /// Applies configuration from a YAML file to this panel.
  ///
  /// Loads the configuration from the specified path and configures the panel's
  /// id, path, storage, session, and database settings.
  ///
  /// Example:
  /// ```dart
  /// final panel = Panel()..applyConfig('schemas/panel.yaml');
  /// ```
  Panel applyConfig(String configPath) {
    final config = PanelConfigLoader.loadSync(configPath);
    setId(config.id);
    setPath(config.path);

    // Resolve base storage path
    final basePath = config.storage?.basePath ?? 'storage';

    // Configure session store
    if (config.session != null) {
      final sessionPath = p.join(basePath, config.session!.path);
      final store = switch (config.session!.driver) {
        'file' => FileSessionStore(sessionPath),
        'memory' => InMemorySessionStore(),
        _ => throw StateError('Unknown session driver: ${config.session!.driver}'),
      };
      sessionStore(store);
    }

    // Configure storage disks (always configure, using defaults if not specified)
    String storageDefaultDisk = 'public';
    final Map<String, Storage> storageDisks = {};

    if (config.storage != null) {
      storageDefaultDisk = config.storage!.defaultDisk;

      for (final entry in config.storage!.disks.entries) {
        final diskName = entry.key;
        final diskConfig = entry.value;
        final diskPath = p.join(basePath, diskConfig.path ?? diskName);

        if (diskConfig.driver == 'local') {
          final urlPrefix = diskConfig.urlPrefix ?? '/${config.path}/storage/$diskName';
          storageDisks[diskName] = LocalStorage(basePath: diskPath, urlPrefix: urlPrefix);
        } else {
          throw StateError('Unknown storage driver: ${diskConfig.driver}');
        }
      }
    }

    final storageConfig = StorageConfig(
      defaultDisk: storageDefaultDisk,
      disks: storageDisks,
      basePath: basePath,
      panelPath: config.path,
    );

    // Always apply storage config - it will create default disks if none are configured
    storage(storageConfig);

    // Configure database
    if (config.database != null) {
      final dbConfig = config.database!;
      final DatabaseConnector connector;

      switch (dbConfig.driver) {
        case 'sqlite':
          final dbPath = p.join(basePath, dbConfig.path ?? 'app.db');
          connector = SqliteConnector(dbPath);
        case 'postgres':
        case 'mysql':
          throw UnimplementedError('${dbConfig.driver} connector not yet implemented');
        default:
          throw StateError('Unknown database driver: ${dbConfig.driver}');
      }

      database(
        DatabaseConfig.using(
          connector,
          migrations: dbConfig.autoMigrate ? MigrationConfig.fromResources(verbose: dbConfig.verbose) : null,
        ),
      );
    }

    return this;
  }
}
