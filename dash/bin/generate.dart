import 'dart:io';

import 'package:dash/src/generators/schema_model_generator.dart';
import 'package:dash/src/generators/schema_parser.dart';
import 'package:path/path.dart' as path;

/// Command-line tool for generating Dart models from Dash schema YAML files.
///
/// Usage:
///   dart run dash:generate [schemas_dir] [output_dir]
///
/// Example:
///   dart run dash:generate schemas lib
///
/// This will:
///   1. Parse all .yaml files in the schemas directory
///   2. Generate model classes in lib/models/
void main(List<String> args) async {
  print('');
  print('🎯 Dash Schema Generator');
  print('========================');
  print('');

  if (args.isEmpty) {
    _printUsage();
    exit(1);
  }

  final schemasDir = args[0];
  final outputDir = args.length > 1 ? args[1] : 'lib';

  if (!Directory(schemasDir).existsSync()) {
    print('❌ Error: Schemas directory not found: $schemasDir');
    exit(1);
  }

  final parser = SchemaParser();

  // Find all schema files
  final schemaFiles = Directory(
    schemasDir,
  ).listSync().whereType<File>().where((f) => f.path.endsWith('.yaml') || f.path.endsWith('.yml')).toList();

  if (schemaFiles.isEmpty) {
    print('⚠️  No schema files found in $schemasDir');
    print('   Expected files with .yaml or .yml extension');
    exit(0);
  }

  print('📁 Found ${schemaFiles.length} schema file(s)');
  print('');

  // Create output directory
  final modelsDir = Directory(path.join(outputDir, 'models'));
  if (!modelsDir.existsSync()) {
    modelsDir.createSync(recursive: true);
  }

  // Process each schema
  for (final schemaFile in schemaFiles) {
    final fileName = path.basename(schemaFile.path);
    print('📝 Processing: $fileName');

    try {
      final schema = parser.parseFile(schemaFile.path);
      final modelGenerator = SchemaModelGenerator(schema);

      // Generate model class file
      final modelContent = modelGenerator.generate();
      final modelFileName = _toSnakeCase(schema.modelName);
      final modelFile = File(path.join(modelsDir.path, '$modelFileName.dart'));
      modelFile.writeAsStringSync(modelContent);
      print('   ✓ Generated model: ${path.relative(modelFile.path)}');

      print('');
    } catch (e, stack) {
      print('   ❌ Error: $e');
      print('   Stack: $stack');
      print('');
    }
  }

  print('✅ Generation complete!');
  print('');
  print('Next steps:');
  print('  1. Review the generated files');
  print('  2. Add any custom query scopes or lifecycle hooks to your models');
  print('  3. Register your models in your main.dart');
  print('');
}

String _toSnakeCase(String input) {
  return input
      .replaceAllMapped(RegExp(r'[A-Z]'), (match) => '_${match.group(0)!.toLowerCase()}')
      .replaceFirst(RegExp(r'^_'), '');
}

void _printUsage() {
  print('Usage: dart run dash:generate <schemas_dir> [output_dir]');
  print('');
  print('Arguments:');
  print('  schemas_dir  Directory containing .schema.yaml files');
  print('  output_dir   Output directory (default: lib)');
  print('');
  print('Example:');
  print('  dart run dash:generate schemas lib');
  print('');
}
