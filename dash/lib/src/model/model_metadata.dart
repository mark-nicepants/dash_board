import 'package:dash_board/src/model/model.dart';

/// Metadata describing how to construct a model.
class ModelMetadata<T extends Model> {
  const ModelMetadata({required this.modelFactory});

  final T Function() modelFactory;
}
