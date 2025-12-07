import 'dart:io';

import 'package:dash_panel_cli/src/commands/base_command.dart';
import 'package:dash_panel_cli/src/commands/completion_configuration.dart';
import 'package:dash_panel_cli/src/commands/dcli_argument.dart';
import 'package:dash_panel_cli/src/generators/models_barrel_generator.dart';
import 'package:dash_panel_cli/src/generators/resource_generator.dart';
import 'package:dash_panel_cli/src/generators/schema_model_generator.dart';
import 'package:dash_panel_cli/src/generators/schema_parser.dart';
import 'package:dash_panel_cli/src/utils/console_utils.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

/// Generate Dart model classes from schema YAML files.
///
/// Usage:
///   dcli generate:models [options]
///   dcli generate:models -s schemas/models -o lib
///
/// Options:
///   -s, --schemas    Path to schema YAML files (default: schemas/models)
///   -o, --output     Output directory for generated code (default: lib)
///   --force          Overwrite existing resource files
class GenerateModelsCommand extends BaseCommand {
  GenerateModelsCommand() {
    DcliArgument.addToParser(argParser, _arguments);
  }

  /// Unified argument definitions.
  static final _arguments = [
    DcliArgument.option(
      name: 'schemas',
      abbr: 's',
      help: 'Path to directory containing schema YAML files',
      defaultsTo: 'schemas/models',
      completionType: CompletionType.directory,
    ),
    DcliArgument.option(
      name: 'output',
      abbr: 'o',
      help: 'Output directory for generated code',
      defaultsTo: 'lib',
      completionType: CompletionType.directory,
    ),
    DcliArgument.flag(name: 'force', abbr: 'f', help: 'Overwrite existing resource files'),
    DcliArgument.flag(name: 'verbose', abbr: 'v', help: 'Show detailed output'),
  ];

  @override
  final String name = 'generate:models';

  @override
  final String description = 'Generate Dart model and resource classes from schema YAML files';

  @override
  final List<String> aliases = ['gen:models', 'g:m'];

