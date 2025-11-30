import 'dart:async';

import 'package:dash/src/auth/auth_service.dart';
import 'package:dash/src/auth/authenticatable.dart';
import 'package:dash/src/auth/session_store.dart';
import 'package:dash/src/database/database_config.dart';
import 'package:dash/src/database/migrations/schema_definition.dart';
import 'package:dash/src/database/query_builder.dart';
import 'package:dash/src/interactive/component_registry.dart';
import 'package:dash/src/model/model.dart';
import 'package:dash/src/panel/dev_console.dart';
import 'package:dash/src/panel/panel_colors.dart';
import 'package:dash/src/panel/panel_config.dart';
import 'package:dash/src/panel/panel_server.dart';
import 'package:dash/src/plugin/asset.dart';
import 'package:dash/src/plugin/navigation_item.dart';
import 'package:dash/src/plugin/plugin.dart';
import 'package:dash/src/plugin/render_hook.dart';
import 'package:dash/src/resource.dart';
import 'package:dash/src/service_locator.dart';
import 'package:dash/src/storage/storage.dart';
import 'package:dash/src/utils/resource_loader.dart';
import 'package:dash/src/widgets/widget.dart' as dash;
import 'package:jaspr/jaspr.dart';

// Re-export RequestCallback from panel_config for external use
export 'package:dash/src/panel/panel_config.dart' show RequestCallback;

