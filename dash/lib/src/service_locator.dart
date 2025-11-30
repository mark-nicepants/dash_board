import 'package:dash/dash.dart';
import 'package:dash/src/utils/resource_loader.dart';
import 'package:get_it/get_it.dart';

/// Global service locator instance.
final inject = GetIt.instance;

/// Registry of registered model slugs.
/// Populated when models call their register() method.
final Set<String> _registeredModelSlugs = {};

/// Tracks a model slug as registered.
void trackModelSlug(String slug) {
  _registeredModelSlugs.add(slug);
}

/// Gets all registered model slugs.
Set<String> get registeredModelSlugs => Set.unmodifiable(_registeredModelSlugs);

/// Clears registered model slugs (for testing).
void clearRegisteredModelSlugs() {
  _registeredModelSlugs.clear();
}

/// Gets the current panel colors from the registered config.
///
/// Returns [PanelColors.defaults] if no config is registered yet.
PanelColors get panelColors {
  if (inject.isRegistered<PanelConfig>()) {
    return inject<PanelConfig>().colors;
  }
  return PanelColors.defaults;
}

T modelInstanceFromSlug<T extends Model>(String slug) {
  return inject<T>(instanceName: 'model:$slug');
}

/// Gets a resource instance by model slug.
Resource resourceFromSlug(String slug) {
  return inject<Resource>(instanceName: 'resource:$slug');
}

/// Builds all registered resources.
///
/// Returns a list of Resource instances for all models that called register().
List<Resource> buildRegisteredResources() {
  return _registeredModelSlugs.map(resourceFromSlug).toList();
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
