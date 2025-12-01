import 'package:dash/src/generators/schema_parser.dart';

/// Generates Dart model code from a parsed schema.
class SchemaModelGenerator {
  final ParsedSchema schema;
  final String packageName;
  final String importPathPrefix;

  SchemaModelGenerator(this.schema, {required this.packageName, this.importPathPrefix = ''});

  /// Generate the complete model code.
  String generate() {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln('// Generated from schema: ${schema.modelName.toLowerCase()}');
    buffer.writeln();
    buffer.writeln("import 'package:dash/dash.dart';");
    final modelFileName = _toSnakeCase(schema.modelName);
    buffer.writeln("import 'package:$packageName/${importPathPrefix}resources/${modelFileName}_resource.dart';");
    buffer.writeln();

    // Class declaration - with Authenticatable mixin if configured
    final mixins = schema.authenticatable != null ? ' with Authenticatable' : '';
    buffer.writeln('class ${schema.modelName} extends Model$mixins {');

    // Table name
    buffer.writeln('  @override');
    buffer.writeln("  String get table => '${schema.config.table}';");
    buffer.writeln();

    // Primary key getter
    final pk = schema.primaryKey;
    if (pk != null) {
      buffer.writeln('  @override');
      buffer.writeln("  String get primaryKey => '${pk.columnName}';");
      buffer.writeln();
    }

    // Timestamps
    buffer.writeln('  @override');
    buffer.writeln('  bool get timestamps => ${schema.config.timestamps};');
    buffer.writeln();

    // Resource getter for DI lookups
    final resourceClass = '${schema.modelName}Resource';
    buffer.writeln('  @override');
    buffer.writeln('  $resourceClass get resource => $resourceClass();');
    buffer.writeln();

    // Fields
    _generateFields(buffer);

    // Constructor
    _generateConstructor(buffer);

    // getKey method
    _generateGetKey(buffer);

    // setKey method
    _generateSetKey(buffer);

    // getFields method
    _generateGetFields(buffer);

    // toMap method
    _generateToMap(buffer);

    // fromMap method
    _generateFromMap(buffer);

    // copyWith method
    _generateCopyWith(buffer);

    // Static query methods
    _generateQueryMethods(buffer);

    // Schema for migrations
    _generateSchema(buffer);

    // getRelationships override
    _generateGetRelationships(buffer);

    // Relationship getters (comments for now)
    _generateRelationshipGetters(buffer);

    // Authenticatable mixin methods if configured
    if (schema.authenticatable != null) {
      _generateAuthenticatableMethods(buffer);
    }

    // Close class
    buffer.writeln('}');

    return buffer.toString();
  }

  void _generateFields(StringBuffer buffer) {
    for (final field in schema.fields) {
      final nullableSuffix = field.isNullable ? '?' : '';
      buffer.writeln('  ${field.dartType}$nullableSuffix ${field.name};');
    }

    // Add loaded relations map if there are any relationships
    final hasRelations = schema.fields.any((f) => f.relation != null);
    if (hasRelations) {
      buffer.writeln();
      buffer.writeln('  /// Stores loaded relationship models.');
      buffer.writeln('  final Map<String, Model> _loadedRelations = {};');
    }

    buffer.writeln();
  }

  void _generateConstructor(StringBuffer buffer) {
    buffer.writeln('  ${schema.modelName}({');

    for (final field in schema.fields) {
      final requiredKeyword = field.isRequired ? 'required ' : '';
      buffer.writeln('    ${requiredKeyword}this.${field.name},');
    }

    buffer.writeln('  });');
    buffer.writeln();
  }

  void _generateGetKey(StringBuffer buffer) {
    final pk = schema.primaryKey;
    buffer.writeln('  @override');
    if (pk != null) {
      buffer.writeln('  dynamic getKey() => ${pk.name};');
    } else {
      buffer.writeln('  dynamic getKey() => null;');
    }
    buffer.writeln();
  }

  void _generateSetKey(StringBuffer buffer) {
    final pk = schema.primaryKey;
    buffer.writeln('  @override');
    buffer.writeln('  void setKey(dynamic value) {');
    if (pk != null) {
      buffer.writeln('    ${pk.name} = value as ${pk.dartType}?;');
    }
    buffer.writeln('  }');
    buffer.writeln();
  }

  void _generateGetFields(StringBuffer buffer) {
    buffer.writeln('  @override');
    buffer.writeln('  List<String> getFields() {');
    buffer.write('    return [');
    final fieldNames = schema.fields.map((f) => "'${f.columnName}'").join(', ');
    buffer.write(fieldNames);
    if (schema.config.timestamps) {
      buffer.write(", 'created_at', 'updated_at'");
    }
    buffer.writeln('];');
    buffer.writeln('  }');
    buffer.writeln();
  }

