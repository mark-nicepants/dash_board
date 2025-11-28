import 'dart:io';

import 'package:yaml/yaml.dart';

/// Parsed field information from Dash schema.
class SchemaField {
  final String name;
  final String dartType;
  final String columnName;
  final bool isRequired;
  final bool isNullable;
  final bool isPrimaryKey;
  final bool autoIncrement;

  // Validation
  final num? min;
  final num? max;
  final String? pattern;
  final String? format;
  final List<String>? enumValues;
  final dynamic defaultValue;

  // Relationship configuration
  final RelationConfig? relation;

  // Database
  final bool isUnique;

  const SchemaField({
    required this.name,
    required this.dartType,
    required this.columnName,
    required this.isRequired,
    required this.isNullable,
    this.isPrimaryKey = false,
    this.autoIncrement = false,
    this.min,
    this.max,
    this.pattern,
    this.format,
    this.enumValues,
    this.defaultValue,
    this.relation,
    this.isUnique = false,
  });
}

/// Relationship configuration.
class RelationConfig {
  final String type; // belongsTo, hasOne, hasMany
  final String model;
  final String foreignKey;
  final String? name; // Custom field name for the relation (via 'as')

  const RelationConfig({required this.type, required this.model, required this.foreignKey, this.name});
}

/// Dash model configuration from schema.
class ModelConfig {
  final String table;
  final bool timestamps;
  final bool softDeletes;

  const ModelConfig({required this.table, this.timestamps = true, this.softDeletes = false});
}

/// Complete parsed schema.
class ParsedSchema {
  final String modelName;
  final ModelConfig config;
  final List<SchemaField> fields;

  const ParsedSchema({required this.modelName, required this.config, required this.fields});

  /// Gets the model class name (e.g., "User", "Post").
  String get className => modelName;

  /// Gets the primary key field.
  SchemaField? get primaryKey => fields.where((f) => f.isPrimaryKey).firstOrNull;

  /// Gets fields that have relationships.
  List<SchemaField> get relationFields => fields.where((f) => f.relation != null).toList();

  /// Gets non-primary-key fields for editing.
  List<SchemaField> get editableFields => fields.where((f) => !f.isPrimaryKey).toList();

  /// Gets required field names.
  List<String> get requiredFieldNames => fields.where((f) => f.isRequired).map((f) => f.name).toList();
}

/// Parses Dash model schema YAML files.
class SchemaParser {
  /// Parses a schema from a YAML file.
  ParsedSchema parseFile(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      throw ArgumentError('Schema file not found: $path');
    }
    final content = file.readAsStringSync();
    return parse(content);
  }

  /// Parses a schema from YAML content.
  ParsedSchema parse(String yamlContent) {
    final doc = loadYaml(yamlContent) as YamlMap;
    return _parseDocument(doc);
  }

  ParsedSchema _parseDocument(YamlMap doc) {
    final modelName = doc['model'] as String? ?? 'Model';
    final table = doc['table'] as String? ?? _toSnakeCase(modelName);
    final timestamps = doc['timestamps'] as bool? ?? true;
    final softDeletes = doc['softDeletes'] as bool? ?? false;

    final config = ModelConfig(table: table, timestamps: timestamps, softDeletes: softDeletes);

    // Parse fields
    final fieldsMap = doc['fields'] as YamlMap? ?? YamlMap();
    final fields = <SchemaField>[];

    for (final entry in fieldsMap.entries) {
      final name = entry.key as String;
      final fieldDef = entry.value as YamlMap;
      fields.add(_parseField(name, fieldDef));
    }

    return ParsedSchema(modelName: modelName, config: config, fields: fields);
  }

  SchemaField _parseField(String name, YamlMap field) {
    final type = field['type'] as String? ?? 'string';
    final isRequired = field['required'] as bool? ?? false;
    final isNullable = field['nullable'] as bool? ?? !isRequired;
    final isPrimaryKey = field['primaryKey'] as bool? ?? false;
    final autoIncrement = field['autoIncrement'] as bool? ?? false;
    final isUnique = field['unique'] as bool? ?? false;

    // Determine Dart type
    final dartType = _mapTypeToDart(type);

    // Parse relationship
    RelationConfig? relation;
    if (field['belongsTo'] != null) {
      relation = RelationConfig(
        type: 'belongsTo',
        model: field['belongsTo'] as String,
        foreignKey: field['foreignKey'] as String? ?? '${_toSnakeCase(name)}_id',
        name: field['as'] as String?,
      );
    } else if (field['hasMany'] != null) {
      relation = RelationConfig(
        type: 'hasMany',
        model: field['hasMany'] as String,
        foreignKey: field['foreignKey'] as String? ?? '${_toSnakeCase(name)}_id',
        name: field['as'] as String?,
      );
    } else if (field['hasOne'] != null) {
      relation = RelationConfig(
        type: 'hasOne',
        model: field['hasOne'] as String,
        foreignKey: field['foreignKey'] as String? ?? '${_toSnakeCase(name)}_id',
        name: field['as'] as String?,
      );
    }

    // Parse enum values
    List<String>? enumValues;
    if (field['enum'] != null) {
      enumValues = _toStringList(field['enum']);
    }

    // For belongsTo relations, the column name is the foreign key
    final columnName = relation?.type == 'belongsTo' ? relation!.foreignKey : _toSnakeCase(name);

    return SchemaField(
      name: name,
      dartType: dartType,
      columnName: columnName,
      isRequired: isRequired,
      isNullable: isNullable,
      isPrimaryKey: isPrimaryKey,
      autoIncrement: autoIncrement,
      min: field['min'] as num?,
      max: field['max'] as num?,
      pattern: field['pattern'] as String?,
      format: field['format'] as String?,
      enumValues: enumValues,
      defaultValue: field['default'],
      relation: relation,
      isUnique: isUnique,
    );
  }

  String _mapTypeToDart(String type) {
    switch (type) {
      case 'int':
        return 'int';
      case 'double':
        return 'double';
      case 'bool':
        return 'bool';
      case 'string':
        return 'String';
      case 'datetime':
        return 'DateTime';
      case 'json':
        return 'Map<String, dynamic>';
      case 'list':
        return 'List<dynamic>';
      default:
        return 'dynamic';
    }
  }

  List<String> _toStringList(dynamic value) {
    if (value == null) return [];
    if (value is YamlList) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(RegExp(r'[A-Z]'), (match) => '_${match.group(0)!.toLowerCase()}')
        .replaceFirst(RegExp(r'^_'), '');
  }
}
