import '../database/migrations/schema_definition.dart';
import '../service_locator.dart';
import 'model.dart';

/// Metadata describing how to construct a model and its schema.
class ModelMetadata<T extends Model> {
  const ModelMetadata({required this.modelFactory, this.schema});

  final T Function() modelFactory;
  final TableSchema? schema;
}

const _modelMetadataKeyPrefix = '__dash_model_metadata__';
const _modelMetadataRegistryKey = '__dash_model_metadata_keys__';

Set<String> _metadataKeys() {
  if (!inject.isRegistered<Set<String>>(instanceName: _modelMetadataRegistryKey)) {
    inject.registerSingleton<Set<String>>(<String>{}, instanceName: _modelMetadataRegistryKey);
  }
  return inject<Set<String>>(instanceName: _modelMetadataRegistryKey);
}

String _metadataKey<T extends Model>() => '$_modelMetadataKeyPrefix${T.toString()}';

/// Registers metadata for the given model type.
void registerModelMetadata<T extends Model>(ModelMetadata<T> metadata) {
  final key = _metadataKey<T>();

  if (inject.isRegistered<ModelMetadata<T>>(instanceName: key)) {
    inject.unregister<ModelMetadata<T>>(instanceName: key);
  }

  inject.registerSingleton<ModelMetadata<T>>(metadata, instanceName: key);
  _metadataKeys().add(key);
}

/// Retrieves metadata for a model type if available.
ModelMetadata<T>? getModelMetadata<T extends Model>() {
  final key = _metadataKey<T>();
  if (!inject.isRegistered<ModelMetadata<T>>(instanceName: key)) {
    return null;
  }
  return inject<ModelMetadata<T>>(instanceName: key);
}

/// Clears all registered model metadata. Useful for tests.
Future<void> clearModelMetadata() async {
  final keys = List<String>.from(_metadataKeys());
  for (final key in keys) {
    if (inject.isRegistered(instanceName: key)) {
      await inject.unregister(instanceName: key);
    }
    _metadataKeys().remove(key);
  }
}
