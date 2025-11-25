import 'package:get_it/get_it.dart';

import 'database/database_connector.dart';
import 'model/model.dart';
import 'panel/panel_config.dart';
import 'resource.dart';
import 'resources/resource_loader.dart';

/// Global service locator instance.
final inject = GetIt.instance;

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