/// Callback type for model event hooks.
typedef ModelCallback = FutureOr<void> Function(Model model);

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
  SessionStore? _sessionStore;

  // Storage configuration
  StorageConfig? _storageConfig;

  // Event hooks (model callbacks still stored here, request callbacks moved to PanelConfig)
  final List<ModelCallback> _modelCreatedCallbacks = [];
  final List<ModelCallback> _modelUpdatedCallbacks = [];
  final List<ModelCallback> _modelDeletedCallbacks = [];

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

  /// Configures the color scheme for this panel.
  ///
  /// Colors are specified as Tailwind CSS color names (without shade),
  /// e.g., 'cyan', 'blue', 'indigo', 'violet', 'purple', etc.
  ///
  /// Example:
  /// ```dart
  /// final panel = Panel()
  ///   ..colors(PanelColors(
  ///     primary: 'indigo',  // Use indigo as primary color
  ///     danger: 'rose',     // Use rose for destructive actions
  ///   ));
  /// ```
  ///
  /// Default colors:
  /// - primary: 'cyan'
  /// - danger: 'red'
  /// - warning: 'amber'
  /// - success: 'green'
  /// - info: 'blue'
  Panel colors(PanelColors colors) {
    _config.setColors(colors);
    return this;
  }

  /// Configures storage for file uploads.
  ///
  /// Example:
  /// ```dart
  /// final panel = Panel()
  ///   ..storage(StorageConfig()
  ///     ..defaultDisk = 'public'
  ///     ..disks = {
  ///       'local': LocalStorage(basePath: 'storage/app'),
  ///       'public': LocalStorage(basePath: 'storage/public', urlPrefix: '/admin/storage/public'),
  ///     });
  /// ```
  Panel storage(StorageConfig config) {
    _storageConfig = config;
    return this;
  }

  /// Configures the session store for persisting user sessions.
  ///
  /// By default, sessions are stored in memory and lost when the server restarts.
  /// Use [FileSessionStore] to persist sessions to disk.
  ///
  /// Example:
  /// ```dart
  /// final panel = Panel()
  ///   ..sessionStore(FileSessionStore('storage/sessions'));
  /// ```
  Panel sessionStore(SessionStore store) {
    _sessionStore = store;
    return this;
  }

  /// Registers resources with this panel.
  Panel registerResources(List<Resource> resources) {
    _config.registerResources(resources);
    return this;
  }

  /// Registers additional table schemas for migrations.
  ///
  /// Use this to register schemas for models that aren't tied to resources,
  /// such as internal plugin tables. These schemas will be included when
  /// using [MigrationConfig.fromResources()].
  ///
  /// Example:
  /// ```dart
  /// // In a plugin's register() method:
  /// panel.registerSchemas([Metric.schema]);
  /// ```
  Panel registerSchemas(List<TableSchema> schemas) {
    _config.registerAdditionalSchemas(schemas);
    return this;
  }

  // ============================================================
  // Interactive Components
  // ============================================================

  /// Registers interactive component factories for wire: directive handling.
  ///
  /// Interactive components are Livewire-like server-driven components
  /// that maintain state on the server and update via wire: directives.
  ///
  /// The factory is called to create an instance, and the component's
  /// `componentName` (class name) is used as the registration key.
  ///
  /// Example:
  /// ```dart
  /// panel.interactiveComponents([
  ///   Counter.make,
  ///   SearchBox.make,
  /// ]);
  /// ```
  ///
  /// Then use in your pages:
  /// ```dart
  /// final counter = Counter(initialCount: 5);
  /// return counter.build(); // Renders with wire: wrapper attributes
  /// ```
  Panel interactiveComponents(List<InteractiveComponentFactory> factories) {
    for (final factory in factories) {
      // Create a temporary instance to get the component name
      final instance = factory();
      ComponentRegistry.registerFactory(instance.componentName, factory);
    }
    return this;
  }

  /// Registers a single interactive component factory.
  ///
  /// If [name] is omitted, the component's class name is used.
  ///
  /// Example:
  /// ```dart
  /// // Uses class name 'Counter' as the registration key
  /// panel.interactiveComponent(Counter.make);
  ///
  /// // Or with explicit name
  /// panel.interactiveComponent(Counter.make, name: 'my-counter');
  /// ```
  Panel interactiveComponent(InteractiveComponentFactory factory, {String? name}) {
    final registrationName = name ?? factory().componentName;
    ComponentRegistry.registerFactory(registrationName, factory);
    return this;
  }

  // ============================================================
  // Plugin Methods
  // ============================================================

  /// Registers a single plugin with this panel.
  ///
  /// The plugin's `register()` method is called immediately.
  /// The `boot()` method is called later during `Panel.boot()`.
  ///
  /// Example:
  /// ```dart
  /// final panel = Panel()
  ///   ..plugin(BlogPlugin.make()
  ///     .commentsEnabled(true));
  /// ```
  Panel plugin(Plugin plugin) {
    plugin.register(this);
    _config.registerPlugin(plugin);
    return this;
  }

  /// Registers multiple plugins with this panel.
  ///
  /// Example:
  /// ```dart
  /// final panel = Panel()
  ///   ..plugins([
  ///     BlogPlugin.make(),
  ///     AnalyticsPlugin.make(),
  ///   ]);
  /// ```
  Panel plugins(List<Plugin> plugins) {
    for (final p in plugins) {
      plugin(p);
    }
    return this;
  }

  /// Gets a registered plugin by its ID.
  ///
  /// Throws [StateError] if the plugin is not found.
  ///
  /// Example:
  /// ```dart
  /// final blogPlugin = panel.getPlugin<BlogPlugin>('blog');
  /// ```
  T getPlugin<T extends Plugin>(String id) {
    return _config.getPlugin(id) as T;
  }

  /// Checks if a plugin with the given ID is registered.
  bool hasPlugin(String id) => _config.hasPlugin(id);

  /// Adds custom navigation items to the sidebar.
  ///
  /// These items appear alongside resource navigation links.
  ///
  /// Example:
  /// ```dart
  /// panel.navigationItems([
  ///   NavigationItem.make('Documentation')
  ///     .url('https://docs.example.com')
  ///     .icon(HeroIcons.bookOpen)
  ///     .openInNewTab(),
  /// ]);
  /// ```
  Panel navigationItems(List<NavigationItem> items) {
    _config.registerNavigationItems(items);
    return this;
  }

  /// Registers a render hook to inject content at specific locations.
  ///
  /// Multiple hooks can be registered for the same location.
  ///
  /// Example:
  /// ```dart
  /// panel.renderHook(
  ///   RenderHook.sidebarFooter,
  ///   () => div([text('v1.0.0')]),
  /// );
  /// ```
  Panel renderHook(RenderHook hook, Component Function() builder) {
    _config.registerRenderHook(hook, builder);
    return this;
  }

  /// Registers widgets to be displayed on the dashboard.
  ///
  /// Widgets are self-contained UI components that can display
  /// statistics, charts, tables, or custom content.
  ///
  /// Example:
  /// ```dart
  /// panel.widgets([
  ///   UserStatsWidget.make(),
  ///   RecentOrdersWidget.make(),
  /// ]);
  /// ```
  Panel widgets(List<dash.Widget> widgets) {
    _config.registerWidgets(widgets);
    return this;
  }

  /// Registers CSS/JS assets to be loaded in the panel.
  ///
  /// Example:
  /// ```dart
  /// panel.assets([
  ///   CssAsset.url('my-plugin', 'https://cdn.example.com/styles.css'),
  ///   JsAsset.inline('my-plugin', 'console.log("loaded");'),
  /// ]);
  /// ```
  Panel assets(List<Asset> assets) {
    _config.registerAssets(assets);
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

  // ============================================================
  // Event Hooks
  // ============================================================

  /// Registers a callback to be called on each request.
  ///
  /// This is useful for tracking page views or other request-based metrics.
  ///
  /// Example:
  /// ```dart
  /// panel.onRequest((request) async {
  ///   await metrics.pageView(request.requestedUri.path);
  /// });
  /// ```
  Panel onRequest(RequestCallback callback) {
    _config.addRequestCallback(callback);
    return this;
  }

  /// Registers a callback to be called when a model is created.
  ///
  /// Example:
  /// ```dart
  /// panel.onModelCreated((model) async {
  ///   await metrics.modelCreated(model.runtimeType.toString());
  /// });
  /// ```
  Panel onModelCreated(ModelCallback callback) {
    _modelCreatedCallbacks.add(callback);
    return this;
  }

  /// Registers a callback to be called when a model is updated.
  Panel onModelUpdated(ModelCallback callback) {
    _modelUpdatedCallbacks.add(callback);
    return this;
  }

  /// Registers a callback to be called when a model is deleted.
  Panel onModelDeleted(ModelCallback callback) {
    _modelDeletedCallbacks.add(callback);
    return this;
  }

  /// Fires model created callbacks.
  Future<void> fireModelCreated(Model model) async {
    for (final callback in _modelCreatedCallbacks) {
      await callback(model);
    }
  }

  /// Fires model updated callbacks.
  Future<void> fireModelUpdated(Model model) async {
    for (final callback in _modelUpdatedCallbacks) {
      await callback(model);
    }
  }

  /// Fires model deleted callbacks.
  Future<void> fireModelDeleted(Model model) async {
    for (final callback in _modelDeletedCallbacks) {
      await callback(model);
    }
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
    // Auto-register resources from registered models
    final autoResources = buildRegisteredResources();
    if (autoResources.isNotEmpty) {
      _config.registerResources(autoResources);
    }

    // Validate configuration
    _config.validate();

    // Connect to database if configured
    if (_config.databaseConfig != null) {
      await _config.databaseConfig!.connect(_config);
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

      // Configure storage if set
      if (_storageConfig != null) {
        _server!.configureStorage(_storageConfig!);

        // Register StorageManager in service locator for URL generation
        if (!inject.isRegistered<StorageManager>()) {
          inject.registerSingleton<StorageManager>(_storageConfig!.createManager());
        }
      }

      // Boot all registered plugins
      await _bootPlugins();
    }

    return this;
  }

  /// Boots all registered plugins.
  Future<void> _bootPlugins() async {
    for (final plugin in _config.plugins.values) {
      await plugin.boot(this);
    }
  }

  /// Initializes the auth service with the configured user model.
  void _initializeAuthService() {
    if (_authModelType == null) {
      throw StateError('No auth model type configured');
    }

    // Convert model type to slug (e.g., "User" -> "user")
    final typeString = _authModelType.toString();
    final modelSlug = _toSnakeCase(typeString);

    // Try to get the model instance from DI to verify it's registered
    Model instance;
    try {
      instance = modelInstanceFromSlug<Model>(modelSlug);
    } catch (_) {
      throw StateError(
        'Model $_authModelType not registered. '
        'Make sure to call $_authModelType.register() before Panel.boot().',
      );
    }

    // Create user resolver using model's query builder
    final userResolver = _customUserResolver ?? _createDefaultUserResolver(modelSlug, instance);

    _authService = AuthService<Model>(userResolver: userResolver, panelId: _config.id, sessionStore: _sessionStore);
  }

  /// Converts a string to snake_case.
  String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(RegExp(r'[A-Z]'), (match) => '_${match.group(0)!.toLowerCase()}')
        .replaceFirst(RegExp(r'^_'), '');
  }

  /// Creates a default user resolver that queries by the auth identifier field.
  UserResolver<Model> _createDefaultUserResolver(String modelSlug, Model templateInstance) {
    return (String identifier) async {
      // Use template instance to get auth identifier field name
      if (templateInstance is! Authenticatable) {
        throw StateError('Model ${templateInstance.runtimeType} must implement Authenticatable mixin');
      }
      final identifierField = templateInstance.getAuthIdentifierName();

      // Query database for user
      final connector = _config.databaseConfig!.connector;
      final results = await connector.query(
        'SELECT * FROM ${templateInstance.table} WHERE $identifierField = ? LIMIT 1',
        [identifier],
      );

      if (results.isEmpty) {
        return null;
      }

      // Create and populate model instance
      final user = modelInstanceFromSlug<Model>(modelSlug);
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
