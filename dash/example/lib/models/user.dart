import 'package:dash/dash.dart';

part 'user.model.g.dart';

/// User model demonstrating Dash's improved model features.
@DashModel(table: 'users', timestamps: false)
class User extends Model with _$UserModelMixin {
  int? id;
  String? name;
  String? email;
  String? role;

  @Column(name: 'created_at')
  DateTime? createdAt;

  User({this.id, this.name, this.email, this.role, this.createdAt});

  // ===== Validation Rules =====
  @override
  Map<String, List<ValidationRule>> get rules => {
    'name': [Required(), MinLength(2)],
    'email': [Required(), Email()],
    'role': [
      Required(),
      InList(['user', 'admin', 'moderator']),
    ],
  };

  // ===== Lifecycle Hooks =====
  @override
  Future<void> onCreating() async {
    print('🎉 Creating user: $name');
    // Set default role if not provided
    role ??= 'user';
  }

  @override
  Future<void> onCreated() async {
    print('✅ User created with ID: $id');
  }

  // ===== Query Scopes (Reusable Query Methods) =====

  /// Get all admin users
  static Future<List<User>> admins() async {
    return UserModel.query().where('role', 'admin').get();
  }

  /// Get all moderator users
  static Future<List<User>> moderators() async {
    return UserModel.query().where('role', 'moderator').get();
  }

  /// Get users by role
  static Future<List<User>> byRole(String role) async {
    return UserModel.query().where('role', role).get();
  }

  /// Find user by email
  static Future<User?> findByEmail(String email) async {
    return UserModel.query().where('email', email).first();
  }
}