  @override
  Future<int> run() async {
    final schemasDir = argResults!['schemas'] as String;
    final outputDir = argResults!['output'] as String;
    final force = argResults!['force'] as bool;
    final verbose = argResults!['verbose'] as bool;

    ConsoleUtils.header('🎯 Dash Model Generator');

    // Validate schemas directory
    if (!Directory(schemasDir).existsSync()) {
      ConsoleUtils.error('Schemas directory not found: $schemasDir');
      print('');
      print('Create a schemas directory with .yaml files defining your models.');
      print('See: https://github.com/yourusername/dash/blob/main/docs/model-schema-generator.md');
      return 1;
    }

    // Resolve output directory
    final resolvedOutputDir = path.normalize(path.absolute(outputDir));

    // Determine package root and name
    final packageRootPath = _determinePackageRoot(resolvedOutputDir);
    final packageName = _getPackageName(packageRootPath);

    if (packageName == null) {
      ConsoleUtils.error('Could not find pubspec.yaml in project');
      return 1;
    }

    ConsoleUtils.info('Package: $packageName');
    ConsoleUtils.info('Schemas: $schemasDir');
    ConsoleUtils.info('Output: $outputDir');
    print('');

    // Calculate import path prefix
    final importPathPrefix = _calculateImportPathPrefix(resolvedOutputDir, packageRootPath);

    final parser = SchemaParser();

    // Find all schema files
    final schemaFiles = Directory(
      schemasDir,
    ).listSync().whereType<File>().where((f) => f.path.endsWith('.yaml') || f.path.endsWith('.yml')).toList();

    if (schemaFiles.isEmpty) {
      ConsoleUtils.warning('No schema files found in $schemasDir');
      print('   Expected files with .yaml or .yml extension');
      return 0;
    }

    ConsoleUtils.info('Found ${schemaFiles.length} schema file(s)');
    print('');

    // Create output directories
    final modelsDir = Directory(path.join(resolvedOutputDir, 'models'));
    if (!modelsDir.existsSync()) {
      modelsDir.createSync(recursive: true);
    }

    final resourcesDir = Directory(path.join(resolvedOutputDir, 'resources'));
    if (!resourcesDir.existsSync()) {
      resourcesDir.createSync(recursive: true);
    }

    // Track parsed schemas
    final parsedSchemas = <ParsedSchema>[];
    var modelsGenerated = 0;
    var resourcesGenerated = 0;

    // Process each schema
    for (final schemaFile in schemaFiles) {
      final fileName = path.basename(schemaFile.path);

      try {
        final schema = parser.parseFile(schemaFile.path);
        parsedSchemas.add(schema);

        // Generate model
        final modelGenerator = SchemaModelGenerator(
          schema,
          packageName: packageName,
          importPathPrefix: importPathPrefix,
        );

        final modelContent = modelGenerator.generate();
        final modelFileName = _toSnakeCase(schema.modelName);
        final modelFile = File(path.join(modelsDir.path, '$modelFileName.dart'));
        modelFile.writeAsStringSync(modelContent);
        modelsGenerated++;

        if (verbose) {
          ConsoleUtils.success('Generated model: ${path.relative(modelFile.path)}');
        }

        // Generate resource (unless it exists and --force is not set)
        final resourceFileName = '${modelFileName}_resource.dart';
        final resourceFile = File(path.join(resourcesDir.path, resourceFileName));

        if (!resourceFile.existsSync() || force) {
          final resourceGenerator = ResourceGenerator(
            schema,
            packageName: packageName,
            importPathPrefix: importPathPrefix,
          );
          final resourceContent = resourceGenerator.generate();
          resourceFile.writeAsStringSync(resourceContent);
          resourcesGenerated++;

          if (verbose) {
            ConsoleUtils.success('Generated resource: ${path.relative(resourceFile.path)}');
          }
        } else {
          ConsoleUtils.info('Skipped resource: ${path.relative(resourceFile.path)} (exists)');
        }
      } catch (e, stack) {
        ConsoleUtils.error('Error processing $fileName: $e');
        if (verbose) {
          print('   Stack trace: $stack');
        }
      }
    }

    // Generate barrel file
    if (parsedSchemas.isNotEmpty) {
      final barrelGenerator = ModelsBarrelGenerator(
        parsedSchemas,
        packageName: packageName,
        importPathPrefix: importPathPrefix,
      );
      final barrelContent = barrelGenerator.generate();
      final barrelFile = File(path.join(modelsDir.path, 'models.dart'));
      barrelFile.writeAsStringSync(barrelContent);

      if (verbose) {
        ConsoleUtils.success('Generated barrel: ${path.relative(barrelFile.path)}');
      }
    }

    print('');
    ConsoleUtils.line();
    ConsoleUtils.success('Generated $modelsGenerated model(s) and $resourcesGenerated resource(s)');
    print('');
    print('Next steps:');
    print("  1. Import 'package:$packageName/models/models.dart'");
    print('  2. Call registerAllModels() in your main.dart');
    print('');

    return 0;
  }

  String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(RegExp(r'[A-Z]'), (match) => '_${match.group(0)!.toLowerCase()}')
        .replaceFirst(RegExp(r'^_'), '');
  }

  String _determinePackageRoot(String resolvedOutputLibPath) {
    if (path.basename(resolvedOutputLibPath) == 'lib') {
      return path.dirname(resolvedOutputLibPath);
    }
    return Directory.current.path;
  }

  String _calculateImportPathPrefix(String resolvedOutputDir, String packageRoot) {
    final libPath = path.join(packageRoot, 'lib');
    if (path.normalize(resolvedOutputDir) == path.normalize(libPath)) {
      return '';
    }
    final relativePath = path.relative(resolvedOutputDir, from: libPath);
    return relativePath.isEmpty ? '' : '$relativePath/';
  }

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

  @override
  CompletionConfiguration getCompletionConfig() {
    return DcliArgument.toCompletionConfig(
      name: name,
      description: description,
      arguments: _arguments,
      aliases: aliases,
    );
  }
}
