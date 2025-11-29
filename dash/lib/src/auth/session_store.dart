import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Session data transfer object for serialization.
///
/// Contains all the data needed to persist and restore a session.
class SessionData {
  final String id;
  final String userIdentifier;
  final DateTime createdAt;
  final DateTime expiresAt;

  const SessionData({required this.id, required this.userIdentifier, required this.createdAt, required this.expiresAt});

  /// Checks if this session has expired.
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Creates a SessionData from JSON map.
  factory SessionData.fromJson(Map<String, dynamic> json) {
    return SessionData(
      id: json['id'] as String,
      userIdentifier: json['userIdentifier'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }

  /// Converts this session to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userIdentifier': userIdentifier,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
    };
  }
}

/// Abstract interface for session persistence.
///
/// Implementations can store sessions in different backends
/// (files, database, Redis, etc.).
abstract class SessionStore {
  /// Saves a session.
  Future<void> save(SessionData session);

  /// Loads a session by ID.
  ///
  /// Returns null if the session doesn't exist.
  Future<SessionData?> load(String sessionId);

  /// Deletes a session by ID.
  Future<void> delete(String sessionId);

  /// Loads all sessions.
  ///
  /// Used during startup to restore sessions.
  Future<List<SessionData>> loadAll();

  /// Deletes all expired sessions.
  Future<void> cleanupExpired();
}

/// In-memory session store for testing.
///
/// Sessions are lost when the application restarts.
class InMemorySessionStore extends SessionStore {
  final Map<String, SessionData> _sessions = {};

  @override
  Future<void> save(SessionData session) async {
    _sessions[session.id] = session;
  }

  @override
  Future<SessionData?> load(String sessionId) async {
    return _sessions[sessionId];
  }

  @override
  Future<void> delete(String sessionId) async {
    _sessions.remove(sessionId);
  }

  @override
  Future<List<SessionData>> loadAll() async {
    return _sessions.values.toList();
  }

  @override
  Future<void> cleanupExpired() async {
    _sessions.removeWhere((_, session) => session.isExpired);
  }
}

/// File-based session store.
///
/// Stores each session as a separate JSON file in the specified directory.
/// This allows sessions to persist across server restarts.
///
/// Example:
/// ```dart
/// final store = FileSessionStore('storage/sessions');
/// await store.save(sessionData);
/// ```
class FileSessionStore extends SessionStore {
  /// The directory where session files are stored.
  final String basePath;

  FileSessionStore(this.basePath);

  /// Factory method for creating a FileSessionStore.
  static FileSessionStore make(String basePath) => FileSessionStore(basePath);

  /// Gets the file path for a session ID.
  String _sessionFilePath(String sessionId) {
    // Sanitize session ID to prevent directory traversal
    final safeId = sessionId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return p.join(basePath, '$safeId.json');
  }

  /// Ensures the sessions directory exists.
  Future<void> _ensureDirectory() async {
    final dir = Directory(basePath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  @override
  Future<void> save(SessionData session) async {
    await _ensureDirectory();
    final file = File(_sessionFilePath(session.id));
    final json = jsonEncode(session.toJson());
    await file.writeAsString(json);
  }

  @override
  Future<SessionData?> load(String sessionId) async {
    final file = File(_sessionFilePath(sessionId));
    if (!await file.exists()) {
      return null;
    }

    try {
      final json = await file.readAsString();
      final data = jsonDecode(json) as Map<String, dynamic>;
      return SessionData.fromJson(data);
    } catch (e) {
      // Invalid JSON or corrupted file - remove it
      await file.delete();
      return null;
    }
  }

  @override
  Future<void> delete(String sessionId) async {
    final file = File(_sessionFilePath(sessionId));
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<List<SessionData>> loadAll() async {
    await _ensureDirectory();
    final dir = Directory(basePath);
    final sessions = <SessionData>[];

    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        try {
          final json = await entity.readAsString();
          final data = jsonDecode(json) as Map<String, dynamic>;
          sessions.add(SessionData.fromJson(data));
        } catch (e) {
          // Invalid JSON - delete corrupted file
          await entity.delete();
        }
      }
    }

    return sessions;
  }

  @override
  Future<void> cleanupExpired() async {
    final sessions = await loadAll();
    for (final session in sessions) {
      if (session.isExpired) {
        await delete(session.id);
      }
    }
  }
}
