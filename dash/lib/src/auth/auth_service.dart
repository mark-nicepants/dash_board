import 'dart:convert';
import 'dart:math';

import 'package:bcrypt/bcrypt.dart';
import 'package:dash_board/src/auth/authenticatable.dart';
import 'package:dash_board/src/auth/session_store.dart';
import 'package:dash_board/src/model/model.dart';

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
///   sessionStore: FileSessionStore('storage/sessions'),
/// );
///
/// final sessionId = await authService.login('admin@example.com', 'password');
/// ```
class AuthService<T extends Model> {
  final Map<String, Session<T>> _sessions = {}; // sessionId -> Session (in-memory cache)

  /// Function to resolve a user by their identifier (e.g., email).
  final UserResolver<T> _userResolver;

  /// The ID of the panel this auth service is associated with.
  final String _panelId;

  /// The session store for persisting sessions.
  final SessionStore _sessionStore;

  AuthService({required UserResolver<T> userResolver, String panelId = 'default', SessionStore? sessionStore})
    : _userResolver = userResolver,
      _panelId = panelId,
      _sessionStore = sessionStore ?? InMemorySessionStore();

  /// Loads a session from the persistent store into memory cache.
  ///
  /// Returns the session if found and valid, null otherwise.
  /// Automatically deletes expired sessions from the store.
  Future<Session<T>?> _loadSessionFromStore(String sessionId) async {
    final sessionData = await _sessionStore.load(sessionId);
    if (sessionData == null) {
      return null;
    }

    // Check if expired - delete from store if so
    if (sessionData.isExpired) {
      await _sessionStore.delete(sessionId);
      return null;
    }

    // Resolve the user from the stored identifier
    final user = await _userResolver(sessionData.userIdentifier);
    if (user == null) {
      // User no longer exists - remove session
      await _sessionStore.delete(sessionId);
      return null;
    }

    // Cache in memory
    final session = Session<T>(
      id: sessionData.id,
      user: user,
      createdAt: sessionData.createdAt,
      expiresAt: sessionData.expiresAt,
    );
    _sessions[sessionId] = session;

    return session;
  }

  /// Gets the session for a session ID.
  ///
  /// First checks the in-memory cache, then falls back to the persistent store.
  /// Returns null if the session is not found or expired.
  Future<Session<T>?> _getSession(String? sessionId) async {
    if (sessionId == null) {
      return null;
    }

    // Check in-memory cache first
    final session = _sessions[sessionId];
    if (session != null) {
      if (session.isExpired) {
        _sessions.remove(sessionId);
        await _sessionStore.delete(sessionId);
        return null;
      }
      return session;
    }

    // Fall back to persistent store
    return _loadSessionFromStore(sessionId);
  }

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
    final now = DateTime.now();
    final expiresAt = now.add(sessionDuration);

    final session = Session<T>(id: sessionId, user: user, createdAt: now, expiresAt: expiresAt);
    _sessions[sessionId] = session;

    // Persist session to store
    await _sessionStore.save(
      SessionData(id: sessionId, userIdentifier: authUser.getAuthIdentifier(), createdAt: now, expiresAt: expiresAt),
    );

    return sessionId;
  }

  /// Logs out by removing the session.
  Future<void> logout(String sessionId) async {
    _sessions.remove(sessionId);
    await _sessionStore.delete(sessionId);
  }

  /// Checks if a session is valid and not expired.
  ///
  /// Checks in-memory cache first, then falls back to persistent store.
  /// Automatically removes expired sessions during the check.
  Future<bool> isAuthenticated(String? sessionId) async {
    final session = await _getSession(sessionId);
    return session != null;
  }

  /// Gets the user for a session.
  ///
  /// Checks in-memory cache first, then falls back to persistent store.
  /// Returns null if the session is invalid or expired.
  Future<T?> getUser(String? sessionId) async {
    final session = await _getSession(sessionId);
    return session?.user;
  }

  /// Refreshes the user data for a session from the database.
  ///
  /// Useful when user data may have changed since login.
  /// Returns the refreshed user, or null if session is invalid.
  Future<T?> refreshUser(String? sessionId) async {
    final session = await _getSession(sessionId);
    if (session == null || sessionId == null) {
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
