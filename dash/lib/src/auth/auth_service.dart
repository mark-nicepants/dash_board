import 'dart:convert';
import 'dart:math';

import 'package:bcrypt/bcrypt.dart';
import 'package:dash/src/auth/authenticatable.dart';
import 'package:dash/src/model/model.dart';

/// Function type for resolving users from a data source.
///
/// Takes an identifier (e.g., email) and returns the matching user model,
/// or null if no user is found.
typedef UserResolver<T> = Future<T?> Function(String identifier);

/// Generic authentication service for the Dash admin panel.
///
/// Handles user authentication, session management, and password verification.
/// Uses bcrypt for secure password hashing and cryptographically secure random
/// tokens for session management.
///
/// The service is generic over [T], which must be a [Model] that implements
/// the [Authenticatable] mixin. This allows developers to use their own
/// user model for authentication.
///
/// Example:
/// ```dart
/// final authService = AuthService<User>(
///   userResolver: (identifier) => User.query()
///     .where('email', '=', identifier)
///     .first(),
/// );
///
/// final sessionId = await authService.login('admin@example.com', 'password');
/// ```
class AuthService<T extends Model> {
  final Map<String, Session<T>> _sessions = {}; // sessionId -> Session

  /// Function to resolve a user by their identifier (e.g., email).
  final UserResolver<T> _userResolver;

  /// The ID of the panel this auth service is associated with.
  final String _panelId;

  AuthService({required UserResolver<T> userResolver, String panelId = 'default'})
    : _userResolver = userResolver,
      _panelId = panelId;

  /// Hashes a password using bcrypt.
  ///
  /// Bcrypt is a password hashing function designed to be computationally expensive,
  /// making it resistant to brute-force attacks. It automatically handles salting.
  ///
  /// [password] - The plain text password to hash
  /// [rounds] - The cost factor (default: 12). Higher values are more secure but slower.
  ///
  /// Returns the bcrypt hash string
  static String hashPassword(String password, {int rounds = 12}) {
    return BCrypt.hashpw(password, BCrypt.gensalt(logRounds: rounds));
  }

  /// Verifies a password against a bcrypt hash.
  ///
  /// [password] - The plain text password to verify
  /// [hash] - The bcrypt hash to check against
  ///
  /// Returns true if the password matches the hash, false otherwise
  static bool verifyPassword(String password, String hash) {
    try {
      return BCrypt.checkpw(password, hash);
    } catch (e) {
      // Invalid hash format or other error
      return false;
    }
  }

  /// Attempts to authenticate with identifier and password.
  ///
  /// Uses the [UserResolver] to look up the user by their identifier,
  /// then verifies the password using bcrypt.
  ///
  /// Returns a session token if successful, null otherwise.
  /// Sessions expire after 24 hours by default.
  ///
  /// Also checks if the user can access this panel via [Authenticatable.canAccessPanel].
  Future<String?> login(
    String identifier,
    String password, {
    Duration sessionDuration = const Duration(hours: 24),
  }) async {
    // Resolve user from data source
    final user = await _userResolver(identifier);
    if (user == null) {
      return null;
    }

    // Verify user implements Authenticatable
    if (user is! Authenticatable) {
      throw StateError('User model ${user.runtimeType} must implement Authenticatable mixin');
    }
    final authUser = user as Authenticatable;

    // Use bcrypt to verify password
    if (!verifyPassword(password, authUser.getAuthPassword())) {
      return null;
    }

    // Check panel access
    if (!authUser.canAccessPanel(_panelId)) {
      return null;
    }

    // Generate secure session token
    final sessionId = _generateSessionId();
    final session = Session<T>(
      id: sessionId,
      user: user,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(sessionDuration),
    );
    _sessions[sessionId] = session;

    return sessionId;
  }

  /// Logs out by removing the session.
  void logout(String sessionId) {
    _sessions.remove(sessionId);
  }

  /// Checks if a session is valid and not expired.
  ///
  /// Automatically removes expired sessions during the check.
  bool isAuthenticated(String? sessionId) {
    if (sessionId == null) {
      return false;
    }

    final session = _sessions[sessionId];
    if (session == null) {
      return false;
    }

    // Check if session has expired
    if (session.isExpired) {
      _sessions.remove(sessionId);
      return false;
    }

    return true;
  }

  /// Gets the user for a session.
  ///
  /// Returns null if the session is invalid or expired.
  T? getUser(String? sessionId) {
    if (sessionId == null) {
      return null;
    }

    final session = _sessions[sessionId];
    if (session == null || session.isExpired) {
      return null;
    }

    return session.user;
  }

  /// Refreshes the user data for a session from the database.
  ///
  /// Useful when user data may have changed since login.
  /// Returns the refreshed user, or null if session is invalid.
  Future<T?> refreshUser(String? sessionId) async {
    if (sessionId == null) {
      return null;
    }

    final session = _sessions[sessionId];
    if (session == null || session.isExpired) {
      return null;
    }

    // Re-fetch user from database
    final authUser = session.user as Authenticatable;
    final refreshedUser = await _userResolver(authUser.getAuthIdentifier());
    if (refreshedUser != null) {
      // Update session with fresh user data
      _sessions[sessionId] = Session<T>(
        id: session.id,
        user: refreshedUser,
        createdAt: session.createdAt,
        expiresAt: session.expiresAt,
      );
    }

    return refreshedUser;
  }

  /// Cleans up expired sessions.
  ///
  /// Should be called periodically to prevent memory leaks.
  void cleanupExpiredSessions() {
    _sessions.removeWhere((_, session) => session.isExpired);
  }

  /// Generates a cryptographically secure random session ID.
  ///
  /// Uses Dart's Random.secure() to generate a 32-byte random token,
  /// which is then base64url-encoded for safe use in HTTP headers/cookies.
  String _generateSessionId() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', ''); // Remove padding
  }
}

/// Represents an authenticated session.
///
/// Stores the authenticated user model along with session metadata.
class Session<T extends Model> {
  final String id;
  final T user;
  final DateTime createdAt;
  final DateTime expiresAt;

  const Session({required this.id, required this.user, required this.createdAt, required this.expiresAt});

  /// Checks if this session has expired.
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Gets the remaining time until expiration.
  Duration get timeRemaining => expiresAt.difference(DateTime.now());
}
