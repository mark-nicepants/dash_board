import 'dart:async';

import '../auth/auth_service.dart';
import '../database/database_config.dart';
import '../database/query_builder.dart';
import '../model/model.dart';
import '../resource.dart';
import '../resources/resource_loader.dart';
import '../service_locator.dart';
import 'panel_config.dart';
import 'panel_server.dart';

/// The main entry point for a Dash admin panel.
///
/// A [Panel] is the core class that configures and runs your admin interface.
/// It manages resources, authentication, theming, routing, and database connections.
///
/// The Panel class now delegates specific responsibilities to specialized classes:
/// - [PanelConfig] - Manages configuration data
/// - [PanelServer] - Handles HTTP server lifecycle
/// - [PanelRouter] - Routes requests to appropriate pages
/// - [RequestHandler] - Processes special requests (login, logout)
///
/// Example:
/// ```dart
/// final panel = Panel()
///   ..setId('admin')
///   ..setPath('/admin')
///   ..database(DatabaseConfig.using(SqliteConnector('app.db')))
///   ..registerResources([
///     UserResource(),
///     PostResource(),
///   ]);
///
/// await panel.boot();
/// await panel.serve();
/// ```
class Panel {
  late final PanelConfig _config;
  late final AuthService _authService;
  PanelServer? _server;

  Panel() {
    _config = PanelConfig();
    _authService = AuthService();
  }

  /// The unique identifier for this panel.
  String get id => _config.id;

  /// The base path where this panel is mounted.
  String get path => _config.path;

  /// The registered resources in this panel.
  List<Resource> get resources => _config.resources;

  /// The database configuration for this panel.
  DatabaseConfig? get databaseConfig => _config.databaseConfig;

  /// The authentication service for this panel.
  AuthService get authService => _authService;

  /// Sets the unique identifier for this panel.
  Panel setId(String id) {
    _config.setId(id);
    return this;
  }

  /// Sets the base path where this panel is mounted.
  Panel setPath(String path) {
    _config.setPath(path);
    return this;
  }

  /// Configures the database connection for this panel.
  Panel database(DatabaseConfig config) {
    _config.setDatabase(config);
    return this;
  }

  /// Registers resources with this panel.
  Panel registerResources(List<Resource> resources) {
    _config.registerResources(resources);
    return this;
  }

  /// Creates a new query builder for database operations.
  /// Throws [StateError] if no database is configured.
  QueryBuilder query() {
    if (_config.databaseConfig == null) {
      throw StateError('No database configured. Call database() first.');
    }
    return QueryBuilder(_config.databaseConfig!.connector);
  }

  /// Boots the panel and returns it ready for use.
  ///
  /// This initializes the panel configuration and connects to the database.
  Future<Panel> boot() async {
    // Pull in any globally registered resources if none were provided manually.
    if (_config.resources.isEmpty) {
      final registeredResources = buildRegisteredResources();
      if (registeredResources.isNotEmpty) {
        _config.registerResources(registeredResources);
      }
    }

    // Validate configuration
    _config.validate();

    // Connect to database if configured
    if (_config.databaseConfig != null) {
      await _config.databaseConfig!.connect();
      // Set the static connector on Model class so all models can access it
      Model.setConnector(_config.databaseConfig!.connector);

      // Setup dependency injection
      await setupServiceLocator(config: _config, connector: _config.databaseConfig!.connector);

      // Create server after DI is set up (PanelRouter needs ResourceLoader from DI)
      final resourceLoader = inject<ResourceLoader>();
      _server = PanelServer(_config, _authService, resourceLoader);
    }

    return this;
  }

  /// Shuts down the panel and cleans up resources.
  ///
  /// This closes the database connection and stops the HTTP server.
  Future<void> shutdown() async {
    // Stop server
    if (_server?.isRunning ?? false) {
      await _server!.stop(force: true);
    }

    // Close database
    if (_config.databaseConfig != null) {
      await _config.databaseConfig!.close();
    }
  }

  /// Starts the HTTP server and serves the admin panel.
  ///
  /// [host] - The host to bind to (default: 'localhost')
  /// [port] - The port to listen on (default: 8080)
  Future<void> serve({String host = 'localhost', int port = 8080}) async {
    await boot();

    if (_server == null) {
      throw StateError('Server not initialized. Database configuration is required.');
    }

    await _server!.start(host: host, port: port);
  }
}
