import 'dart:async';

import 'package:dash/dash.dart';
import 'package:shelf/shelf.dart';

/// Callback type for request hooks.
typedef RequestCallback = FutureOr<void> Function(Request request);

/// Callback type for custom route handlers.
typedef CustomRouteHandler = FutureOr<Response> Function(Request request);

/// Configuration for a Dash panel.
///
/// Holds all the configuration data for a panel including
/// identification, resources, plugins, and database settings.
class PanelConfig {
  String _id = 'admin';
  String _path = '/admin';
  final List<Resource> _resources = [];
  final List<Page> _pages = [];
  final List<Widget> _widgets = [];
  PanelColors _colors = PanelColors.defaults;

  DatabaseConfig? _databaseConfig;
  final List<TableSchema> _additionalSchemas = [];

  List<TableSchema> get additionalSchemas => List.unmodifiable(_additionalSchemas);

  // Plugin system
  final Map<String, Plugin> _plugins = {};
  final List<NavigationItem> _navigationItems = [];
  final RenderHookRegistry _renderHookRegistry = RenderHookRegistry();
  final AssetRegistry _assetRegistry = AssetRegistry();

  /// The unique identifier for this panel.
  String get id => _id;

  /// The base path where this panel is mounted.
  String get path => _path;

  /// The registered resources in this panel.
  List<Resource> get resources => List.unmodifiable(_resources);

  /// The registered custom pages in this panel.
  List<Page> get pages => List.unmodifiable(_pages);

  /// The registered widgets in this panel.
  List<Widget> get widgets => List.unmodifiable(_widgets);

  /// The database configuration for this panel.
  DatabaseConfig? get databaseConfig => _databaseConfig;

  /// The color configuration for this panel.
  PanelColors get colors => _colors;

  /// The registered plugins in this panel.
  Map<String, Plugin> get plugins => Map.unmodifiable(_plugins);

  /// Custom navigation items added by plugins.
  List<NavigationItem> get navigationItems => List.unmodifiable(_navigationItems);

  /// The render hook registry for this panel.
  RenderHookRegistry get renderHooks => _renderHookRegistry;

  /// The asset registry for this panel.
  AssetRegistry get assets => _assetRegistry;

  // Custom routes registered by plugins
  final Map<String, CustomRouteHandler> _customRoutes = {};

  /// The registered custom routes.
  Map<String, CustomRouteHandler> get customRoutes => Map.unmodifiable(_customRoutes);

  /// Registers a custom route handler.
  void registerCustomRoute(String path, CustomRouteHandler handler) {
    _customRoutes[path] = handler;
  }

  // Event hooks
  final List<RequestCallback> _requestCallbacks = [];

  /// Registers a callback to be called on each request.
  void addRequestCallback(RequestCallback callback) {
    _requestCallbacks.add(callback);
  }

  /// Fires all request callbacks.
  Future<void> fireRequestCallbacks(Request request) async {
    for (final callback in _requestCallbacks) {
      await callback(request);
    }
  }

  /// The registered request callbacks.
  List<RequestCallback> get requestCallbacks => List.unmodifiable(_requestCallbacks);

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

  /// Sets the color configuration for this panel.
  void setColors(PanelColors colors) {
    _colors = colors;
  }

  /// Registers resources with this panel.
  void registerResources(List<Resource> resources) {
    for (final resource in resources) {
      final alreadyExists = _resources.any((existing) => existing.runtimeType == resource.runtimeType);
      if (!alreadyExists) {
        _resources.add(resource);

        ComponentRegistry.registerFactory('resource-index-${resource.slug}', resource.indexComponentFactory);
      }
    }
  }

  /// Registers custom pages with this panel.
  ///
  /// Pages with [Page.shouldRegisterNavigation] set to true will also
  /// be added to the sidebar navigation.
  void registerPages(List<Page> pages) {
    for (final page in pages) {
      final alreadyExists = _pages.any((existing) => existing.slug == page.slug);
      if (!alreadyExists) {
        _pages.add(page);

        // Auto-register navigation item if page wants it
        if (page.shouldRegisterNavigation) {
          _navigationItems.add(
            NavigationItem.make(page.title)
                .url('/pages/${page.slug}')
                .group(page.navigationGroup!)
                .sort(page.navigationSort)
                .icon(page.icon ?? HeroIcons.document),
          );
        }
      }
    }
  }

  /// Registers widgets with this panel.
  void registerWidgets(List<Widget> widgets) {
    _widgets.addAll(widgets);
  }

  // ============================================================
  // Plugin Methods
  // ============================================================

  /// Registers a plugin with this panel.
  ///
  /// Throws [StateError] if a plugin with the same ID is already registered.
  void registerPlugin(Plugin plugin) {
    final id = plugin.getId();
    if (_plugins.containsKey(id)) {
      throw StateError('Plugin with ID "$id" is already registered');
    }
    _plugins[id] = plugin;
  }

  /// Gets a plugin by its ID.
  ///
  /// Throws [StateError] if the plugin is not found.
  Plugin getPlugin(String id) {
    final plugin = _plugins[id];
    if (plugin == null) {
      throw StateError('Plugin with ID "$id" not found');
    }
    return plugin;
  }

  /// Checks if a plugin with the given ID is registered.
  bool hasPlugin(String id) => _plugins.containsKey(id);

  /// Registers custom navigation items.
  void registerNavigationItems(List<NavigationItem> items) {
    _navigationItems.addAll(items);
  }

  /// Registers a render hook.
  void registerRenderHook(RenderHook hook, RenderHookBuilder builder) {
    _renderHookRegistry.register(hook, builder);
  }

  /// Registers assets (CSS/JS).
  void registerAssets(List<Asset> assets) {
    for (final asset in assets) {
      _assetRegistry.register(asset);
    }
  }

  void registerAdditionalSchemas(List<TableSchema> schemas) {
    _additionalSchemas.addAll(schemas);
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
    for (final resource in _resources) {
      resource.validateTableConfiguration();
    }
  }
}
