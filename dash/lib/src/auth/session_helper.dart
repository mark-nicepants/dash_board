import 'package:shelf/shelf.dart';

/// Cookie name for the session ID.
const String _sessionCookieName = 'dash_session';

/// Helper class for managing request session data.
class SessionHelper {
  /// Parses the session ID from request cookies.
  ///
  /// Returns the session ID if found, null otherwise.
  static String? parseSessionId(Request request) {
    final cookies = request.headers['cookie'];
    if (cookies == null) return null;

    final cookieList = cookies.split(';');
    for (final cookie in cookieList) {
      final parts = cookie.trim().split('=');
      if (parts.length == 2 && parts[0] == _sessionCookieName) {
        return parts[1];
      }
    }
    return null;
  }

  /// Creates a Set-Cookie header value for the session.
  static String createSessionCookie(String sessionId) {
    return '$_sessionCookieName=$sessionId; Path=/; HttpOnly';
  }

  /// Creates a Set-Cookie header value to clear the session.
  static String clearSessionCookie() {
    return '$_sessionCookieName=; Path=/; HttpOnly; Max-Age=0';
  }
}
