import 'dart:io';

import 'package:dash/src/generators/models_barrel_generator.dart';
import 'package:dash/src/generators/resource_generator.dart';
import 'package:dash/src/generators/schema_model_generator.dart';
import 'package:dash/src/generators/schema_parser.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

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
  final outputDirArg = args.length > 1 ? args[1] : 'lib';
  final resolvedOutputDir = path.normalize(path.absolute(outputDirArg));

  if (!Directory(schemasDir).existsSync()) {
    print('❌ Error: Schemas directory not found: $schemasDir');
    exit(1);
  }

  // Determine package root based on the output directory so generated files import the correct package
  final packageRootPath = _determinePackageRoot(resolvedOutputDir);

  // Get package name from pubspec.yaml in the detected package root
  final packageName = _getPackageName(packageRootPath);
  if (packageName == null) {
    print('❌ Error: Could not find package name in pubspec.yaml at $packageRootPath');
    exit(1);
  }
  print('📦 Package: $packageName');

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
  final modelsDir = Directory(path.join(resolvedOutputDir, 'models'));
  if (!modelsDir.existsSync()) {
    modelsDir.createSync(recursive: true);
  }

  // Create resources directory
  final resourcesDir = Directory(path.join(resolvedOutputDir, 'resources'));
  if (!resourcesDir.existsSync()) {
    resourcesDir.createSync(recursive: true);
  }

  // Track successfully parsed schemas for barrel file generation
  final parsedSchemas = <ParsedSchema>[];

  // Process each schema
  for (final schemaFile in schemaFiles) {
    final fileName = path.basename(schemaFile.path);
    print('📝 Processing: $fileName');

    try {
      final schema = parser.parseFile(schemaFile.path);
      parsedSchemas.add(schema);
      final modelGenerator = SchemaModelGenerator(schema, packageName: packageName);

      // Generate model class file
      final modelContent = modelGenerator.generate();
      final modelFileName = _toSnakeCase(schema.modelName);
      final modelFile = File(path.join(modelsDir.path, '$modelFileName.dart'));
      modelFile.writeAsStringSync(modelContent);
      print('   ✓ Generated model: ${path.relative(modelFile.path)}');

      // Generate resource class file if it doesn't exist
      final resourceFileName = '${modelFileName}_resource.dart';
      final resourceFile = File(path.join(resourcesDir.path, resourceFileName));
      if (!resourceFile.existsSync()) {
        final resourceGenerator = ResourceGenerator(schema, packageName: packageName);
        final resourceContent = resourceGenerator.generate();
        resourceFile.writeAsStringSync(resourceContent);
        print('   ✓ Generated resource: ${path.relative(resourceFile.path)}');
      } else {
        print('   ℹ Resource exists: ${path.relative(resourceFile.path)}');
      }

      print('');
    } catch (e, stack) {
      print('   ❌ Error: $e');
      print('   Stack: $stack');
      print('');
    }
  }

  // Generate barrel file (models.dart) with registerAllModels function
  if (parsedSchemas.isNotEmpty) {
    print('📦 Generating barrel file...');
    final barrelGenerator = ModelsBarrelGenerator(parsedSchemas, packageName: packageName);
    final barrelContent = barrelGenerator.generate();
    final barrelFile = File(path.join(modelsDir.path, 'models.dart'));
    barrelFile.writeAsStringSync(barrelContent);
    print('   ✓ Generated: ${path.relative(barrelFile.path)}');
    print('');
  }

  print('✅ Generation complete!');
  print('');
  print('Next steps:');
  print('  1. Review and customize the generated resource files');
  print('  2. Register your models in main.dart:');
  print('');
  print("     import 'package:$packageName/models/models.dart';");
  print('');
  print('     void main() {');
  print('       registerAllModels();');
  print('       // ... rest of your app');
  print('     }');
  print('');
}

String _toSnakeCase(String input) {
  return input
      .replaceAllMapped(RegExp(r'[A-Z]'), (match) => '_${match.group(0)!.toLowerCase()}')
      .replaceFirst(RegExp(r'^_'), '');
}

/// Determines the package root directory based on the resolved output lib path.
String _determinePackageRoot(String resolvedOutputLibPath) {
  // If the output path points to a lib directory, use its parent as the package root
  if (path.basename(resolvedOutputLibPath) == 'lib') {
    return path.dirname(resolvedOutputLibPath);
  }

  // Fallback to the current working directory
  return Directory.current.path;
}

/// Reads the package name from pubspec.yaml in the detected package root directory.
String? _getPackageName(String packageRootPath) {
  final pubspecFile = File(path.join(packageRootPath, 'pubspec.yaml'));
  if (!pubspecFile.existsSync()) {
    return null;
  }

  try {
    final content = pubspecFile.readAsStringSync();
    final yaml = loadYaml(content) as YamlMap;
    return yaml['name'] as String?;
  } catch (_) {
    return null;
  }
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
