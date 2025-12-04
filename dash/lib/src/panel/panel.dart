import 'dart:async';

import 'package:dash/src/auth/auth_service.dart';
import 'package:dash/src/auth/session_store.dart';
import 'package:dash/src/components/interactive/component_registry.dart';
import 'package:dash/src/database/database_config.dart';
import 'package:dash/src/database/migrations/schema_definition.dart';
import 'package:dash/src/database/query_builder.dart';
import 'package:dash/src/events/events.dart';
import 'package:dash/src/model/model.dart';
import 'package:dash/src/page/page.dart';
import 'package:dash/src/panel/panel_auth.dart';
import 'package:dash/src/panel/panel_colors.dart';
import 'package:dash/src/panel/panel_config.dart';
import 'package:dash/src/panel/panel_server.dart';
import 'package:dash/src/panel/panel_storage.dart';
import 'package:dash/src/plugin/asset.dart';
import 'package:dash/src/plugin/navigation_item.dart';
import 'package:dash/src/plugin/plugin.dart';
import 'package:dash/src/plugin/render_hook.dart';
import 'package:dash/src/resource.dart';
import 'package:dash/src/service_locator.dart';
import 'package:dash/src/settings/settings_service.dart';
import 'package:dash/src/storage/storage.dart';
import 'package:dash/src/utils/resource_loader.dart';
import 'package:dash/src/widgets/widget.dart' as dash;
import 'package:jaspr/jaspr.dart';

