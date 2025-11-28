import 'package:dash/src/database/database_connector.dart';
import 'package:dash/src/model/model.dart';
import 'package:dash/src/panel/panel_colors.dart';
import 'package:dash/src/panel/panel_config.dart';
import 'package:dash/src/resource.dart';
import 'package:dash/src/storage/storage.dart';
import 'package:dash/src/utils/resource_loader.dart';
import 'package:get_it/get_it.dart';

/// Global service locator instance.
final inject = GetIt.instance;

/// Gets the current panel colors from the registered config.
///
/// Returns [PanelColors.defaults] if no config is registered yet.
PanelColors get panelColors {
  if (inject.isRegistered<PanelConfig>()) {
    return inject<PanelConfig>().colors;
  }
  return PanelColors.defaults;
}

/// Gets a storage URL for a file path on a specific disk.
///
/// Uses the registered [StorageManager] to get the URL with the proper prefix.
/// Returns the path unchanged if it's already a full URL or absolute path.
String getStorageUrl(String path, {String? disk}) {
  // If it's already a full URL or absolute path, return as-is
  if (path.startsWith('http://') || path.startsWith('https://') || path.startsWith('/')) {
    return path;
  }

  // Use StorageManager if registered
  if (inject.isRegistered<StorageManager>()) {
    final storageManager = inject<StorageManager>();
    try {
      final storage = storageManager.disk(disk);
      return storage.url(path);
    } catch (_) {
      // Disk not found, fall through to fallback
    }
  }

  // Fallback: construct URL manually
  String basePath = '/admin';
  if (inject.isRegistered<PanelConfig>()) {
    basePath = inject<PanelConfig>().path;
  }
  if (disk != null) {
    return '$basePath/storage/$disk/$path';
  }
  return '$basePath/storage/$path';
}

typedef _ResourceFactory = Resource Function();

const _resourceFactoriesKey = '__dash_resource_factories__';

Map<Type, _ResourceFactory> _resourceFactoryMap() {
  if (!inject.isRegistered<Map<Type, _ResourceFactory>>(instanceName: _resourceFactoriesKey)) {
    inject.registerSingleton<Map<Type, _ResourceFactory>>(
      <Type, _ResourceFactory>{},
      instanceName: _resourceFactoriesKey,
    );
  }
  return inject<Map<Type, _ResourceFactory>>(instanceName: _resourceFactoriesKey);
}

/// Registers a resource factory for a model type.
void registerResourceFactory<T extends Model>(Resource<T> Function() factory) {
  _resourceFactoryMap()[T] = () => factory();
}

/// Returns true if a resource factory has been registered for the model type.
bool hasResourceFactoryFor<T extends Model>() {
  return _resourceFactoryMap().containsKey(T);
}

/// Builds fresh resource instances using the registered factories.
List<Resource> buildRegisteredResources() {
  return _resourceFactoryMap().values.map((factory) => factory()).toList();
}

/// Clears all registered resource factories.
void clearResourceFactories() {
  _resourceFactoryMap().clear();
}

/// Sets up dependency injection for the Dash framework.
///
/// This registers core services like:
/// - PanelConfig: The panel configuration
/// - DatabaseConnector: The database connection
/// - ResourceLoader: Static asset loader
///
/// Call this during Panel.boot() before starting the server.
Future<void> setupServiceLocator({required PanelConfig config, required DatabaseConnector connector}) async {
  // Register panel config as singleton
  if (!inject.isRegistered<PanelConfig>()) {
    inject.registerSingleton<PanelConfig>(config);
  }

  // Register database connector as singleton
  if (!inject.isRegistered<DatabaseConnector>()) {
    inject.registerSingleton<DatabaseConnector>(connector);
  }

  // Initialize and register resource loader
  if (!inject.isRegistered<ResourceLoader>()) {
    final resourceLoader = await ResourceLoader.initialize();
    inject.registerSingleton<ResourceLoader>(resourceLoader);
  }
}

/// Resets the service locator (useful for testing).
Future<void> resetServiceLocator() async {
  await inject.reset();
}
