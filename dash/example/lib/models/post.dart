// GENERATED CODE - DO NOT MODIFY BY HAND
// Generated from schema: post

import 'package:dash/dash.dart';

class Post extends Model {
  @override
  String get table => 'posts';

  @override
  String get primaryKey => 'id';

  @override
  bool get timestamps => true;

  int? id;
  String title;
  String slug;
  String? content;
  bool? isPublished;
  DateTime? publishedAt;
  int author;

  /// Stores loaded relationship models.
  final Map<String, Model> _loadedRelations = {};

  Post({
    this.id,
    required this.title,
    required this.slug,
    this.content,
    this.isPublished,
    this.publishedAt,
    required this.author,
  });

  @override
  dynamic getKey() => id;

  @override
  void setKey(dynamic value) {
    id = value as int?;
  }

  @override
  List<String> getFields() {
    return ['id', 'title', 'slug', 'content', 'is_published', 'published_at', 'author_id', 'created_at', 'updated_at'];
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'content': content,
      'is_published': isPublished == true ? 1 : 0,
      'published_at': publishedAt?.toIso8601String(),
      'author_id': author,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  void fromMap(Map<String, dynamic> map) {
    id = getFromMap<int>(map, 'id');
    title = getFromMap<String>(map, 'title') ?? '';
    slug = getFromMap<String>(map, 'slug') ?? '';
    content = getFromMap<String>(map, 'content');
    isPublished = map['is_published'] == 1 || map['is_published'] == true;
    publishedAt = parseDateTime(map['published_at']);
    author = getFromMap<int>(map, 'author_id') ?? 0;
    createdAt = parseDateTime(map['created_at']);
    updatedAt = parseDateTime(map['updated_at']);
  }

  Post copyWith({
    int? id,
    String? title,
    String? slug,
    String? content,
    bool? isPublished,
    DateTime? publishedAt,
    int? author,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Post(
      id: id ?? this.id,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      content: content ?? this.content,
      isPublished: isPublished ?? this.isPublished,
      publishedAt: publishedAt ?? this.publishedAt,
      author: author ?? this.author,
    )
      ..createdAt = createdAt ?? this.createdAt
      ..updatedAt = updatedAt ?? this.updatedAt;
  }

  /// Factory constructor for creating empty instances.
  /// Used internally by query builder and model registration.
  factory Post.empty() => Post._empty();

  /// Creates a query builder for Posts.
  static ModelQueryBuilder<Post> query() {
    return ModelQueryBuilder<Post>(
      Model.connector,
      modelFactory: Post.empty,
      modelTable: 'posts',
      modelPrimaryKey: 'id',
    );
  }

  /// Finds a Post by its primary key.
  static Future<Post?> find(dynamic id) => query().find(id);

  /// Gets all Posts.
  static Future<List<Post>> all() => query().get();

  /// Registers this model and optionally a resource factory.
  static void register([Resource<Post> Function()? resourceFactory]) {
    registerModelMetadata<Post>(
      ModelMetadata<Post>(
        modelFactory: Post.empty,
        schema: Post.schema,
      ),
    );
    if (resourceFactory != null) {
      registerResourceFactory<Post>(resourceFactory);
    }
  }

  /// Internal empty constructor.
  Post._empty()
      : title = '',
        slug = '',
        author = 0;

  /// Gets the table schema for automatic migrations.
  static TableSchema get schema {
    return const TableSchema(
      name: 'posts',
      columns: [
        ColumnDefinition(
          name: 'id',
          type: ColumnType.integer,
          isPrimaryKey: true,
          autoIncrement: true,
          nullable: true,
        ),
        ColumnDefinition(
          name: 'title',
          type: ColumnType.text,
          nullable: false,
        ),
        ColumnDefinition(
          name: 'slug',
          type: ColumnType.text,
          unique: true,
          nullable: false,
        ),
        ColumnDefinition(
          name: 'content',
          type: ColumnType.text,
          nullable: true,
        ),
        ColumnDefinition(
          name: 'is_published',
          type: ColumnType.boolean,
          nullable: true,
        ),
        ColumnDefinition(
          name: 'published_at',
          type: ColumnType.datetime,
          nullable: true,
        ),
        ColumnDefinition(
          name: 'author_id',
          type: ColumnType.integer,
          nullable: false,
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
    const RelationshipMeta(
      name: 'author',
      type: RelationshipType.belongsTo,
      foreignKey: 'author_id',
      relatedKey: 'id',
      relatedModelType: 'User',
    ),
  ];

  @override
  Model? getRelation(String name) => _loadedRelations[name];

  /// Sets a loaded relationship by name.
  void setRelation(String name, Model value) {
    _loadedRelations[name] = value;
  }

  /// Get the related User via [userRelation].
  // Foreign key: 'author_id'

}
