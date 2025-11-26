import 'package:build/build.dart';
import 'package:dash/src/generators/model_generator.dart';
import 'package:source_gen/source_gen.dart';

/// Creates a builder for generating Dash model code.
Builder modelBuilder(BuilderOptions options) {
  return PartBuilder([ModelGenerator()], '.model.g.dart');
}
