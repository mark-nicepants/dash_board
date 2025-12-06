// GENERATED CODE - DO NOT MODIFY BY HAND
// Generated from schema: role

import 'package:dash/dash.dart';

class Role extends Model {
  @override
  String get table => 'roles';

  @override
  String get primaryKey => 'id';

  @override
  bool get timestamps => true;

  @override
  RoleResource get resource => RoleResource();

  int? id;
  String name;
  String slug;
  String? description;
  bool? isDefault;

  Role({this.id, required this.name, required this.slug, this.description, this.isDefault});

  @override
  dynamic getKey() => id;

  @override
  void setKey(dynamic value) {
    id = value as int?;
  }

  @override
  List<String> getFields() {
    return ['id', 'name', 'slug', 'description', 'is_default', 'created_at', 'updated_at'];
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'is_default': isDefault == true ? 1 : 0,
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
    isDefault = map['is_default'] == 1 || map['is_default'] == true;
    createdAt = parseDateTime(map['created_at']);
    updatedAt = parseDateTime(map['updated_at']);
  }

  Role copyWith({
    int? id,
    String? name,
    String? slug,
    String? description,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Role(
        id: id ?? this.id,
        name: name ?? this.name,
        slug: slug ?? this.slug,
        description: description ?? this.description,
        isDefault: isDefault ?? this.isDefault,
      )
      ..createdAt = createdAt ?? this.createdAt
      ..updatedAt = updatedAt ?? this.updatedAt;
  }

  /// Factory constructor for creating empty instances.
  /// Used internally by query builder and model registration.
  factory Role.empty() => Role._empty();

  /// Creates a query builder for Roles.
  static ModelQueryBuilder<Role> query() {
    return ModelQueryBuilder<Role>(
      Model.connector,
      modelFactory: Role.empty,
      modelTable: 'roles',
      modelPrimaryKey: 'id',
    );
  }

  /// Finds a Role by its primary key.
  static Future<Role?> find(dynamic id) => query().find(id);

  /// Gets all Roles.
  static Future<List<Role>> all() => query().get();

  static void register() {
    inject.registerFactory<Model>(Role.empty, instanceName: 'model:role');
    inject.registerSingleton<Resource>(Role.empty().resource, instanceName: 'resource:role');
    trackModelSlug('role');
  }

  /// Internal empty constructor.
  Role._empty() : name = '', slug = '';

  /// Gets the table schema for automatic migrations.
  @override
  TableSchema get schema {
    return const TableSchema(
      name: 'roles',
      columns: [
        ColumnDefinition(name: 'id', type: ColumnType.integer, isPrimaryKey: true, autoIncrement: true, nullable: true),
        ColumnDefinition(name: 'name', type: ColumnType.text, unique: true, nullable: false),
        ColumnDefinition(name: 'slug', type: ColumnType.text, unique: true, nullable: false),
        ColumnDefinition(name: 'description', type: ColumnType.text, nullable: true),
        ColumnDefinition(name: 'is_default', type: ColumnType.boolean, nullable: true),
        ColumnDefinition(name: 'created_at', type: ColumnType.text, nullable: true),
        ColumnDefinition(name: 'updated_at', type: ColumnType.text, nullable: true),
      ],
      pivotTables: [
        PivotTableSchema(
          name: 'permission_role',
          localTable: 'roles',
          relatedTable: 'permissions',
          localKeyColumn: 'role_id',
          relatedKeyColumn: 'permission_id',
        ),
      ],
    );
  }

  @override
  List<RelationshipMeta> getRelationships() => [
    const RelationshipMeta(
      name: 'permissions',
      type: RelationshipType.hasMany,
      foreignKey: 'permissions_id',
      relatedKey: 'id',
      relatedModelType: 'Permission',
      pivotTable: 'permission_role',
      pivotLocalKey: 'role_id',
      pivotRelatedKey: 'permission_id',
    ),
  ];

  /// Get the related Permissions via [permissionRelation].
  // Foreign key: 'permissions_id'

  /// Prevents deletion if users are still assigned to this role.
  @override
  Future<void> onDeleting() async {
    final userCount = await Model.connector.query('SELECT COUNT(*) as count FROM user_role WHERE role_id = ?', [
      getKey(),
    ]);
    final count = userCount.first['count'] as int? ?? 0;
    if (count > 0) {
      throw StateError('Cannot delete role "$name" because it is assigned to $count user(s)');
    }
  }

  /// Loads the permissions associated with this role.
  Future<List<Permission>> loadPermissions() async {
    final ids = await loadHasManyIds('permissions');
    if (ids.isEmpty) return [];

    final permissions = <Permission>[];
    for (final id in ids) {
      final permission = await Permission.find(id);
      if (permission != null) {
        permissions.add(permission);
      }
    }
    return permissions;
  }

  /// Gets the permission slugs for this role.
  Future<Set<String>> getPermissionSlugs() async {
    final permissions = await loadPermissions();
    return permissions.map((p) => p.slug).toSet();
  }

  /// Finds a role by its slug.
  static Future<Role?> findBySlug(String slug) {
    return query().where('slug', '=', slug).first();
  }
}
