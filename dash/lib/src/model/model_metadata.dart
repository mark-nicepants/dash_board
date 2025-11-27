import 'package:dash/src/database/migrations/schema_definition.dart';
import 'package:dash/src/model/model.dart';
import 'package:dash/src/service_locator.dart';

/// Metadata describing how to construct a model and its schema.
class ModelMetadata<T extends Model> {
  const ModelMetadata({required this.modelFactory, this.schema});

  final T Function() modelFactory;
  final TableSchema? schema;
}

const _modelMetadataKeyPrefix = '__dash_model_metadata__';
const _modelMetadataRegistryKey = '__dash_model_metadata_keys__';
const _modelMetadataMapKey = '__dash_model_metadata_map__';

Set<String> _metadataKeys() {
  if (!inject.isRegistered<Set<String>>(instanceName: _modelMetadataRegistryKey)) {
    inject.registerSingleton<Set<String>>(<String>{}, instanceName: _modelMetadataRegistryKey);
  }
  return inject<Set<String>>(instanceName: _modelMetadataRegistryKey);
}

/// Gets or creates the metadata map for string-based lookup.
Map<String, ModelMetadata<Model>> _metadataMap() {
  if (!inject.isRegistered<Map<String, ModelMetadata<Model>>>(instanceName: _modelMetadataMapKey)) {
    inject.registerSingleton<Map<String, ModelMetadata<Model>>>(
      <String, ModelMetadata<Model>>{},
      instanceName: _modelMetadataMapKey,
    );
  }
  return inject<Map<String, ModelMetadata<Model>>>(instanceName: _modelMetadataMapKey);
}

String _metadataKey<T extends Model>() => '$_modelMetadataKeyPrefix${T.toString()}';

/// Registers metadata for the given model type.
void registerModelMetadata<T extends Model>(ModelMetadata<T> metadata) {
  final key = _metadataKey<T>();
  final typeName = T.toString();

  if (inject.isRegistered<ModelMetadata<T>>(instanceName: key)) {
    inject.unregister<ModelMetadata<T>>(instanceName: key);
  }

  inject.registerSingleton<ModelMetadata<T>>(metadata, instanceName: key);
  _metadataKeys().add(key);

  // Also store in the map for string-based lookup
  // We create a new ModelMetadata<Model> that wraps the factory
  _metadataMap()[typeName] = ModelMetadata<Model>(modelFactory: metadata.modelFactory, schema: metadata.schema);
}

/// Retrieves metadata for a model type if available.
ModelMetadata<T>? getModelMetadata<T extends Model>() {
  final key = _metadataKey<T>();
  if (!inject.isRegistered<ModelMetadata<T>>(instanceName: key)) {
    return null;
  }
  return inject<ModelMetadata<T>>(instanceName: key);
}

/// Retrieves model metadata by type name string.
/// This is useful when you only have the type name as a string.
ModelMetadata<Model>? getModelMetadataByName(String typeName) {
  return _metadataMap()[typeName];
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
  _metadataMap().clear();
}
