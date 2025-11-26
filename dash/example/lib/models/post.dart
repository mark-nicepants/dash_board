import 'package:dash/dash.dart';
import 'package:dash_example/models/user.dart';

part 'post.model.g.dart';

/// Post model representing blog posts.
@DashModel(table: 'posts', timestamps: false)
class Post extends Model with _$PostModelMixin {
  int? id;
  String? title;
  String? content;

  @Column(name: 'user_id')
  int? userId;

  String? status;

  @Column(name: 'published_at')
  DateTime? publishedAt;

  @Column(name: 'created_at')
  DateTime? createdAt;

  // Relationship
  @BelongsTo(foreignKey: 'user_id')
  User? author;

  Post({this.id, this.title, this.content, this.userId, this.status, this.publishedAt, this.createdAt, this.author});

  // ===== Validation Rules =====
  @override
  Map<String, List<ValidationRule>> get rules => {
    'title': [Required(), MinLength(3), MaxLength(200)],
    'content': [Required(), MinLength(10)],
    'status': [
      Required(),
      InList(['draft', 'published', 'archived']),
    ],
  };

  // ===== Lifecycle Hooks =====
  @override
  Future<void> onCreating() async {
    // Set default status if not provided
    status ??= 'draft';
    print('📝 Creating post: $title');
  }

  // ===== Query Scopes =====

  /// Gets published posts.
  static Future<List<Post>> published() async {
    return PostModel.query().where('status', 'published').get();
  }

  /// Gets draft posts.
  static Future<List<Post>> drafts() async {
    return PostModel.query().where('status', 'draft').get();
  }

  /// Loads the author relationship.
  Future<void> loadAuthor() async {
    if (userId != null) {
      author = await UserModel.find(userId!);
    }
  }
}
