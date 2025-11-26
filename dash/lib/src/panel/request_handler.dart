import 'dart:async';

import 'package:dash/src/auth/auth_service.dart';
import 'package:dash/src/panel/panel_config.dart';
import 'package:shelf/shelf.dart';

/// Handles specific HTTP requests for authentication and special routes.
///
/// Processes login, logout, and other custom request types that require
/// special handling beyond basic page rendering.
class RequestHandler {
  final PanelConfig _config;
  final AuthService _authService;

  RequestHandler(this._config, this._authService);

  /// Handles custom requests (login POST, logout, etc.).
  ///
  /// Returns a Response if the request is handled, or a 404 if not.
  FutureOr<Response> handle(Request request) async {
    final path = request.url.path;
    final baseSegment = _config.path.startsWith('/') ? _config.path.substring(1) : _config.path;

    // Handle login POST
    if (path == '$baseSegment/login' && request.method == 'POST') {
      return await _handleLogin(request);
    }

    // Handle logout
    if (path == '$baseSegment/logout') {
      return _handleLogout(request);
    }

    return Response.notFound('Not found');
  }

  /// Handles login POST request.
  Future<Response> _handleLogin(Request request) async {
    final body = await request.readAsString();

    // Parse form data
    final params = Uri.splitQueryString(body);
    final email = params['email'];
    final password = params['password'];

    if (email == null || password == null) {
      return Response.found('${_config.path}/login?error=missing_credentials');
    }

    // Attempt login
    final sessionId = _authService.login(email, password);
    if (sessionId == null) {
      return Response.found('${_config.path}/login?error=invalid_credentials');
    }

    // Set session cookie and redirect to dashboard
    return Response.found(_config.path, headers: {'set-cookie': 'dash_session=$sessionId; Path=/; HttpOnly'});
  }

  /// Handles logout request.
  Response _handleLogout(Request request) {
    // Get session from cookie
    final cookies = request.headers['cookie'];
    if (cookies != null) {
      final cookieList = cookies.split(';');
      for (final cookie in cookieList) {
        final parts = cookie.trim().split('=');
        if (parts.length == 2 && parts[0] == 'dash_session') {
          _authService.logout(parts[1]);
          break;
        }
      }
    }

    // Clear cookie and redirect to login
    return Response.found(
      '${_config.path}/login',
      headers: {'set-cookie': 'dash_session=; Path=/; HttpOnly; Max-Age=0'},
    );
  }
}
