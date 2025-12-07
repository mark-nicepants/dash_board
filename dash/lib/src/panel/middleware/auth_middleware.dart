import 'package:dash_board/src/auth/auth_service.dart';
import 'package:dash_board/src/auth/session_helper.dart';
import 'package:dash_board/src/context/request_context.dart';
import 'package:dash_board/src/model/model.dart';
import 'package:dash_board/src/panel/middleware_stack.dart';
import 'package:shelf/shelf.dart' hide Middleware;

/// Middleware to protect routes that require authentication.
///
/// Checks for a valid session cookie and redirects to login if not authenticated.
/// Runs all downstream handlers within a [RequestContext] zone to provide
/// request-scoped access to session and user data.
///
/// ## Request Isolation
///
/// Each request runs in its own Dart Zone with isolated context values.
/// This ensures that concurrent requests cannot interfere with each other's
/// session or user data - a critical security feature.
///
/// ## Accessing Context
///
/// Downstream code can access the context anywhere:
/// ```dart
/// final sessionId = RequestContext.sessionId;
/// final user = RequestContext.user;
/// ```
class AuthMiddleware implements Middleware {
  final AuthService<Model> authService;
  final String basePath;

  AuthMiddleware(this.authService, {required this.basePath});

  @override
  Handler call(Handler innerHandler) {
    final baseSegment = basePath.startsWith('/') ? basePath.substring(1) : basePath;

    return (Request request) async {
      // Skip auth for login page and login POST
      final path = request.url.path;
      if (path == '$baseSegment/login' || path.startsWith('$baseSegment/login')) {
        return innerHandler(request);
      }

      // Parse session ID from cookie
      final sessionId = SessionHelper.parseSessionId(request);

      // Check if authenticated (loads from file if not in memory)
      if (!await authService.isAuthenticated(sessionId)) {
        // Redirect to login
        return Response.found('$basePath/login');
      }

      // Get the authenticated user
      final user = await authService.getUser(sessionId);

      // Run the rest of the request within a zone that carries the context
      // This ensures sessionId and user are available throughout the request
      // via RequestContext.sessionId and RequestContext.user, even through
      // async operations and deep call stacks.
      return RequestContext.run(sessionId: sessionId, user: user, callback: () async => innerHandler(request));
    };
  }

  @override
  MiddlewareEntry toEntry() {
    return MiddlewareEntry.make(stage: MiddlewareStage.auth, middleware: this, id: 'auth');
  }
}
