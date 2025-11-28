import 'dart:async';

import 'package:dash/src/auth/auth_service.dart';
import 'package:dash/src/auth/authenticatable.dart';
import 'package:dash/src/database/database_config.dart';
import 'package:dash/src/database/query_builder.dart';
import 'package:dash/src/model/model.dart';
import 'package:dash/src/model/model_metadata.dart';
import 'package:dash/src/panel/dev_console.dart';
import 'package:dash/src/panel/panel_config.dart';
import 'package:dash/src/panel/panel_server.dart';
import 'package:dash/src/resource.dart';
import 'package:dash/src/service_locator.dart';
import 'package:dash/src/utils/resource_loader.dart';

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
///   ..authModel<User>()  // Register User as the auth model
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
  AuthService<Model>? _authService;
  PanelServer? _server;

  // Auth model configuration
  Type? _authModelType;
  UserResolver<Model>? _customUserResolver;

  Panel() {
    _config = PanelConfig();
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
  ///
  /// Throws [StateError] if no auth model has been configured.
  AuthService<Model> get authService {
    if (_authService == null) {
      throw StateError('No auth model configured. Call authModel<YourUser>() before accessing authService.');
    }
    return _authService!;
  }

  /// Configures the user model for authentication.
  ///
  /// The model type [T] must extend [Model] and implement [Authenticatable].
  /// This enables database-backed authentication using your own user model.
  ///
  /// By default, users are resolved by querying the database using the
  /// identifier field configured in the model's [Authenticatable] implementation.
  ///
  /// Example:
  /// ```dart
  /// final panel = Panel()
  ///   ..authModel<User>()  // User must implement Authenticatable
  ///   ..database(...)
  ///   ..registerResources([...]);
  /// ```
  ///
  /// For custom user resolution, provide a [userResolver]:
  /// ```dart
  /// panel.authModel<User>(
  ///   userResolver: (identifier) => User.query()
  ///     .where('email', '=', identifier)
  ///     .where('is_active', '=', true)
  ///     .first(),
  /// );
  /// ```
  Panel authModel<T extends Model>({UserResolver<T>? userResolver}) {
    _authModelType = T;
    if (userResolver != null) {
      _customUserResolver = (identifier) async {
        final user = await userResolver(identifier);
        return user;
      };
    }
    return this;
  }

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

  /// Adds custom dev commands to this panel.
  ///
  /// These commands will be available in the interactive dev console
  /// when running the server in development mode.
  ///
  /// Example:
  /// ```dart
  /// panel.addDevCommands([
  ///   DevCommand(
  ///     name: 'seed',
  ///     description: 'Seed the database with test data',
  ///     handler: (args) async {
  ///       // Your seeding logic here
  ///     },
  ///   ),
  /// ]);
  /// ```
  Panel addDevCommands(List<DevCommand> commands) {
    _config.registerDevCommands(commands);
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

      // Initialize auth service if auth model is configured
      if (_authModelType != null) {
        _initializeAuthService();
      }

      // Create server after DI is set up (PanelRouter needs ResourceLoader from DI)
      final resourceLoader = inject<ResourceLoader>();
      _server = PanelServer(_config, authService, resourceLoader);
    }

    return this;
  }

  /// Initializes the auth service with the configured user model.
  void _initializeAuthService() {
    if (_authModelType == null) {
      throw StateError('No auth model type configured');
    }

    // Get model metadata to access the factory
    final metadata = getModelMetadataByName(_authModelType.toString());
    if (metadata == null) {
      throw StateError(
        'Model $_authModelType not registered. '
        'Make sure to call $_authModelType.register() before Panel.boot().',
      );
    }

    // Create user resolver using model's query builder
    final userResolver = _customUserResolver ?? _createDefaultUserResolver(metadata);

    _authService = AuthService<Model>(userResolver: userResolver, panelId: _config.id);
  }

  /// Creates a default user resolver that queries by the auth identifier field.
  UserResolver<Model> _createDefaultUserResolver(ModelMetadata<Model> metadata) {
    return (String identifier) async {
      // Create instance to get auth identifier field name
      final instance = metadata.modelFactory();
      if (instance is! Authenticatable) {
        throw StateError('Model ${instance.runtimeType} must implement Authenticatable mixin');
      }
      final identifierField = instance.getAuthIdentifierName();

      // Query database for user
      final connector = _config.databaseConfig!.connector;
      final results = await connector.query('SELECT * FROM ${instance.table} WHERE $identifierField = ? LIMIT 1', [
        identifier,
      ]);

      if (results.isEmpty) {
        return null;
      }

      // Create and populate model instance
      final user = metadata.modelFactory();
      user.fromMap(results.first);
      return user;
    };
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
