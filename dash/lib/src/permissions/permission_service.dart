import 'package:dash/src/model/model.dart';
import 'package:dash/src/permissions/models/permission.dart';
import 'package:dash/src/permissions/models/role.dart';

/// Service for checking and caching user permissions.
///
/// This service provides efficient permission checking with per-request
/// caching to avoid repeated database queries for the same user.
///
/// ## Usage
///
/// ```dart
/// // Check a single permission
/// if (await PermissionService.hasPermission(user, 'edit_posts')) {
///   // User can edit posts
/// }
///
/// // Get all permissions (cached)
/// final permissions = await PermissionService.getUserPermissions(user);
/// ```
class PermissionService {
  /// Cache of user permissions by user ID.
  ///
  /// Keys are user IDs (dynamic to support int or string PKs).
  /// Values are sets of permission slugs.
  static final Map<dynamic, Set<String>> _cache = {};

  /// Checks if a user has a specific permission.
  ///
  /// This method checks both:
  /// - Direct permissions assigned to the user
  /// - Permissions inherited through roles
  ///
  /// Results are cached per user for performance.
  static Future<bool> hasPermission(Model user, String permission) async {
    final permissions = await getUserPermissions(user);
    return permissions.contains(permission);
  }

  /// Checks if a user has any of the given permissions.
  static Future<bool> hasAnyPermission(Model user, List<String> permissions) async {
    if (permissions.isEmpty) return false;

    final userPermissions = await getUserPermissions(user);
    return permissions.any(userPermissions.contains);
  }

  /// Checks if a user has all of the given permissions.
  static Future<bool> hasAllPermissions(Model user, List<String> permissions) async {
    if (permissions.isEmpty) return true;

    final userPermissions = await getUserPermissions(user);
    return permissions.every(userPermissions.contains);
  }

  /// Gets all permission slugs for a user (with caching).
  ///
  /// This method loads and caches the user's permissions from:
  /// 1. Direct permissions (user_permission pivot)
  /// 2. Role permissions (through user_role and role_permission pivots)
  static Future<Set<String>> getUserPermissions(Model user) async {
    final userId = user.getKey();
    if (userId == null) return {};

    // Check cache first
    if (_cache.containsKey(userId)) {
      return _cache[userId]!;
    }

    // Load permissions
    final permissions = await _loadUserPermissions(user);
    _cache[userId] = permissions;
    return permissions;
  }

  /// Loads permissions for a user from the database.
  static Future<Set<String>> _loadUserPermissions(Model user) async {
    final permissions = <String>{};
    final userId = user.getKey();
    if (userId == null) return permissions;

    try {
      // Load direct permissions
      final directPermissionIds = await _loadDirectPermissionIds(userId);
      for (final id in directPermissionIds) {
        final permission = await Permission.find(id);
        if (permission != null) {
          permissions.add(permission.slug);
        }
      }

      // Load role permissions
      final roleIds = await _loadUserRoleIds(userId);
      for (final roleId in roleIds) {
        final role = await Role.find(roleId);
        if (role != null) {
          final rolePermissions = await role.loadPermissions();
          for (final permission in rolePermissions) {
            permissions.add(permission.slug);
          }
        }
      }
    } catch (e) {
      // Tables might not exist yet during initial setup
      // Return empty set
    }

    return permissions;
  }

  /// Loads direct permission IDs for a user.
  static Future<List<dynamic>> _loadDirectPermissionIds(dynamic userId) async {
    try {
      final rows = await Model.connector.query('SELECT permission_id FROM user_permission WHERE user_id = ?', [userId]);
      return rows.map((r) => r['permission_id']).toList();
    } catch (e) {
      // Table might not exist
      return [];
    }
  }

  /// Loads role IDs for a user.
  static Future<List<dynamic>> _loadUserRoleIds(dynamic userId) async {
    try {
      final rows = await Model.connector.query('SELECT role_id FROM user_role WHERE user_id = ?', [userId]);
      return rows.map((r) => r['role_id']).toList();
    } catch (e) {
      // Table might not exist
      return [];
    }
  }

  /// Clears the permission cache for a specific user.
  ///
  /// Call this after modifying a user's roles or permissions.
  static void clearCache(dynamic userId) {
    _cache.remove(userId);
  }

  /// Clears all cached permissions.
  ///
  /// Useful after bulk permission updates or for testing.
  static void clearAllCache() {
    _cache.clear();
  }

  /// Pre-warms the cache for a list of users.
  ///
  /// Useful for batch operations where you know you'll need
  /// to check permissions for multiple users.
  static Future<void> warmCache(List<Model> users) async {
    for (final user in users) {
      await getUserPermissions(user);
    }
  }
}
