import 'package:dash/src/generators/schema_parser.dart';

/// Generates an empty Resource class for a model.
class ResourceGenerator {
  final ParsedSchema schema;
  final String packageName;
  final String importPathPrefix;

  ResourceGenerator(this.schema, {required this.packageName, this.importPathPrefix = ''});

  /// Generate the resource class code.
  String generate() {
    final buffer = StringBuffer();
    final modelName = schema.modelName;
    final modelFileName = _toSnakeCase(modelName);

    // Header
    buffer.writeln('// GENERATED CODE - Customize as needed');
    buffer.writeln('// Resource for $modelName');
    buffer.writeln();
    buffer.writeln("import 'package:dash/dash.dart';");
    buffer.writeln("import 'package:$packageName/${importPathPrefix}models/$modelFileName.dart';");
    buffer.writeln();

    // Class declaration
    buffer.writeln('/// Resource for managing ${modelName}s in the admin panel.');
    buffer.writeln('class ${modelName}Resource extends Resource<$modelName> {');

    // Icon - use a sensible default based on model name
    final icon = _guessIcon(modelName);
    buffer.writeln('  @override');
    buffer.writeln('  Heroicon get iconComponent => const Heroicon(HeroIcons.$icon);');
    buffer.writeln();

    // Table configuration
    buffer.writeln('  @override');
    buffer.writeln('  Table<$modelName> table(Table<$modelName> table) {');
    buffer.writeln('    return table.columns([');

    // Generate columns for each field
    for (final field in schema.fields) {
      if (field.isPrimaryKey) {
        buffer.writeln("      TextColumn.make('${field.columnName}')");
        buffer.writeln("          .label('ID')");
        buffer.writeln('          .sortable()');
        buffer.writeln("          .width('80px'),");
      } else if (field.dartType == 'bool') {
        buffer.writeln("      BooleanColumn.make('${field.columnName}')");
        buffer.writeln("          .label('${_toTitleCase(field.name)}')");
        buffer.writeln('          .sortable(),');
      } else if (field.dartType == 'String' && !_isPasswordField(field.name)) {
        buffer.writeln("      TextColumn.make('${field.columnName}')");
        buffer.writeln("          .label('${_toTitleCase(field.name)}')");
        buffer.writeln('          .searchable()');
        buffer.writeln('          .sortable(),');
      }
    }

    buffer.writeln('    ]);');
    buffer.writeln('  }');
    buffer.writeln();

    // Form configuration
    buffer.writeln('  @override');
    buffer.writeln('  FormSchema<$modelName> form(FormSchema<$modelName> form) {');
    buffer.writeln('    return form.fields([');

    // Generate form fields for each field
    for (final field in schema.fields) {
      if (field.isPrimaryKey) continue; // Skip primary key
      if (_isPasswordField(field.name)) {
        buffer.writeln("      TextInput.make('${field.columnName}')");
        buffer.writeln("          .label('${_toTitleCase(field.name)}')");
        buffer.writeln('          .password()');
        buffer.writeln('          .required(),');
      } else if (field.dartType == 'bool') {
        buffer.writeln("      Toggle.make('${field.columnName}')");
        buffer.writeln("          .label('${_toTitleCase(field.name)}'),");
      } else if (field.dartType == 'String') {
        if (field.name == 'email' || field.columnName == 'email') {
          buffer.writeln("      TextInput.make('${field.columnName}')");
          buffer.writeln("          .label('${_toTitleCase(field.name)}')");
          buffer.writeln('          .email()');
          buffer.writeln('          .required(),');
        } else {
          buffer.writeln("      TextInput.make('${field.columnName}')");
          buffer.writeln("          .label('${_toTitleCase(field.name)}')");
          if (field.isRequired) {
            buffer.writeln('          .required(),');
          } else {
            buffer.writeln(',');
          }
        }
      } else if (field.dartType == 'int' || field.dartType == 'double') {
        buffer.writeln("      TextInput.make('${field.columnName}')");
        buffer.writeln("          .label('${_toTitleCase(field.name)}')");
        buffer.writeln('          .numeric(),');
      } else if (field.dartType == 'DateTime') {
        buffer.writeln("      DatePicker.make('${field.columnName}')");
        buffer.writeln("          .label('${_toTitleCase(field.name)}'),");
      }
    }

    buffer.writeln('    ]);');
    buffer.writeln('  }');

    // Close class
    buffer.writeln('}');

    return buffer.toString();
  }

  String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(RegExp(r'[A-Z]'), (match) => '_${match.group(0)!.toLowerCase()}')
        .replaceFirst(RegExp(r'^_'), '');
  }

  String _toTitleCase(String input) {
    // Convert camelCase or snake_case to Title Case
    final words = input
        .replaceAllMapped(RegExp(r'[A-Z]'), (match) => ' ${match.group(0)}')
        .replaceAll('_', ' ')
        .trim()
        .split(' ');
    return words.map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}').join(' ');
  }

  bool _isPasswordField(String name) {
    final lower = name.toLowerCase();
    return lower.contains('password') || lower.contains('secret') || lower.contains('token');
  }

  String _guessIcon(String modelName) {
    final lower = modelName.toLowerCase();
    if (lower.contains('user') || lower.contains('account') || lower.contains('member')) {
      return 'userGroup';
    }
    if (lower.contains('post') || lower.contains('article') || lower.contains('blog')) {
      return 'documentText';
    }
    if (lower.contains('product') || lower.contains('item')) {
      return 'shoppingBag';
    }
    if (lower.contains('order') || lower.contains('purchase')) {
      return 'shoppingCart';
    }
    if (lower.contains('category') || lower.contains('tag')) {
      return 'tag';
    }
    if (lower.contains('comment') || lower.contains('review')) {
      return 'chatBubbleLeftRight';
    }
    if (lower.contains('image') || lower.contains('photo') || lower.contains('media')) {
      return 'photo';
    }
    if (lower.contains('file') || lower.contains('document')) {
      return 'document';
    }
    if (lower.contains('setting') || lower.contains('config')) {
      return 'cog6Tooth';
    }
    if (lower.contains('metric') || lower.contains('stat') || lower.contains('analytic')) {
      return 'chartBar';
    }
    return 'rectangleStack';
  }
}
