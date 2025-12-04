import 'dart:async';
import 'dart:math';

import 'package:dash/src/model/model.dart';

/// Provides request-scoped context data via Dart zones.
///
/// This class solves the problem of sharing request-specific data (like
/// the authenticated user or session ID) across all code that runs during
/// a single HTTP request, without using shared mutable state that would
/// cause race conditions with concurrent requests.
///
/// ## The Problem
///
/// In a concurrent server environment, multiple requests may be processed
/// simultaneously. If we use a singleton to store request-specific data,
/// requests will overwrite each other's data:
///
/// ```
/// t1: Request A: sessionId = "A"
/// t2: Request A: await model.save()  // Yields to event loop
/// t3: Request B: sessionId = "B"     // OVERWRITES!
/// t4: Request A: resumes, sees sessionId = "B"  // WRONG!
/// ```
///
/// ## The Solution
///
/// Dart Zones provide a way to carry context through async operations.
/// Each request runs in its own zone with its own values, ensuring
/// complete isolation between concurrent requests.
///
/// ## Usage
///
/// In middleware, wrap the handler in a zone:
///
/// ```dart
/// return RequestContext.run(
///   sessionId: sessionId,
///   user: user,
///   () => innerHandler(request),
/// );
/// ```
///
/// Anywhere in the request (including deep in Model.save()):
///
/// ```dart
/// final sessionId = RequestContext.sessionId;
/// final user = RequestContext.user;
/// ```
///
/// ## Thread Safety
///
/// Zone values are immutable and scoped to their zone. Each async operation
/// maintains its zone association, ensuring that even after `await` calls,
/// the correct context is available.
class RequestContext {
  /// Zone key for the session ID.
  static const _sessionIdKey = #dash.requestContext.sessionId;

  /// Zone key for the authenticated user.
  static const _userKey = #dash.requestContext.user;

  /// Zone key for the request ID (for tracing/logging).
  static const _requestIdKey = #dash.requestContext.requestId;

  /// Random number generator for request ID generation.
  static final _random = Random();

  /// Private constructor - this class is not meant to be instantiated.
  RequestContext._();

  /// Runs [callback] within a zone that carries request context.
  ///
  /// This method wraps the callback in a Dart Zone with the provided
  /// context values. Any code running within this callback (including
  /// async operations) will have access to the context via the static
  /// getters on this class.
  ///
  /// Parameters:
  /// - [sessionId]: The session ID from the request cookie
  /// - [user]: The authenticated user model (if authenticated)
  /// - [callback]: The function to run within the context
  ///
  /// Returns: The result of the callback
  ///
  /// Example:
  /// ```dart
  /// final response = await RequestContext.run(
  ///   sessionId: 'abc123',
  ///   user: authenticatedUser,
  ///   () async {
  ///     // Any code here can access RequestContext.sessionId
  ///     await model.save(); // Model events will have correct sessionId
  ///     return Response.ok('Success');
  ///   },
  /// );
  /// ```
  static Future<T> run<T>({String? sessionId, Model? user, required Future<T> Function() callback}) {
    final requestId = _generateRequestId();

    return runZoned(callback, zoneValues: {_sessionIdKey: sessionId, _userKey: user, _requestIdKey: requestId});
  }

  /// Gets the current session ID, or null if not in a request context.
  ///
  /// This reads from the current zone's values, ensuring each concurrent
  /// request sees its own session ID.
  static String? get sessionId => Zone.current[_sessionIdKey] as String?;

  /// Gets the current authenticated user, or null if not authenticated.
  ///
  /// This reads from the current zone's values, ensuring each concurrent
  /// request sees its own user.
  static Model? get user => Zone.current[_userKey] as Model?;

  /// Gets the authenticated user cast to a specific type.
  ///
  /// Returns null if no user is authenticated or if the cast fails.
  static T? getUser<T extends Model>() {
    final u = user;
    if (u is T) return u;
    return null;
  }

  /// Gets the current request ID for tracing/logging.
  ///
  /// Each request gets a unique ID that can be used to correlate
  /// log entries and debug concurrent request issues.
  static String? get requestId => Zone.current[_requestIdKey] as String?;

  /// Whether we're currently within a request context.
  ///
  /// Returns true if code is running inside a [run] callback.
  /// Useful for conditional logic that should only run during requests.
  static bool get isInRequestContext => Zone.current[_requestIdKey] != null;

  /// Generates a unique request ID.
  ///
  /// Format: timestamp-random (e.g., "1701687245123456-4567")
  static String _generateRequestId() {
    return '${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(9999).toString().padLeft(4, '0')}';
  }
}
