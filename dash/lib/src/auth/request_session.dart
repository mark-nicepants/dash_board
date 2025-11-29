import 'package:dash/src/auth/authenticatable.dart';
import 'package:dash/src/model/model.dart';
import 'package:dash/src/service_locator.dart';
import 'package:shelf/shelf.dart';

/// Cookie name for the session ID.
const String _sessionCookieName = 'dash_session';

/// Helper class for managing request session data.
///
/// Provides a centralized way to get/set session data from HTTP requests,
/// including parsing session cookies and storing the authenticated user.
///
/// Usage:
/// ```dart
/// // In AuthService or Panel boot
/// RequestSession.register();
///
/// // In middleware or handlers
/// final session = RequestSession.instance();
/// session.initFromRequest(request);
///
/// // Anywhere in the app
/// final user = RequestSession.instance().user;
/// ```
class RequestSession {
  /// The current session ID from the cookie.
  String? _sessionId;

  /// The authenticated user for this request.
  Model? _user;

  RequestSession._();

  /// Registers a singleton instance in the service locator.
  ///
  /// Should be called during panel initialization.
  static void register() {
    if (!inject.isRegistered<RequestSession>()) {
      inject.registerLazySingleton<RequestSession>(RequestSession._);
    }
  }

  /// Gets the singleton instance from the service locator.
  static RequestSession instance() {
    if (!inject.isRegistered<RequestSession>()) {
      register();
    }
    return inject<RequestSession>();
  }

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

  /// Initializes the session from a request.
  ///
  /// Parses the session cookie and optionally sets the authenticated user.
  void initFromRequest(Request request, {Model? user}) {
    _sessionId = parseSessionId(request);
    _user = user;
  }

  /// Sets the authenticated user for this session.
  void setUser(Model? user) {
    _user = user;
  }

  /// Gets the current session ID.
  String? get sessionId => _sessionId;

  /// Gets the authenticated user.
  Model? get user => _user;

  /// Gets the authenticated user cast to a specific type.
  T? getUser<T extends Model>() => _user as T?;

  /// Gets the user as Authenticatable (for display name, etc).
  Authenticatable? get authenticatable => _user is Authenticatable ? _user as Authenticatable : null;

  /// Checks if there is an authenticated user.
  bool get isAuthenticated => _user != null;

  /// Gets the user's display name, or a fallback.
  String? get userName => authenticatable?.getDisplayName();

  /// Gets the user's avatar URL if available.
  ///
  /// Tries to get the 'avatar' field from the user model's map representation.
  String? get userAvatarUrl {
    if (_user == null) return null;
    try {
      final userMap = (_user as dynamic).toMap();
      return userMap['avatar'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Clears the session data.
  void clear() {
    _sessionId = null;
    _user = null;
  }
}
