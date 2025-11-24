import '../database/database_config.dart';
import '../resource.dart';

/// Configuration for a Dash panel.
///
/// Holds all the configuration data for a panel including
/// identification, resources, and database settings.
class PanelConfig {
  String _id = 'admin';
  String _path = '/admin';
  final List<Resource> _resources = [];
  DatabaseConfig? _databaseConfig;

  /// The unique identifier for this panel.
  String get id => _id;

  /// The base path where this panel is mounted.
  String get path => _path;

  /// The registered resources in this panel.
  List<Resource> get resources => List.unmodifiable(_resources);

  /// The database configuration for this panel.
  DatabaseConfig? get databaseConfig => _databaseConfig;

  /// Sets the unique identifier for this panel.
  void setId(String id) {
    _id = id;
  }

  /// Sets the base path where this panel is mounted.
  void setPath(String path) {
    _path = path;
  }

  /// Configures the database connection for this panel.
  void setDatabase(DatabaseConfig config) {
    _databaseConfig = config;
  }

  /// Registers resources with this panel.
  void registerResources(List<Resource> resources) {
    _resources.addAll(resources);
  }

  /// Validates the configuration.
  void validate() {
    if (_path.isEmpty) {
      throw StateError('Panel path cannot be empty');
    }
    if (_id.isEmpty) {
      throw StateError('Panel id cannot be empty');
    }

    // Validate all resource table configurations
    print('🔍 Validating resource configurations...');
    for (final resource in _resources) {
      try {
        resource.validateTableConfiguration();
        print('  ✅ ${resource.runtimeType}');
      } catch (e) {
        print('  ❌ ${resource.runtimeType}');
        rethrow;
      }
    }
    print('✅ All resource configurations are valid\n');
  }
}