  void _generateToMap(StringBuffer buffer) {
    buffer.writeln('  @override');
    buffer.writeln('  Map<String, dynamic> toMap() {');
    buffer.writeln('    return {');

    for (final field in schema.fields) {
      final conversion = _getToMapConversion(field);
      buffer.writeln("      '${field.columnName}': $conversion,");
    }

    if (schema.config.timestamps) {
      buffer.writeln("      'created_at': createdAt?.toIso8601String(),");
      buffer.writeln("      'updated_at': updatedAt?.toIso8601String(),");
    }

    buffer.writeln('    };');
    buffer.writeln('  }');
    buffer.writeln();
  }

  void _generateFromMap(StringBuffer buffer) {
    buffer.writeln('  @override');
    buffer.writeln('  void fromMap(Map<String, dynamic> map) {');

    for (final field in schema.fields) {
      final conversion = _getFromMapConversion(field);
      buffer.writeln('    ${field.name} = $conversion;');
    }

    if (schema.config.timestamps) {
      buffer.writeln("    createdAt = parseDateTime(map['created_at']);");
      buffer.writeln("    updatedAt = parseDateTime(map['updated_at']);");
    }

    buffer.writeln('  }');
    buffer.writeln();
  }

  void _generateCopyWith(StringBuffer buffer) {
    buffer.writeln('  ${schema.modelName} copyWith({');

    for (final field in schema.fields) {
      buffer.writeln('    ${field.dartType}? ${field.name},');
    }

    if (schema.config.timestamps) {
      buffer.writeln('    DateTime? createdAt,');
      buffer.writeln('    DateTime? updatedAt,');
    }

    buffer.writeln('  }) {');
    buffer.writeln('    return ${schema.modelName}(');

    for (final field in schema.fields) {
      buffer.writeln('      ${field.name}: ${field.name} ?? this.${field.name},');
    }

    buffer.writeln('    )');

    if (schema.config.timestamps) {
      buffer.writeln('      ..createdAt = createdAt ?? this.createdAt');
      buffer.writeln('      ..updatedAt = updatedAt ?? this.updatedAt;');
    } else {
      buffer.writeln('    ;');
    }

    buffer.writeln('  }');
    buffer.writeln();
  }

  void _generateRelationshipGetters(StringBuffer buffer) {
    for (final field in schema.fields) {
      if (field.relation != null) {
        _generateRelationshipGetter(buffer, field);
      }
    }
  }

  void _generateRelationshipGetter(StringBuffer buffer, SchemaField field) {
    final rel = field.relation!;
    final relatedModel = rel.model;

    // Determine relation getter name, avoiding collision with field name
    final relationName = rel.name != null && rel.name != field.name
        ? rel.name!
        : '${_toCamelCase(relatedModel)}Relation';

    switch (rel.type) {
      case 'belongsTo':
        buffer.writeln('  /// Get the related $relatedModel via [$relationName].');
        buffer.writeln("  // Foreign key: '${rel.foreignKey}'");
        buffer.writeln();

      case 'hasOne':
        buffer.writeln('  /// Get the related $relatedModel via [$relationName].');
        buffer.writeln("  // Foreign key: '${rel.foreignKey}'");
        buffer.writeln();

      case 'hasMany':
        buffer.writeln('  /// Get the related ${relatedModel}s via [$relationName].');
        buffer.writeln("  // Foreign key: '${rel.foreignKey}'");
        buffer.writeln();
    }
  }

  void _generateGetRelationships(StringBuffer buffer) {
    final relationships = schema.fields.where((f) => f.relation != null).toList();

    buffer.writeln('  @override');
    buffer.writeln('  List<RelationshipMeta> getRelationships() => [');

    for (final field in relationships) {
      final rel = field.relation!;
      final relationName = rel.name ?? field.name;
      final relType = _mapRelationType(rel.type);

      buffer.writeln('    const RelationshipMeta(');
      buffer.writeln("      name: '$relationName',");
      buffer.writeln('      type: RelationshipType.$relType,');
      buffer.writeln("      foreignKey: '${rel.foreignKey}',");
      buffer.writeln("      relatedKey: 'id',");
      buffer.writeln("      relatedModelType: '${rel.model}',");
      buffer.writeln('    ),');
    }

    buffer.writeln('  ];');
    buffer.writeln();

    // Generate getRelation and setRelation methods if there are relationships
    if (relationships.isNotEmpty) {
      buffer.writeln('  @override');
      buffer.writeln('  Model? getRelation(String name) => _loadedRelations[name];');
      buffer.writeln();
      buffer.writeln('  /// Sets a loaded relationship by name.');
      buffer.writeln('  void setRelation(String name, Model value) {');
      buffer.writeln('    _loadedRelations[name] = value;');
      buffer.writeln('  }');
    }
    buffer.writeln();
  }

