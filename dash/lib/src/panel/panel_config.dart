import 'dart:async';

import 'package:dash/src/database/database_config.dart';
import 'package:dash/src/panel/dev_console.dart';
import 'package:dash/src/panel/panel_colors.dart';
import 'package:dash/src/plugin/asset.dart';
import 'package:dash/src/plugin/navigation_item.dart';
import 'package:dash/src/plugin/plugin.dart';
import 'package:dash/src/plugin/render_hook.dart';
import 'package:dash/src/resource.dart';
import 'package:dash/src/widgets/widget.dart';
import 'package:shelf/shelf.dart';

/// Callback type for request hooks.
typedef RequestCallback = FutureOr<void> Function(Request request);

/// Configuration for a Dash panel.
///
/// Holds all the configuration data for a panel including
/// identification, resources, plugins, and database settings.
class PanelConfig {
  String _id = 'admin';
  String _path = '/admin';
  final List<Resource> _resources = [];
  final List<Widget> _widgets = [];
  final List<DevCommand> _devCommands = [];
  DatabaseConfig? _databaseConfig;
  PanelColors _colors = PanelColors.defaults;

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

  /// The registered widgets in this panel.
  List<Widget> get widgets => List.unmodifiable(_widgets);

  /// The database configuration for this panel.
  DatabaseConfig? get databaseConfig => _databaseConfig;

  /// Custom dev commands registered with this panel.
  List<DevCommand> get devCommands => List.unmodifiable(_devCommands);

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
      }
    }
  }

  /// Registers widgets with this panel.
  void registerWidgets(List<Widget> widgets) {
    _widgets.addAll(widgets);
  }

  /// Registers custom dev commands with this panel.
  void registerDevCommands(List<DevCommand> commands) {
    _devCommands.addAll(commands);
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
