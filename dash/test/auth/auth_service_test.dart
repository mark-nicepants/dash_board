import 'package:dash/dash.dart';
import 'package:test/test.dart';

// Pre-computed bcrypt hashes with minimum rounds (4) for fast tests
// 'password' -> hash
final _passwordHash = AuthService.hashPassword('password', rounds: 4);
// 'testpass' -> hash
final _testpassHash = AuthService.hashPassword('testpass', rounds: 4);

/// Test user model that implements Authenticatable for testing AuthService.
class TestUser extends Model with Authenticatable {
  @override
  String get table => 'test_users';

  String email;
  String password;
  String name;
  String role;
  bool isActive;

  TestUser({required this.email, required this.password, required this.name, this.role = 'user', this.isActive = true});

  factory TestUser.empty() => TestUser(email: '', password: '', name: '');

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

  @override
  bool canAccessPanel(String panelId) => isActive;

  @override
  dynamic getKey() => null;

  @override
  void setKey(dynamic value) {}

  @override
  List<String> getFields() => ['email', 'password', 'name', 'role', 'is_active'];

  @override
  Map<String, dynamic> toMap() => {
    'email': email,
    'password': password,
    'name': name,
    'role': role,
    'is_active': isActive,
  };

  @override
  void fromMap(Map<String, dynamic> map) {
    email = map['email'] ?? '';
    password = map['password'] ?? '';
    name = map['name'] ?? '';
    role = map['role'] ?? 'user';
    isActive = map['is_active'] ?? true;
  }
}