  String _mapRelationType(String yamlType) {
    return switch (yamlType) {
      'belongsTo' => 'belongsTo',
      'hasOne' => 'hasOne',
      'hasMany' => 'hasMany',
      _ => 'belongsTo',
    };
  }

  /// Generates the Authenticatable mixin method implementations.
  void _generateAuthenticatableMethods(StringBuffer buffer) {
    final auth = schema.authenticatable!;
    final identifierField = auth.identifierField;
    final passwordField = auth.passwordField;
    final displayNameField = auth.displayNameField;

    // Find the column name for the identifier field (for database queries)
    final identifierSchemaField = schema.fields.where((f) => f.name == identifierField).firstOrNull;
    final identifierColumnName = identifierSchemaField?.columnName ?? _toSnakeCase(identifierField);

    buffer.writeln('  // ═══════════════════════════════════════════════════════════════════════════');
    buffer.writeln('  // Authenticatable mixin implementation');
    buffer.writeln('  // ═══════════════════════════════════════════════════════════════════════════');
    buffer.writeln();

    // getAuthIdentifier
    buffer.writeln('  @override');
    buffer.writeln('  String getAuthIdentifier() => $identifierField;');
    buffer.writeln();

    // getAuthIdentifierName
    buffer.writeln('  @override');
    buffer.writeln("  String getAuthIdentifierName() => '$identifierColumnName';");
    buffer.writeln();

    // getAuthPassword
    buffer.writeln('  @override');
    buffer.writeln('  String getAuthPassword() => $passwordField;');
    buffer.writeln();

    // setAuthPassword
    buffer.writeln('  @override');
    buffer.writeln('  void setAuthPassword(String hash) {');
    buffer.writeln('    $passwordField = hash;');
    buffer.writeln('  }');
    buffer.writeln();

    // getDisplayName
    buffer.writeln('  @override');
    buffer.writeln('  String getDisplayName() => $displayNameField;');
    buffer.writeln();

    // canAccessPanel - default implementation, users can override in partial class
    buffer.writeln('  // Override canAccessPanel(String panelId) to customize access control');
  }

