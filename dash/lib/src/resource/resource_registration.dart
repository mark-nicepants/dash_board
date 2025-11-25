import '../model/model.dart';
import '../resource.dart';
import '../service_locator.dart';

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
