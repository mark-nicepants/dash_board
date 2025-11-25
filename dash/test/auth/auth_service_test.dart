import 'package:dash/dash.dart';
import 'package:test/test.dart';

void main() {
  group('AuthService - Password Hashing', () {
    test('hashPassword creates a valid bcrypt hash', () {
      final hash = AuthService.hashPassword('mypassword');

      // Bcrypt hashes start with $2a$, $2b$, or $2y$
      expect(RegExp(r'\$2[aby]\$').hasMatch(hash), isTrue);
      // Bcrypt hashes are 60 characters long
      expect(hash.length, equals(60));
    });

    test('hashPassword creates different hashes for same password', () {
      final hash1 = AuthService.hashPassword('password');
      final hash2 = AuthService.hashPassword('password');

      // Due to random salt, hashes should be different
      expect(hash1, isNot(equals(hash2)));
    });

    test('verifyPassword returns true for correct password', () {
      final password = 'mysecurepassword';
      final hash = AuthService.hashPassword(password);

      expect(AuthService.verifyPassword(password, hash), isTrue);
    });

    test('verifyPassword returns false for incorrect password', () {
      final hash = AuthService.hashPassword('correctpassword');

      expect(AuthService.verifyPassword('wrongpassword', hash), isFalse);
    });

    test('verifyPassword handles invalid hash format', () {
      expect(AuthService.verifyPassword('password', 'invalid-hash'), isFalse);
    });

    test('hashPassword with custom rounds works', () {
      final hash = AuthService.hashPassword('password', rounds: 10);
      expect(hash, startsWith(r'$2a$10$'));
    });
  });

  group('AuthService - Session Management', () {
    late AuthService authService;

    setUp(() {
      authService = AuthService();
    });

    test('default admin user exists', () {
      final sessionId = authService.login('admin@example.com', 'password');
      expect(sessionId, isNotNull);
      expect(sessionId!.length, greaterThan(30)); // Should be a long random token
    });

    test('login with correct credentials returns session ID', () {
      authService.addUser(
        DashUser(
          email: 'test@example.com',
          passwordHash: AuthService.hashPassword('testpass'),
          name: 'Test User',
          role: 'user',
        ),
      );

      final sessionId = authService.login('test@example.com', 'testpass');
      expect(sessionId, isNotNull);
    });

    test('login with incorrect password returns null', () {
      authService.addUser(
        DashUser(
          email: 'test@example.com',
          passwordHash: AuthService.hashPassword('testpass'),
          name: 'Test User',
          role: 'user',
        ),
      );

      final sessionId = authService.login('test@example.com', 'wrongpass');
      expect(sessionId, isNull);
    });

    test('login with non-existent user returns null', () {
      final sessionId = authService.login('nonexistent@example.com', 'password');
      expect(sessionId, isNull);
    });

    test('session tokens are cryptographically random', () {
      final sessionId1 = authService.login('admin@example.com', 'password');
      authService.logout(sessionId1!);
      final sessionId2 = authService.login('admin@example.com', 'password');

      // Session IDs should be different even for same user
      expect(sessionId1, isNot(equals(sessionId2)));
    });

    test('isAuthenticated returns true for valid session', () {
      final sessionId = authService.login('admin@example.com', 'password');
      expect(authService.isAuthenticated(sessionId), isTrue);
    });

    test('isAuthenticated returns false for null session', () {
      expect(authService.isAuthenticated(null), isFalse);
    });

    test('isAuthenticated returns false for invalid session', () {
      expect(authService.isAuthenticated('invalid-session-id'), isFalse);
    });

    test('logout removes session', () {
      final sessionId = authService.login('admin@example.com', 'password');
      expect(authService.isAuthenticated(sessionId), isTrue);

      authService.logout(sessionId!);
      expect(authService.isAuthenticated(sessionId), isFalse);
    });

    test('getUser returns user for valid session', () {
      final sessionId = authService.login('admin@example.com', 'password');
      final user = authService.getUser(sessionId);

      expect(user, isNotNull);
      expect(user!.email, equals('admin@example.com'));
      expect(user.name, equals('Admin User'));
    });

    test('getUser returns null for invalid session', () {
      final user = authService.getUser('invalid-session');
      expect(user, isNull);
    });
  });

  group('AuthService - Session Expiration', () {
    late AuthService authService;

    setUp(() {
      authService = AuthService();
    });

    test('sessions expire after specified duration', () async {
      // Create a session that expires in 100ms
      final sessionId = authService.login(
        'admin@example.com',
        'password',
        sessionDuration: const Duration(milliseconds: 100),
      );

      expect(authService.isAuthenticated(sessionId), isTrue);

      // Wait for expiration
      await Future.delayed(const Duration(milliseconds: 150));

      expect(authService.isAuthenticated(sessionId), isFalse);
    });

    test('expired sessions are automatically removed on check', () async {
      final sessionId = authService.login(
        'admin@example.com',
        'password',
        sessionDuration: const Duration(milliseconds: 50),
      );

      await Future.delayed(const Duration(milliseconds: 100));

      // First check should remove the expired session
      expect(authService.isAuthenticated(sessionId), isFalse);
      // Second check should also return false (session is gone)
      expect(authService.isAuthenticated(sessionId), isFalse);
    });

    test('getUser returns null for expired session', () async {
      final sessionId = authService.login(
        'admin@example.com',
        'password',
        sessionDuration: const Duration(milliseconds: 50),
      );

      await Future.delayed(const Duration(milliseconds: 100));

      final user = authService.getUser(sessionId);
      expect(user, isNull);
    });

    test('cleanupExpiredSessions removes expired sessions', () async {
      // Create multiple sessions with short expiration
      final session1 = authService.login(
        'admin@example.com',
        'password',
        sessionDuration: const Duration(milliseconds: 50),
      );

      authService.logout(session1!);

      final session2 = authService.login(
        'admin@example.com',
        'password',
        sessionDuration: const Duration(milliseconds: 50),
      );

      // Wait for expiration
      await Future.delayed(const Duration(milliseconds: 100));

      // Cleanup
      authService.cleanupExpiredSessions();

      // Session should be gone
      expect(authService.isAuthenticated(session2), isFalse);
    });
  });

  group('Session class', () {
    test('isExpired returns false for future expiration', () {
      final session = Session(
        id: 'test-id',
        email: 'test@example.com',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );

      expect(session.isExpired, isFalse);
    });

    test('isExpired returns true for past expiration', () {
      final session = Session(
        id: 'test-id',
        email: 'test@example.com',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      expect(session.isExpired, isTrue);
    });

    test('timeRemaining returns correct duration', () {
      final expiresAt = DateTime.now().add(const Duration(minutes: 30));
      final session = Session(
        id: 'test-id',
        email: 'test@example.com',
        createdAt: DateTime.now(),
        expiresAt: expiresAt,
      );

      final remaining = session.timeRemaining;
      // Should be approximately 30 minutes (allow small variance)
      expect(remaining.inSeconds, greaterThan(29 * 60));
      expect(remaining.inSeconds, lessThan(31 * 60));
    });
  });
}
