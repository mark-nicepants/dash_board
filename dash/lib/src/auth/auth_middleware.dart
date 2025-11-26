import 'package:dash/src/auth/auth_service.dart';
import 'package:shelf/shelf.dart';

/// Middleware to protect routes that require authentication.
///
/// Checks for a valid session cookie and redirects to login if not authenticated.
Middleware authMiddleware(AuthService authService, {required String basePath}) {
  final baseSegment = basePath.startsWith('/') ? basePath.substring(1) : basePath;
  return (Handler innerHandler) {
    return (Request request) async {
      // Skip auth for login page and login POST
      final path = request.url.path;
      if (path == '$baseSegment/login' || path.startsWith('$baseSegment/login')) {
        return innerHandler(request);
      }

      // Check for session cookie
      final cookies = request.headers['cookie'];
      String? sessionId;

      if (cookies != null) {
        final cookieList = cookies.split(';');
        for (final cookie in cookieList) {
          final parts = cookie.trim().split('=');
          if (parts.length == 2 && parts[0] == 'dash_session') {
            sessionId = parts[1];
            break;
          }
        }
      }

      // Check if authenticated
      if (!authService.isAuthenticated(sessionId)) {
        // Redirect to login
        return Response.found('$basePath/login');
      }

      // Add user to request context
      final user = authService.getUser(sessionId);
      final updatedRequest = request.change(context: {'user': user, 'sessionId': sessionId});

      return innerHandler(updatedRequest);
    };
  };
}
