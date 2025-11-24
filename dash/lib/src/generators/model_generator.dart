import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import '../model/annotations.dart';

/// Generator for Dash model code.
///
/// This generator creates boilerplate code for models annotated with @DashModel,
/// including toMap(), fromMap(), getKey(), setKey(), and query() methods.
class ModelGenerator extends GeneratorForAnnotation<DashModel> {
  @override
  String generateForAnnotatedElement(Element element, ConstantReader annotation, BuildStep buildStep) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError('@DashModel can only be applied to classes.', element: element);
    }

    final className = element.name;
    final tableName = annotation.read('table').stringValue;
    final timestamps = annotation.read('timestamps').boolValue;
    final createdAtColumn = annotation.read('createdAtColumn').stringValue;
    final updatedAtColumn = annotation.read('updatedAtColumn').stringValue;

    // Analyze the class fields
    final fields = _analyzeFields(element);

    // Find primary key - defaults to 'id' if not explicitly annotated
    final primaryKeyField = fields.firstWhere(
      (f) => f.isPrimaryKey || f.fieldName == 'id',
      orElse: () => throw InvalidGenerationSourceError(
        'Model must have an id field or a field annotated with @PrimaryKey()',
        element: element,
      ),
    );

    final buffer = StringBuffer();

    // Add ignore directive
    buffer.writeln('// ignore_for_file: unnecessary_this');
    buffer.writeln();

    // Generate the mixin
    buffer.writeln('mixin _\$${className}ModelMixin on Model {');

    // Generate table getter
    buffer.writeln('  @override');
    buffer.writeln('  String get table => \'$tableName\';');
    buffer.writeln();

    // Generate timestamps getter
    buffer.writeln('  @override');
    buffer.writeln('  bool get timestamps => $timestamps;');
    buffer.writeln();

    if (timestamps) {
      buffer.writeln('  @override');
      buffer.writeln('  String get createdAtColumn => \'$createdAtColumn\';');
      buffer.writeln();
      buffer.writeln('  @override');
      buffer.writeln('  String get updatedAtColumn => \'$updatedAtColumn\';');
      buffer.writeln();
    }

    // Generate getKey
    buffer.writeln('  @override');
    buffer.writeln('  dynamic getKey() {');
    buffer.writeln('    final self = this as $className;');
    buffer.writeln('    return self.${primaryKeyField.fieldName};');
    buffer.writeln('  }');
    buffer.writeln();

    // Generate setKey
    buffer.writeln('  @override');
    buffer.writeln('  void setKey(dynamic value) {');
    buffer.writeln('    final self = this as $className;');
    buffer.writeln('    self.${primaryKeyField.fieldName} = value as ${primaryKeyField.dartType};');
    buffer.writeln('  }');
    buffer.writeln();

    // Generate toMap
    buffer.writeln('  @override');
    buffer.writeln('  Map<String, dynamic> toMap() {');
    buffer.writeln('    final self = this as $className;');
    buffer.writeln('    return {');
    for (final field in fields) {
      if (field.isRelationship) continue; // Skip relationships

      final fieldName = field.fieldName;
      final columnName = field.columnName;

      if (field.isNullable) {
        buffer.writeln(
          '      if (self.$fieldName != null) \'$columnName\': ${_serializeValue('self.$fieldName', field.dartType)},',
        );
      } else {
        buffer.writeln('      \'$columnName\': ${_serializeValue('self.$fieldName', field.dartType)},');
      }
    }
    buffer.writeln('    };');
    buffer.writeln('  }');
    buffer.writeln();

    // Generate fromMap
    buffer.writeln('  @override');
    buffer.writeln('  void fromMap(Map<String, dynamic> map) {');
    buffer.writeln('    final self = this as $className;');
    for (final field in fields) {
      if (field.isRelationship) continue; // Skip relationships

      final fieldName = field.fieldName;
      final columnName = field.columnName;
      final dartType = field.dartType;

      buffer.writeln('    self.$fieldName = ${_deserializeValue(columnName, dartType)};');
    }
    buffer.writeln('  }');
    buffer.writeln();

    // Generate toString
    buffer.writeln('  @override');
    buffer.writeln('  String toString() {');
    buffer.writeln('    final self = this as $className;');
    final nonRelationshipFields = fields.where((f) => !f.isRelationship).toList();
    final fieldStrings = nonRelationshipFields.map((f) => '${f.fieldName}: \${self.${f.fieldName}}').join(', ');
    buffer.writeln('    return \'$className($fieldStrings)\';');
    buffer.writeln('  }');
    buffer.writeln();

    // Generate getFields - returns all database column names
    buffer.writeln('  @override');
    buffer.writeln('  List<String> getFields() {');
    buffer.writeln('    return [');
    for (final field in fields) {
      if (field.isRelationship) continue; // Skip relationships
      buffer.writeln('      \'${field.columnName}\',');
    }
    buffer.writeln('    ];');
    buffer.writeln('  }');

    buffer.writeln('}');
    buffer.writeln();

    // Generate extension with static methods
    buffer.writeln('extension ${className}Model on $className {');
    buffer.writeln('  /// Creates a query builder for $className models.');
    buffer.writeln('  static ModelQueryBuilder<$className> query() {');
    buffer.writeln('    return ModelQueryBuilder<$className>(');
    buffer.writeln('      Model.connector,');
    buffer.writeln('      modelFactory: () => $className(),');
    buffer.writeln('    ).table(\'$tableName\');');
    buffer.writeln('  }');
    buffer.writeln();
    buffer.writeln('  /// Finds a $className by its primary key.');
    buffer.writeln('  static Future<$className?> find(dynamic id) async {');
    buffer.writeln('    return query().find(id);');
    buffer.writeln('  }');
    buffer.writeln();
    buffer.writeln('  /// Gets all $className records.');
    buffer.writeln('  static Future<List<$className>> all() async {');
    buffer.writeln('    return query().get();');
    buffer.writeln('  }');
    buffer.writeln('}');

    return buffer.toString();
  }

  /// Analyzes all fields in a class.
  List<_FieldInfo> _analyzeFields(ClassElement element) {
    final fields = <_FieldInfo>[];

    for (final field in element.fields) {
      if (field.isStatic || field.isSynthetic) continue;

      final annotations = _getFieldAnnotations(field);
      final rawName = field.name ?? field.displayName; // Analyzer 9 may expose nullable name
      if (rawName.isEmpty) {
        continue; // Skip unnamed synthetic fields just in case
      }
      final columnName = (annotations['columnName'] as String?) ?? _toSnakeCase(rawName);
      final isPrimaryKey = (annotations['isPrimaryKey'] as bool?) ?? rawName == 'id';

      fields.add(
        _FieldInfo(
          fieldName: rawName,
          columnName: columnName,
          dartType: field.type.getDisplayString(),
          isNullable: field.type.nullabilitySuffix == NullabilitySuffix.question,
          isPrimaryKey: isPrimaryKey,
          isRelationship: (annotations['isRelationship'] as bool?) ?? false,
        ),
      );
    }

    return fields;
  }

  /// Extracts annotation information from a field.
  Map<String, dynamic> _getFieldAnnotations(FieldElement field) {
    final result = <String, dynamic>{};

    // Analyzer API differences (v9): metadata may not be a plain List; attempt dynamic access.
    final metaSource = field.metadata; // Analyzer 9: Metadata object with 'annotations' collection.
    Iterable<dynamic> annotationElements;
    try {
      final dynAnnotations = (metaSource as dynamic).annotations;
      annotationElements = dynAnnotations is Iterable ? dynAnnotations : const <dynamic>[];
    } catch (_) {
      annotationElements = const <dynamic>[];
    }
    for (final annotationElement in annotationElements) {
      dynamic constantValue;
      try {
        constantValue = (annotationElement as dynamic).computeConstantValue();
      } catch (_) {
        continue;
      }
      if (constantValue == null) continue;
      final annotationType = constantValue.type;
      if (annotationType == null) continue;
      final typeName = annotationType.getDisplayString(withNullability: false);

      if (typeName == 'PrimaryKey') {
        result['isPrimaryKey'] = true;
        final nameValue = constantValue.getField('name');
        if (nameValue != null && !nameValue.isNull) {
          result['columnName'] = nameValue.toStringValue();
        }
      } else if (typeName == 'Column') {
        final nameValue = constantValue.getField('name');
        if (nameValue != null && !nameValue.isNull) {
          result['columnName'] = nameValue.toStringValue();
        }
      } else if (typeName == 'BelongsTo' || typeName == 'HasMany' || typeName == 'HasOne') {
        result['isRelationship'] = true;
      }
    }

    return result;
  }

  /// Converts camelCase to snake_case.
  String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(RegExp(r'[A-Z]'), (match) => '_${match.group(0)!.toLowerCase()}')
        .replaceFirst(RegExp(r'^_'), '');
  }

  /// Generates serialization code for a value.
  String _serializeValue(String fieldName, String dartType) {
    if (dartType == 'DateTime') {
      return '$fieldName!.toIso8601String()';
    }
    return fieldName;
  }

  /// Generates deserialization code for a value.
  String _deserializeValue(String columnName, String dartType) {
    dartType = dartType.replaceAll('?', ''); // Remove nullability for type checks
    if (dartType == 'DateTime') {
      return 'parseDateTime(map[\'$columnName\'])';
    } else if (dartType == 'int') {
      return 'getFromMap<int>(map, \'$columnName\')';
    } else if (dartType == 'String') {
      return 'getFromMap<String>(map, \'$columnName\')';
    } else if (dartType == 'double') {
      return 'getFromMap<double>(map, \'$columnName\')';
    } else if (dartType == 'bool') {
      return 'getFromMap<bool>(map, \'$columnName\')';
    }
    return 'map[\'$columnName\'] as $dartType';
  }
}

/// Information about a field in a model class.
class _FieldInfo {
  final String fieldName;
  final String columnName;
  final String dartType;
  final bool isNullable;
  final bool isPrimaryKey;
  final bool isRelationship;

  _FieldInfo({
    required this.fieldName,
    required this.columnName,
    required this.dartType,
    required this.isNullable,
    required this.isPrimaryKey,
    required this.isRelationship,
  });
}