// Re-export callback types from panel_config for external use
export 'package:dash/src/panel/panel_config.dart' show RequestCallback, CustomRouteHandler;

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
  PanelServer? _server;
  final PanelAuthManager _authManager = PanelAuthManager();
  final PanelStorageManager _storageManager = PanelStorageManager();

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
    return _authManager.authService;
  }

  /// The settings service for key-value configuration storage.
  ///
  /// Returns the registered [SettingsService] instance for storing
  /// and retrieving application and plugin settings.
  ///
  /// Throws [StateError] if the service is not registered (call after boot).
  ///
  /// Example:
  /// ```dart
  /// // Get a string setting
  /// final appName = await panel.settings.getString('app.name');
  ///
  /// // Set a value
  /// await panel.settings.set('app.debug', true);
  /// ```
  SettingsService get settings {
    if (!inject.isRegistered<SettingsService>()) {
      throw StateError('SettingsService not registered. Call boot() first.');
    }
    return inject<SettingsService>();
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
    _authManager.authModel<T>(userResolver: userResolver);
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
  ///   ..storage(StorageConfig(
  ///     defaultDisk: 'public',
  ///     disks: {
  ///       'local': LocalStorage(basePath: 'storage/app'),
  ///       'public': LocalStorage(basePath: 'storage/public', urlPrefix: '/admin/storage/public'),
  ///     },
  ///   ));
  /// ```
  Panel storage(StorageConfig config) {
    _storageManager.configure(config);
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
    _authManager.sessionStore(store);
    return this;
  }

  /// Registers resources with this panel.
  Panel registerResources(List<Resource> resources) {
    _config.registerResources(resources);
    return this;
  }

  /// Registers custom pages with this panel.
  ///
  /// Pages are arbitrary non-CRUD pages that integrate with the admin layout.
  /// They are accessible at `/admin/pages/{slug}`.
  ///
  /// Example:
  /// ```dart
  /// final panel = Panel()
  ///   ..registerPages([
  ///     SettingsPage.make(),
  ///     AboutPage.make(),
  ///   ]);
  /// ```
  ///
  /// Pages can optionally register themselves in the sidebar navigation
  /// by setting [Page.navigationGroup].
  Panel registerPages(List<Page> pages) {
    _config.registerPages(pages);
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

  /// Registers a custom route handler for a specific path.
  ///
  /// This allows plugins to register custom GET routes that are handled
  /// before the standard resource routing. The path should be relative
  /// to the panel's base path.
  ///
  /// Example:
  /// ```dart
  /// panel.registerCustomRoute('/', (request) async {
  ///   return Response.ok('Homepage');
  /// });
  ///
  /// panel.registerCustomRoute('/about', (request) async {
  ///   final page = renderAboutPage();
  ///   return Response.ok(page);
  /// });
  /// ```
  Panel registerCustomRoute(String path, CustomRouteHandler handler) {
    _config.registerCustomRoute(path, handler);
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
  /// This uses the EventDispatcher internally for consistency.
  /// For more control, use `EventDispatcher.instance.listen<ModelCreatedEvent>()`.
  ///
  /// Example:
  /// ```dart
  /// panel.onModelCreated((model) async {
  ///   await metrics.modelCreated(model.runtimeType.toString());
  /// });
  /// ```
  Panel onModelCreated(ModelCallback callback) {
    EventDispatcher.instance.listen<ModelCreatedEvent>((event) async {
      await callback(event.model);
    });
    // Also add to legacy callbacks for backward compatibility
    _modelCreatedCallbacks.add(callback);
    return this;
  }

  /// Registers a callback to be called when a model is updated.
  ///
  /// This uses the EventDispatcher internally for consistency.
  /// For more control, use `EventDispatcher.instance.listen<ModelUpdatedEvent>()`.
  Panel onModelUpdated(ModelCallback callback) {
    EventDispatcher.instance.listen<ModelUpdatedEvent>((event) async {
      await callback(event.model);
    });
    // Also add to legacy callbacks for backward compatibility
    _modelUpdatedCallbacks.add(callback);
    return this;
  }

  /// Registers a callback to be called when a model is deleted.
  ///
  /// This uses the EventDispatcher internally for consistency.
  /// For more control, use `EventDispatcher.instance.listen<ModelDeletedEvent>()`.
  Panel onModelDeleted(ModelCallback callback) {
    // Note: ModelDeletedEvent doesn't have a model reference (it was deleted)
    // So we need a special wrapper that extracts model info from the event
    _modelDeletedCallbacks.add(callback);
    return this;
  }

  /// Fires model created callbacks.
  @Deprecated('Model events are now dispatched automatically via EventDispatcher')
  Future<void> fireModelCreated(Model model) async {
    for (final callback in _modelCreatedCallbacks) {
      await callback(model);
    }
  }

  /// Fires model updated callbacks.
  @Deprecated('Model events are now dispatched automatically via EventDispatcher')
  Future<void> fireModelUpdated(Model model) async {
    for (final callback in _modelUpdatedCallbacks) {
      await callback(model);
    }
  }

  /// Fires model deleted callbacks.
  @Deprecated('Model events are now dispatched automatically via EventDispatcher')
  Future<void> fireModelDeleted(Model model) async {
    for (final callback in _modelDeletedCallbacks) {
      await callback(model);
    }
  }

  /// Returns the EventDispatcher instance for direct event handling.
  ///
  /// Use this for more advanced event handling:
  /// ```dart
  /// panel.events.listen<ModelCreatedEvent>((event) {
  ///   print('Created: ${event.model.table}');
  ///   print('Changes: ${event.toPayload()}');
  /// });
  ///
  /// panel.events.listenTo('users.created', (event) {
  ///   sendWelcomeEmail(event);
  /// });
  /// ```
  EventDispatcher get events => EventDispatcher.instance;

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
      // Register core Dash schemas before migrations run
      _config.registerAdditionalSchemas([SettingsService.schema]);

      await _config.databaseConfig!.connect(_config);
      // Set the static connector on Model class so all models can access it
      Model.setConnector(_config.databaseConfig!.connector);

      // Setup dependency injection
      await setupServiceLocator(config: _config, connector: _config.databaseConfig!.connector);

      // Initialize auth service if configured
      _authManager.initialize(config: _config);

      // Create server after DI is set up (PanelRouter needs ResourceLoader from DI)
      final resourceLoader = inject<ResourceLoader>();
      _server = PanelServer(_config, authService, resourceLoader);

      // Configure storage if set
      _storageManager.applyToServer(_server!);

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
