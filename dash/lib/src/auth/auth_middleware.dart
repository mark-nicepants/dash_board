import 'package:dash/src/auth/auth_service.dart';
import 'package:dash/src/auth/request_session.dart';
import 'package:dash/src/model/model.dart';
import 'package:shelf/shelf.dart';

/// Middleware to protect routes that require authentication.
///
/// Checks for a valid session cookie and redirects to login if not authenticated.
/// Initializes [RequestSession] with the authenticated user for downstream handlers.
Middleware authMiddleware(AuthService<Model> authService, {required String basePath}) {
  // Ensure RequestSession is registered
  RequestSession.register();

  final baseSegment = basePath.startsWith('/') ? basePath.substring(1) : basePath;
  return (Handler innerHandler) {
    return (Request request) async {
      // Skip auth for login page and login POST
      final path = request.url.path;
      if (path == '$baseSegment/login' || path.startsWith('$baseSegment/login')) {
        return innerHandler(request);
      }

      // Parse session ID from cookie
      final sessionId = RequestSession.parseSessionId(request);

      // Check if authenticated (loads from file if not in memory)
      if (!await authService.isAuthenticated(sessionId)) {
        // Redirect to login
        return Response.found('$basePath/login');
      }

      // Get the authenticated user and initialize RequestSession
      final user = await authService.getUser(sessionId);
      RequestSession.instance().initFromRequest(request, user: user);

      return innerHandler(request);
    };
  };
}
