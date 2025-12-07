import 'package:dash_board/dash_board.dart';
import 'package:test/test.dart';

void main() {
  group('Role Model', () {
    late SqliteConnector connector;

    setUpAll(() async {
      // Set up in-memory SQLite database
      connector = SqliteConnector(':memory:');
      await connector.connect();
      Model.setConnector(connector);

      // Create roles table
      await connector.execute('''
        CREATE TABLE roles (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          slug TEXT NOT NULL UNIQUE,
          description TEXT,
          is_default INTEGER DEFAULT 0,
          created_at TEXT,
          updated_at TEXT
        )
      ''');

      // Create permissions table
      await connector.execute('''
        CREATE TABLE permissions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          slug TEXT NOT NULL UNIQUE,
          description TEXT,
          created_at TEXT,
          updated_at TEXT
        )
      ''');

      // Create permission_role pivot table
      await connector.execute('''
        CREATE TABLE permission_role (
          role_id INTEGER NOT NULL,
          permission_id INTEGER NOT NULL,
          PRIMARY KEY (role_id, permission_id)
        )
      ''');

      // Create user_role pivot table
      await connector.execute('''
        CREATE TABLE user_role (
          user_id INTEGER NOT NULL,
          role_id INTEGER NOT NULL,
          PRIMARY KEY (user_id, role_id)
        )
      ''');
    });

    tearDownAll(() async {
      await connector.close();
    });

    setUp(() async {
      // Clean up tables before each test
      await connector.execute('DELETE FROM permission_role');
      await connector.execute('DELETE FROM user_role');
      await connector.execute('DELETE FROM roles');
      await connector.execute('DELETE FROM permissions');
    });

    test('can create a role', () async {
      final role = Role(name: 'Admin', slug: 'admin', description: 'Administrator role');
      await role.save();

      expect(role.id, isNotNull);
      expect(role.id, greaterThan(0));
    });

    test('can find role by slug', () async {
      final role = Role(name: 'Editor', slug: 'editor');
      await role.save();

      final found = await Role.findBySlug('editor');
      expect(found, isNotNull);
      expect(found!.name, equals('Editor'));
    });

    test('can update a role', () async {
      final role = Role(name: 'Original', slug: 'original');
      await role.save();

      role.name = 'Updated';
      await role.save();

      final found = await Role.find(role.id);
      expect(found!.name, equals('Updated'));
    });

    test('can delete a role without users', () async {
      final role = Role(name: 'Deletable', slug: 'deletable');
      await role.save();
      final roleId = role.id;

      await role.delete();

      final found = await Role.find(roleId);
      expect(found, isNull);
    });

    test('cannot delete role with assigned users', () async {
      final role = Role(name: 'Protected', slug: 'protected');
      await role.save();

      // Assign a user to this role
      await connector.insert('user_role', {'user_id': 1, 'role_id': role.id});

      // Attempting to delete should throw
      expect(
        role.delete,
        throwsA(isA<StateError>().having((e) => e.message, 'message', contains('Cannot delete role'))),
      );
    });

    test('can attach permissions to role', () async {
      final role = Role(name: 'Manager', slug: 'manager');
      await role.save();

      final permission1 = Permission(name: 'Create Posts', slug: 'create_posts');
      final permission2 = Permission(name: 'Edit Posts', slug: 'edit_posts');
      await permission1.save();
      await permission2.save();

      await role.attachMany('permissions', [permission1.id, permission2.id]);

      final permissionIds = await role.loadHasManyIds('permissions');
      expect(permissionIds.length, equals(2));
      expect(permissionIds, contains(permission1.id));
      expect(permissionIds, contains(permission2.id));
    });

    test('can load permissions for role', () async {
      final role = Role(name: 'Viewer', slug: 'viewer');
      await role.save();

      final permission = Permission(name: 'View Posts', slug: 'view_posts');
      await permission.save();

      await role.attachMany('permissions', [permission.id]);

      final permissions = await role.loadPermissions();
      expect(permissions.length, equals(1));
      expect(permissions.first.slug, equals('view_posts'));
    });

    test('can get permission slugs', () async {
      final role = Role(name: 'Writer', slug: 'writer');
      await role.save();

      final p1 = Permission(name: 'Create', slug: 'create');
      final p2 = Permission(name: 'Edit', slug: 'edit');
      await p1.save();
      await p2.save();

      await role.attachMany('permissions', [p1.id, p2.id]);

      final slugs = await role.getPermissionSlugs();
      expect(slugs, contains('create'));
      expect(slugs, contains('edit'));
    });
  });

  group('Permission Model', () {
    late SqliteConnector connector;

    setUpAll(() async {
      connector = SqliteConnector(':memory:');
      await connector.connect();
      Model.setConnector(connector);

      await connector.execute('''
        CREATE TABLE permissions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          slug TEXT NOT NULL UNIQUE,
          description TEXT,
          created_at TEXT,
          updated_at TEXT
        )
      ''');

      await connector.execute('''
        CREATE TABLE permission_role (
          role_id INTEGER NOT NULL,
          permission_id INTEGER NOT NULL,
          PRIMARY KEY (role_id, permission_id)
        )
      ''');

      await connector.execute('''
        CREATE TABLE user_permission (
          user_id INTEGER NOT NULL,
          permission_id INTEGER NOT NULL,
          PRIMARY KEY (user_id, permission_id)
        )
      ''');
    });

    tearDownAll(() async {
      await connector.close();
    });

    setUp(() async {
      await connector.execute('DELETE FROM permission_role');
      await connector.execute('DELETE FROM user_permission');
      await connector.execute('DELETE FROM permissions');
    });

    test('can create a permission', () async {
      final permission = Permission(name: 'Delete Posts', slug: 'delete_posts');
      await permission.save();

      expect(permission.id, isNotNull);
      expect(permission.id, greaterThan(0));
    });

    test('can find permission by slug', () async {
      final permission = Permission(name: 'Manage Users', slug: 'manage_users');
      await permission.save();

      final found = await Permission.findBySlug('manage_users');
      expect(found, isNotNull);
      expect(found!.name, equals('Manage Users'));
    });

    test('can delete permission without roles', () async {
      final permission = Permission(name: 'Temp', slug: 'temp');
      await permission.save();
      final id = permission.id;

      await permission.delete();

      final found = await Permission.find(id);
      expect(found, isNull);
    });

    test('cannot delete permission assigned to roles', () async {
      final permission = Permission(name: 'Protected', slug: 'protected');
      await permission.save();

      // Assign to a role
      await connector.insert('permission_role', {'role_id': 1, 'permission_id': permission.id});

      expect(
        permission.delete,
        throwsA(isA<StateError>().having((e) => e.message, 'message', contains('Cannot delete permission'))),
      );
    });

    test('cannot delete permission assigned to users', () async {
      final permission = Permission(name: 'UserPerm', slug: 'user_perm');
      await permission.save();

      // Assign directly to a user
      await connector.insert('user_permission', {'user_id': 1, 'permission_id': permission.id});

      expect(
        permission.delete,
        throwsA(isA<StateError>().having((e) => e.message, 'message', contains('Cannot delete permission'))),
      );
    });
  });
}
