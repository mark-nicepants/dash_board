import 'dart:convert';
import 'dart:math';

import 'package:bcrypt/bcrypt.dart';

/// Authentication service for the Dash admin panel.
///
/// Handles user authentication, session management, and password verification.
/// Uses bcrypt for secure password hashing and cryptographically secure random
/// tokens for session management.
class AuthService {
  final Map<String, DashUser> _users = {};
  final Map<String, Session> _sessions = {}; // sessionId -> Session

  AuthService() {
    // Add default admin user for development
    addUser(
      DashUser(email: 'admin@example.com', passwordHash: hashPassword('password'), name: 'Admin User', role: 'admin'),
    );
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

  /// Add a user to the authentication system
  void addUser(DashUser user) {
    _users[user.email] = user;
  }

  /// Attempts to authenticate with email and password.
  ///
  /// Returns a session token if successful, null otherwise.
  /// Sessions expire after 24 hours by default.
  String? login(String email, String password, {Duration sessionDuration = const Duration(hours: 24)}) {
    final user = _users[email];
    if (user == null) {
      return null;
    }

    // Use bcrypt to verify password
    if (!verifyPassword(password, user.passwordHash)) {
      return null;
    }

    // Generate secure session token
    final sessionId = _generateSessionId();
    final session = Session(
      id: sessionId,
      email: email,
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
  DashUser? getUser(String? sessionId) {
    if (sessionId == null) {
      return null;
    }

    final session = _sessions[sessionId];
    if (session == null || session.isExpired) {
      return null;
    }

    return _users[session.email];
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
class Session {
  final String id;
  final String email;
  final DateTime createdAt;
  final DateTime expiresAt;

  const Session({required this.id, required this.email, required this.createdAt, required this.expiresAt});

  /// Checks if this session has expired.
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Gets the remaining time until expiration.
  Duration get timeRemaining => expiresAt.difference(DateTime.now());
}

/// User model for authentication
class DashUser {
  final String email;
  final String passwordHash;
  final String name;
  final String role;

  const DashUser({required this.email, required this.passwordHash, required this.name, required this.role});
}
