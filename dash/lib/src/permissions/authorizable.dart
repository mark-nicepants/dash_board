import 'package:dash_board/src/model/model.dart';
import 'package:dash_board/src/permissions/models/permission.dart';
import 'package:dash_board/src/permissions/models/role.dart';
import 'package:dash_board/src/permissions/permission_service.dart';

/// Mixin that adds authorization capabilities to User models.
///
/// When applied to a model, it provides methods for checking permissions,
/// managing roles, and handling both role-based and direct permission assignments.
///
/// ## Usage
///
/// Apply the mixin to your User model:
///
/// ```dart
/// class User extends Model with Authorizable {
///   // ... your user fields
///
///   @override
///   Future<List<Role>> getRoles() => loadHasManyRelation<Role>('roles');
///
///   @override
///   Future<List<Permission>> getDirectPermissions() =>
///       loadHasManyRelation<Permission>('permissions');
/// }
/// ```
///
/// Then use the permission methods:
///
/// ```dart
/// final user = await User.find(1);
/// if (await user.can('edit_posts')) {
///   // User has the 'edit_posts' permission
/// }
/// ```
mixin Authorizable on Model {
  /// Gets the roles assigned to this user.
  ///
  /// This should load roles from the `user_role` pivot table.
  /// Override this to implement the actual loading logic.
  Future<List<Role>> getRoles() async {
    try {
      final ids = await loadHasManyIds('roles');
      if (ids.isEmpty) return [];

      final roles = <Role>[];
      for (final id in ids) {
        final role = await Role.find(id);
        if (role != null) {
          roles.add(role);
        }
      }
      return roles;
    } catch (e) {
      // Table might not exist yet
      return [];
    }
  }

  /// Gets the direct permissions assigned to this user.
  ///
  /// These are permissions assigned directly to the user,
  /// not through roles. Loaded from `user_permission` pivot table.
  Future<List<Permission>> getDirectPermissions() async {
    try {
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
    } catch (e) {
      // Table might not exist yet
      return [];
    }
  }

  /// Gets all permissions for this user.
  ///
  /// This includes:
  /// - Direct permissions assigned to the user
  /// - Permissions inherited from roles
  ///
  /// Results are combined and deduplicated.
  Future<Set<Permission>> getAllPermissions() async {
    final permissions = <Permission>{};

    // Add direct permissions
    final directPermissions = await getDirectPermissions();
    permissions.addAll(directPermissions);

    // Add permissions from roles
    final roles = await getRoles();
    for (final role in roles) {
      final rolePermissions = await role.loadPermissions();
      permissions.addAll(rolePermissions);
    }

    return permissions;
  }

  /// Gets all permission slugs for this user (cached).
  ///
  /// Uses the PermissionService for caching.
  Future<Set<String>> getAllPermissionSlugs() {
    return PermissionService.getUserPermissions(this);
  }

  /// Checks if the user has a specific permission.
  ///
  /// Returns `true` if the user has the permission either:
  /// - Directly assigned to them
  /// - Inherited through one of their roles
  ///
  /// ```dart
  /// if (await user.can('edit_posts')) {
  ///   // User can edit posts
  /// }
  /// ```
  Future<bool> can(String permission) {
    return PermissionService.hasPermission(this, permission);
  }

  /// Checks if the user has any of the given permissions.
  ///
  /// Returns `true` if the user has at least one of the permissions.
  ///
  /// ```dart
  /// if (await user.canAny(['edit_posts', 'delete_posts'])) {
  ///   // User can edit OR delete posts
  /// }
  /// ```
  Future<bool> canAny(List<String> permissions) async {
    if (permissions.isEmpty) return false;

    final userPermissions = await getAllPermissionSlugs();
    return permissions.any(userPermissions.contains);
  }

  /// Checks if the user has all of the given permissions.
  ///
  /// Returns `true` only if the user has every permission in the list.
  ///
  /// ```dart
  /// if (await user.canAll(['edit_posts', 'delete_posts'])) {
  ///   // User can edit AND delete posts
  /// }
  /// ```
  Future<bool> canAll(List<String> permissions) async {
    if (permissions.isEmpty) return true;

    final userPermissions = await getAllPermissionSlugs();
    return permissions.every(userPermissions.contains);
  }

  /// Checks if the user has a specific role.
  ///
  /// ```dart
  /// if (await user.hasRole('admin')) {
  ///   // User has the admin role
  /// }
  /// ```
  Future<bool> hasRole(String roleSlug) async {
    final roles = await getRoles();
    return roles.any((role) => role.slug == roleSlug);
  }

  /// Checks if the user has any of the given roles.
  Future<bool> hasAnyRole(List<String> roleSlugs) async {
    if (roleSlugs.isEmpty) return false;

    final roles = await getRoles();
    final userRoleSlugs = roles.map((r) => r.slug).toSet();
    return roleSlugs.any(userRoleSlugs.contains);
  }

  /// Assigns a role to the user.
  ///
  /// ```dart
  /// await user.assignRole('editor');
  /// ```
  Future<void> assignRole(String roleSlug) async {
    final role = await Role.findBySlug(roleSlug);
    if (role == null) {
      throw StateError('Role "$roleSlug" not found');
    }

    // Get current role IDs and add the new one
    final currentIds = await loadHasManyIds('roles');
    if (!currentIds.contains(role.id)) {
      await attachMany('roles', [role.id]);
      // Clear permission cache
      PermissionService.clearCache(getKey());
    }
  }

  /// Removes a role from the user.
  ///
  /// ```dart
  /// await user.removeRole('editor');
  /// ```
  Future<void> removeRole(String roleSlug) async {
    final role = await Role.findBySlug(roleSlug);
    if (role == null) {
      throw StateError('Role "$roleSlug" not found');
    }

    await detachMany('roles', [role.id]);
    // Clear permission cache
    PermissionService.clearCache(getKey());
  }

  /// Syncs the user's roles to exactly the given role slugs.
  ///
  /// Removes any roles not in the list and adds missing ones.
  ///
  /// ```dart
  /// await user.syncRoles(['admin', 'editor']);
  /// ```
  Future<void> syncRoles(List<String> roleSlugs) async {
    final roleIds = <int>[];
    for (final slug in roleSlugs) {
      final role = await Role.findBySlug(slug);
      if (role != null && role.id != null) {
        roleIds.add(role.id!);
      }
    }

    await syncMany('roles', roleIds);
    // Clear permission cache
    PermissionService.clearCache(getKey());
  }

  /// Gives a direct permission to the user.
  ///
  /// This assigns the permission directly to the user, not through a role.
  ///
  /// ```dart
  /// await user.givePermission('special_access');
  /// ```
  Future<void> givePermission(String permissionSlug) async {
    final permission = await Permission.findBySlug(permissionSlug);
    if (permission == null) {
      throw StateError('Permission "$permissionSlug" not found');
    }

    final currentIds = await loadHasManyIds('permissions');
    if (!currentIds.contains(permission.id)) {
      await attachMany('permissions', [permission.id]);
      // Clear permission cache
      PermissionService.clearCache(getKey());
    }
  }

  /// Revokes a direct permission from the user.
  ///
  /// ```dart
  /// await user.revokePermission('special_access');
  /// ```
  Future<void> revokePermission(String permissionSlug) async {
    final permission = await Permission.findBySlug(permissionSlug);
    if (permission == null) {
      throw StateError('Permission "$permissionSlug" not found');
    }

    await detachMany('permissions', [permission.id]);
    // Clear permission cache
    PermissionService.clearCache(getKey());
  }

  /// Syncs the user's direct permissions to exactly the given slugs.
  ///
  /// ```dart
  /// await user.syncPermissions(['read_reports', 'export_data']);
  /// ```
  Future<void> syncPermissions(List<String> permissionSlugs) async {
    final permissionIds = <int>[];
    for (final slug in permissionSlugs) {
      final permission = await Permission.findBySlug(slug);
      if (permission != null && permission.id != null) {
        permissionIds.add(permission.id!);
      }
    }

    await syncMany('permissions', permissionIds);
    // Clear permission cache
    PermissionService.clearCache(getKey());
  }
}
