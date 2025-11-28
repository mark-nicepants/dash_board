// GENERATED CODE - DO NOT MODIFY BY HAND
// Generated from schema: user

import 'package:dash/dash.dart';

class User extends Model with Authenticatable {
  @override
  String get table => 'users';

  @override
  String get primaryKey => 'id';

  @override
  bool get timestamps => true;

  int? id;
  String name;
  String email;
  String password;
  String? avatar;
  String role;
  bool? isActive;

  User({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    this.avatar,
    required this.role,
    this.isActive,
  });

  @override
  dynamic getKey() => id;

  @override
  void setKey(dynamic value) {
    id = value as int?;
  }

  @override
  List<String> getFields() {
    return ['id', 'name', 'email', 'password', 'avatar', 'role', 'is_active', 'created_at', 'updated_at'];
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'avatar': avatar,
      'role': role,
      'is_active': isActive == true ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  void fromMap(Map<String, dynamic> map) {
    id = getFromMap<int>(map, 'id');
    name = getFromMap<String>(map, 'name') ?? '';
    email = getFromMap<String>(map, 'email') ?? '';
    password = getFromMap<String>(map, 'password') ?? '';
    avatar = getFromMap<String>(map, 'avatar');
    role = getFromMap<String>(map, 'role') ?? '';
    isActive = map['is_active'] == 1 || map['is_active'] == true;
    createdAt = parseDateTime(map['created_at']);
    updatedAt = parseDateTime(map['updated_at']);
  }

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? password,
    String? avatar,
    String? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
    )
      ..createdAt = createdAt ?? this.createdAt
      ..updatedAt = updatedAt ?? this.updatedAt;
  }

  /// Factory constructor for creating empty instances.
  /// Used internally by query builder and model registration.
  factory User.empty() => User._empty();

  /// Creates a query builder for Users.
  static ModelQueryBuilder<User> query() {
    return ModelQueryBuilder<User>(
      Model.connector,
      modelFactory: User.empty,
      modelTable: 'users',
      modelPrimaryKey: 'id',
    );
  }

  /// Finds a User by its primary key.
  static Future<User?> find(dynamic id) => query().find(id);

  /// Gets all Users.
  static Future<List<User>> all() => query().get();

  /// Registers this model and optionally a resource factory.
  static void register([Resource<User> Function()? resourceFactory]) {
    registerModelMetadata<User>(
      ModelMetadata<User>(
        modelFactory: User.empty,
        schema: User.schema,
      ),
    );
    if (resourceFactory != null) {
      registerResourceFactory<User>(resourceFactory);
    }
  }

  /// Internal empty constructor.
  User._empty()
      : name = '',
        email = '',
        password = '',
        role = '';

  /// Gets the table schema for automatic migrations.
  static TableSchema get schema {
    return const TableSchema(
      name: 'users',
      columns: [
        ColumnDefinition(
          name: 'id',
          type: ColumnType.integer,
          isPrimaryKey: true,
          autoIncrement: true,
          nullable: true,
        ),
        ColumnDefinition(
          name: 'name',
          type: ColumnType.text,
          nullable: false,
        ),
        ColumnDefinition(
          name: 'email',
          type: ColumnType.text,
          unique: true,
          nullable: false,
        ),
        ColumnDefinition(
          name: 'password',
          type: ColumnType.text,
          nullable: false,
        ),
        ColumnDefinition(
          name: 'avatar',
          type: ColumnType.text,
          nullable: true,
        ),
        ColumnDefinition(
          name: 'role',
          type: ColumnType.text,
          nullable: false,
        ),
        ColumnDefinition(
          name: 'is_active',
          type: ColumnType.boolean,
          nullable: true,
        ),
        ColumnDefinition(
          name: 'created_at',
          type: ColumnType.text,
          nullable: true,
        ),
        ColumnDefinition(
          name: 'updated_at',
          type: ColumnType.text,
          nullable: true,
        ),
      ],
    );
  }

  @override
  List<RelationshipMeta> getRelationships() => [
  ];


  // ═══════════════════════════════════════════════════════════════════════════
  // Authenticatable mixin implementation
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  String getAuthIdentifier() => email;

  @override
  String getAuthIdentifierName() => 'email';

  @override
  String getAuthPassword() => password;

  @override
  void setAuthPassword(String hash) {
    password = hash;
  }

  @override
  String getDisplayName() => name;

  // Override canAccessPanel(String panelId) to customize access control
}
