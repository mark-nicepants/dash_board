// GENERATED CODE - DO NOT MODIFY BY HAND
// Generated from schema: permission

import 'package:dash/dash.dart';

class Permission extends Model {
  @override
  String get table => 'permissions';

  @override
  String get primaryKey => 'id';

  @override
  bool get timestamps => true;

  @override
  PermissionResource get resource => PermissionResource();

  int? id;
  String name;
  String slug;
  String? description;

  Permission({this.id, required this.name, required this.slug, this.description});

  @override
  dynamic getKey() => id;

  @override
  void setKey(dynamic value) {
    id = value as int?;
  }

  @override
  List<String> getFields() {
    return ['id', 'name', 'slug', 'description', 'created_at', 'updated_at'];
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  void fromMap(Map<String, dynamic> map) {
    id = getFromMap<int>(map, 'id');
    name = getFromMap<String>(map, 'name') ?? '';
    slug = getFromMap<String>(map, 'slug') ?? '';
    description = getFromMap<String>(map, 'description');
    createdAt = parseDateTime(map['created_at']);
    updatedAt = parseDateTime(map['updated_at']);
  }

  Permission copyWith({
    int? id,
    String? name,
    String? slug,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Permission(
        id: id ?? this.id,
        name: name ?? this.name,
        slug: slug ?? this.slug,
        description: description ?? this.description,
      )
      ..createdAt = createdAt ?? this.createdAt
      ..updatedAt = updatedAt ?? this.updatedAt;
  }

  /// Factory constructor for creating empty instances.
  /// Used internally by query builder and model registration.
  factory Permission.empty() => Permission._empty();

  /// Creates a query builder for Permissions.
  static ModelQueryBuilder<Permission> query() {
    return ModelQueryBuilder<Permission>(
      Model.connector,
      modelFactory: Permission.empty,
      modelTable: 'permissions',
      modelPrimaryKey: 'id',
    );
  }

  /// Finds a Permission by its primary key.
  static Future<Permission?> find(dynamic id) => query().find(id);

  /// Gets all Permissions.
  static Future<List<Permission>> all() => query().get();

  static void register() {
    inject.registerFactory<Model>(Permission.empty, instanceName: 'model:permission');
    inject.registerSingleton<Resource>(Permission.empty().resource, instanceName: 'resource:permission');
    trackModelSlug('permission');
  }

  /// Internal empty constructor.
  Permission._empty() : name = '', slug = '';

  /// Gets the table schema for automatic migrations.
  @override
  TableSchema get schema {
    return const TableSchema(
      name: 'permissions',
      columns: [
        ColumnDefinition(name: 'id', type: ColumnType.integer, isPrimaryKey: true, autoIncrement: true, nullable: true),
        ColumnDefinition(name: 'name', type: ColumnType.text, unique: true, nullable: false),
        ColumnDefinition(name: 'slug', type: ColumnType.text, unique: true, nullable: false),
        ColumnDefinition(name: 'description', type: ColumnType.text, nullable: true),
        ColumnDefinition(name: 'created_at', type: ColumnType.text, nullable: true),
        ColumnDefinition(name: 'updated_at', type: ColumnType.text, nullable: true),
      ],
    );
  }

  @override
  List<RelationshipMeta> getRelationships() => [];

  /// Prevents deletion if this permission is assigned to any roles.
  @override
  Future<void> onDeleting() async {
    final roleCount = await Model.connector.query(
      'SELECT COUNT(*) as count FROM permission_role WHERE permission_id = ?',
      [getKey()],
    );
    final count = roleCount.first['count'] as int? ?? 0;
    if (count > 0) {
      throw StateError('Cannot delete permission "$name" because it is assigned to $count role(s)');
    }

    // Also check direct user assignments
    final userCount = await Model.connector.query(
      'SELECT COUNT(*) as count FROM user_permission WHERE permission_id = ?',
      [getKey()],
    );
    final userAssignments = userCount.first['count'] as int? ?? 0;
    if (userAssignments > 0) {
      throw StateError('Cannot delete permission "$name" because it is directly assigned to $userAssignments user(s)');
    }
  }

  /// Finds a permission by its slug.
  static Future<Permission?> findBySlug(String slug) {
    return query().where('slug', '=', slug).first();
  }
}