  String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(RegExp(r'[A-Z]'), (match) => '_${match.group(0)!.toLowerCase()}')
        .replaceFirst(RegExp(r'^_'), '');
  }

  String _getFromMapConversion(SchemaField field) {
    final columnName = field.columnName;
    final isRequired = field.isRequired;

    switch (field.dartType) {
      case 'int':
        if (isRequired) {
          return "getFromMap<int>(map, '$columnName') ?? 0";
        }
        return "getFromMap<int>(map, '$columnName')";

      case 'double':
        if (isRequired) {
          return "getFromMap<num>(map, '$columnName')?.toDouble() ?? 0.0";
        }
        return "getFromMap<num>(map, '$columnName')?.toDouble()";

      case 'bool':
        return "map['$columnName'] == 1 || map['$columnName'] == true";

      case 'DateTime':
        return "parseDateTime(map['$columnName'])";

      case 'String':
      default:
        if (isRequired) {
          return "getFromMap<String>(map, '$columnName') ?? ''";
        }
        return "getFromMap<String>(map, '$columnName')";
    }
  }

  String _getToMapConversion(SchemaField field) {
    switch (field.dartType) {
      case 'DateTime':
        return '${field.name}?.toIso8601String()';
      case 'bool':
        return '${field.name} == true ? 1 : 0';
      default:
        return field.name;
    }
  }

  void _generateQueryMethods(StringBuffer buffer) {
    final className = schema.modelName;
    final tableName = schema.config.table;
    final pk = schema.primaryKey;
    final modelSlug = _toSnakeCase(schema.modelName);

    // Factory for creating empty instances (used by query builder and registration)
    buffer.writeln('  /// Factory constructor for creating empty instances.');
    buffer.writeln('  /// Used internally by query builder and model registration.');
    buffer.writeln('  factory $className.empty() => $className._empty();');
    buffer.writeln();

    // Static query() method
    buffer.writeln('  /// Creates a query builder for ${className}s.');
    buffer.writeln('  static ModelQueryBuilder<$className> query() {');
    buffer.writeln('    return ModelQueryBuilder<$className>(');
    buffer.writeln('      Model.connector,');
    buffer.writeln('      modelFactory: $className.empty,');
    buffer.writeln("      modelTable: '$tableName',");
    if (pk != null) {
      buffer.writeln("      modelPrimaryKey: '${pk.columnName}',");
    }
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln();

    // Static find() method
    buffer.writeln('  /// Finds a $className by its primary key.');
    buffer.writeln('  static Future<$className?> find(dynamic id) => query().find(id);');
    buffer.writeln();

    // Static all() method
    buffer.writeln('  /// Gets all ${className}s.');
    buffer.writeln('  static Future<List<$className>> all() => query().get();');
    buffer.writeln();

    // Static register() method
    buffer.writeln('  static void register() {');
    buffer.writeln("    inject.registerFactory<Model>($className.empty, instanceName: 'model:$modelSlug');");
    buffer.writeln(
      "    inject.registerSingleton<Resource>($className.empty().resource, instanceName: 'resource:$modelSlug');",
    );
    buffer.writeln("    trackModelSlug('$modelSlug');");
    buffer.writeln('  }');
    buffer.writeln();

    // Empty constructor for factory (private)
    buffer.writeln('  /// Internal empty constructor.');
    buffer.writeln('  $className._empty()');
    final nonPkFields = schema.fields.where((f) => !f.isPrimaryKey).toList();
    if (nonPkFields.isEmpty) {
      buffer.writeln('      : super();');
    } else {
      buffer.write('      : ');
      final initializers = <String>[];
      for (final field in schema.fields) {
        if (field.isPrimaryKey) continue;
        if (field.isRequired && !field.isNullable) {
          initializers.add('${field.name} = ${_getDefaultValue(field)}');
        }
      }
      if (initializers.isEmpty) {
        buffer.writeln('super();');
      } else {
        buffer.writeln('${initializers.join(',\n        ')};');
      }
    }
    buffer.writeln();
  }

  String _getDefaultValue(SchemaField field) {
    switch (field.dartType) {
      case 'int':
        return '0';
      case 'double':
        return '0.0';
      case 'bool':
        return 'false';
      case 'String':
        return "''";
      case 'DateTime':
        return 'DateTime.now()';
      default:
        return "''";
    }
  }

  void _generateSchema(StringBuffer buffer) {
    final tableName = schema.config.table;

    buffer.writeln('  /// Gets the table schema for automatic migrations.');
    buffer.writeln('  @override');
    buffer.writeln('  TableSchema get schema {');
    buffer.writeln('    return const TableSchema(');
    buffer.writeln("      name: '$tableName',");
    buffer.writeln('      columns: [');

    for (final field in schema.fields) {
      final columnType = _mapDartTypeToColumnType(field.dartType);
      final isNullable = field.isNullable;
      final isPrimary = field.isPrimaryKey;
      final autoIncrement = field.autoIncrement;
      final isUnique = field.isUnique;

      buffer.writeln('        ColumnDefinition(');
      buffer.writeln("          name: '${field.columnName}',");
      buffer.writeln('          type: ColumnType.$columnType,');
      if (isPrimary) {
        buffer.writeln('          isPrimaryKey: true,');
      }
      if (autoIncrement) {
        buffer.writeln('          autoIncrement: true,');
      }
      if (isUnique) {
        buffer.writeln('          unique: true,');
      }
      buffer.writeln('          nullable: $isNullable,');
      buffer.writeln('        ),');
    }

    // Timestamp columns
    if (schema.config.timestamps) {
      buffer.writeln('        ColumnDefinition(');
      buffer.writeln("          name: 'created_at',");
      buffer.writeln('          type: ColumnType.text,');
      buffer.writeln('          nullable: true,');
      buffer.writeln('        ),');
      buffer.writeln('        ColumnDefinition(');
      buffer.writeln("          name: 'updated_at',");
      buffer.writeln('          type: ColumnType.text,');
      buffer.writeln('          nullable: true,');
      buffer.writeln('        ),');
    }

    buffer.writeln('      ],');
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln();
  }

  String _mapDartTypeToColumnType(String dartType) {
    switch (dartType) {
      case 'int':
        return 'integer';
      case 'double':
        return 'real';
      case 'bool':
        return 'boolean';
      case 'DateTime':
        return 'datetime';
      case 'String':
      default:
        return 'text';
    }
  }

  String _toCamelCase(String input) {
    if (input.isEmpty) return input;
    return input[0].toLowerCase() + input.substring(1);
  }
}