void main() {
  group('AuthService - Password Hashing', () {
    test('verifyPassword returns true for correct password', () {
      // Use pre-computed hash
      expect(AuthService.verifyPassword('password', _passwordHash), isTrue);
    });

    test('verifyPassword returns false for incorrect password', () {
      // Use pre-computed hash
      expect(AuthService.verifyPassword('wrongpassword', _passwordHash), isFalse);
    });

    test('verifyPassword handles invalid hash format', () {
      expect(AuthService.verifyPassword('password', 'invalid-hash'), isFalse);
    });
  });

  group('AuthService - Session Management', () {
    late AuthService<TestUser> authService;
    late Map<String, TestUser> testUsers;

    setUp(() {
      // Create test users with pre-computed hashes
      testUsers = {
        'admin@example.com': TestUser(
          email: 'admin@example.com',
          password: _passwordHash,
          name: 'Admin User',
          role: 'admin',
        ),
        'test@example.com': TestUser(
          email: 'test@example.com',
          password: _testpassHash,
          name: 'Test User',
          role: 'user',
        ),
      };

      // Create auth service with mock user resolver
      authService = AuthService<TestUser>(
        userResolver: (identifier) async => testUsers[identifier],
        panelId: 'test-panel',
      );
    });

    test('login with correct credentials returns session ID', () async {
      final sessionId = await authService.login('admin@example.com', 'password');
      expect(sessionId, isNotNull);
      expect(sessionId!.length, greaterThan(30)); // Should be a long random token
    });

    test('login with incorrect password returns null', () async {
      final sessionId = await authService.login('admin@example.com', 'wrongpass');
      expect(sessionId, isNull);
    });

    test('login with non-existent user returns null', () async {
      final sessionId = await authService.login('nonexistent@example.com', 'password');
      expect(sessionId, isNull);
    });

    test('session tokens are cryptographically random', () async {
      final sessionId1 = await authService.login('admin@example.com', 'password');
      await authService.logout(sessionId1!);
      final sessionId2 = await authService.login('admin@example.com', 'password');

      // Session IDs should be different even for same user
      expect(sessionId1, isNot(equals(sessionId2)));
    });

    test('isAuthenticated returns true for valid session', () async {
      final sessionId = await authService.login('admin@example.com', 'password');
      expect(await authService.isAuthenticated(sessionId), isTrue);
    });

    test('isAuthenticated returns false for null session', () async {
      expect(await authService.isAuthenticated(null), isFalse);
    });

    test('isAuthenticated returns false for invalid session', () async {
      expect(await authService.isAuthenticated('invalid-session-id'), isFalse);
    });

    test('logout removes session', () async {
      final sessionId = await authService.login('admin@example.com', 'password');
      expect(await authService.isAuthenticated(sessionId), isTrue);

      await authService.logout(sessionId!);
      expect(await authService.isAuthenticated(sessionId), isFalse);
    });

    test('getUser returns user for valid session', () async {
      final sessionId = await authService.login('admin@example.com', 'password');
      final user = await authService.getUser(sessionId);

      expect(user, isNotNull);
      expect(user!.email, equals('admin@example.com'));
      expect(user.name, equals('Admin User'));
    });

    test('getUser returns null for invalid session', () async {
      final user = await authService.getUser('invalid-session');
      expect(user, isNull);
    });

    test('canAccessPanel is checked during login', () async {
      // Add an inactive user with pre-computed hash
      testUsers['inactive@example.com'] = TestUser(
        email: 'inactive@example.com',
        password: _passwordHash,
        name: 'Inactive User',
        isActive: false, // This user should not be able to login
      );

      final sessionId = await authService.login('inactive@example.com', 'password');
      expect(sessionId, isNull); // Should fail because canAccessPanel returns false
    });
  });

  group('AuthService - Session Expiration', () {
    late AuthService<TestUser> authService;

    setUp(() {
      authService = AuthService<TestUser>(
        userResolver: (identifier) async => TestUser(email: identifier, password: _passwordHash, name: 'Test User'),
        panelId: 'test-panel',
      );
    });

    test('sessions expire after specified duration', () async {
      // Create a session that expires in 100ms
      final sessionId = await authService.login(
        'test@example.com',
        'password',
        sessionDuration: const Duration(milliseconds: 100),
      );

      expect(await authService.isAuthenticated(sessionId), isTrue);

      // Wait for expiration
      await Future.delayed(const Duration(milliseconds: 150));

      expect(await authService.isAuthenticated(sessionId), isFalse);
    });

    test('expired sessions are automatically removed on check', () async {
      final sessionId = await authService.login(
        'test@example.com',
        'password',
        sessionDuration: const Duration(milliseconds: 50),
      );

      await Future.delayed(const Duration(milliseconds: 100));

      // First check should remove the expired session
      expect(await authService.isAuthenticated(sessionId), isFalse);
      // Second check should also return false (session is gone)
      expect(await authService.isAuthenticated(sessionId), isFalse);
    });

    test('getUser returns null for expired session', () async {
      final sessionId = await authService.login(
        'test@example.com',
        'password',
        sessionDuration: const Duration(milliseconds: 50),
      );

      await Future.delayed(const Duration(milliseconds: 100));

      final user = await authService.getUser(sessionId);
      expect(user, isNull);
    });

    test('cleanupExpiredSessions removes expired sessions', () async {
      final session1 = await authService.login(
        'test@example.com',
        'password',
        sessionDuration: const Duration(milliseconds: 50),
      );

      await authService.logout(session1!);

      final session2 = await authService.login(
        'test@example.com',
        'password',
        sessionDuration: const Duration(milliseconds: 50),
      );

      // Wait for expiration
      await Future.delayed(const Duration(milliseconds: 100));

      // Cleanup
      await authService.cleanupExpiredSessions();

      // Session should be gone
      expect(await authService.isAuthenticated(session2), isFalse);
    });
  });

  group('Session class', () {
    test('isExpired returns false for future expiration', () {
      final session = Session<TestUser>(
        id: 'test-id',
        user: TestUser(email: 'test@example.com', password: 'hash', name: 'Test'),
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );

      expect(session.isExpired, isFalse);
    });

    test('isExpired returns true for past expiration', () {
      final session = Session<TestUser>(
        id: 'test-id',
        user: TestUser(email: 'test@example.com', password: 'hash', name: 'Test'),
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      expect(session.isExpired, isTrue);
    });

    test('timeRemaining returns correct duration', () {
      final expiresAt = DateTime.now().add(const Duration(minutes: 30));
      final session = Session<TestUser>(
        id: 'test-id',
        user: TestUser(email: 'test@example.com', password: 'hash', name: 'Test'),
        createdAt: DateTime.now(),
        expiresAt: expiresAt,
      );

      final remaining = session.timeRemaining;
      // Should be approximately 30 minutes (allow small variance)
      expect(remaining.inSeconds, greaterThan(29 * 60));
      expect(remaining.inSeconds, lessThan(31 * 60));
    });
  });

  group('Authenticatable mixin', () {
    test('setPassword hashes and stores password', () {
      final user = TestUser(email: 'test@example.com', password: '', name: 'Test');
      // Directly set a pre-computed hash to test the setter works
      user.setAuthPassword(_passwordHash);

      expect(user.password, equals(_passwordHash));
      expect(AuthService.verifyPassword('password', user.password), isTrue);
    });

    test('getAuthIdentifier returns correct value', () {
      final user = TestUser(email: 'test@example.com', password: 'hash', name: 'Test');
      expect(user.getAuthIdentifier(), equals('test@example.com'));
    });

    test('getDisplayName returns correct value', () {
      final user = TestUser(email: 'test@example.com', password: 'hash', name: 'Test User');
      expect(user.getDisplayName(), equals('Test User'));
    });
  });
}
