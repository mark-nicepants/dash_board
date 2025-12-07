import 'dart:io';

import 'package:dash_board/src/panel/middleware_stack.dart';
import 'package:shelf/shelf.dart' hide Middleware;

/// Middleware that adds security headers to all responses.
///
/// This middleware implements OWASP recommended security headers:
///
/// - **X-Content-Type-Options**: Prevents MIME type sniffing
/// - **X-Frame-Options**: Prevents clickjacking attacks
/// - **X-XSS-Protection**: Enables browser's XSS filter (legacy)
/// - **Referrer-Policy**: Controls referrer information in requests
/// - **Content-Security-Policy**: Controls resource loading (configurable)
/// - **Strict-Transport-Security**: Enforces HTTPS (production only)
/// - **Permissions-Policy**: Controls browser features
///
/// References:
/// - https://owasp.org/www-project-secure-headers/
/// - https://cheatsheetseries.owasp.org/cheatsheets/HTTP_Headers_Cheat_Sheet.html
///
/// Example usage:
/// ```dart
/// final pipeline = Pipeline()
///   .addMiddleware(SecurityHeadersMiddleware().call)
///   .addHandler(myHandler);
/// ```
class SecurityHeadersMiddleware implements Middleware {
  final SecurityHeadersConfig config;

  SecurityHeadersMiddleware({SecurityHeadersConfig? config}) : config = config ?? SecurityHeadersConfig();

  @override
  Handler call(Handler innerHandler) {
    return (Request request) async {
      final response = await innerHandler(request);

      // Build headers map
      final securityHeaders = <String, String>{
        // Prevent MIME type sniffing
        'X-Content-Type-Options': 'nosniff',

        // Prevent clickjacking - deny all framing
        'X-Frame-Options': config.frameOptions,

        // Enable browser XSS filter (legacy but still useful)
        'X-XSS-Protection': '1; mode=block',

        // Control referrer information
        'Referrer-Policy': config.referrerPolicy,

        // Control browser features/permissions
        'Permissions-Policy': config.permissionsPolicy,
      };

      // Add Content-Security-Policy if configured and not already set
      if (config.contentSecurityPolicy != null && !response.headers.containsKey('Content-Security-Policy')) {
        securityHeaders['Content-Security-Policy'] = config.contentSecurityPolicy!;
      }

      // Add HSTS header in production (HTTPS enforcement)
      if (_isProduction && config.enableHsts) {
        securityHeaders['Strict-Transport-Security'] = 'max-age=${config.hstsMaxAge}; includeSubDomains';
      }

      // Merge with existing response headers
      return response.change(headers: {...response.headers, ...securityHeaders});
    };
  }

  @override
  MiddlewareEntry toEntry() {
    return MiddlewareEntry.make(stage: MiddlewareStage.security, middleware: this, id: 'security-headers');
  }
}

/// Configuration for security headers middleware.
///
/// Provides sensible defaults that can be customized per application needs.
class SecurityHeadersConfig {
  /// X-Frame-Options value.
  ///
  /// Options:
  /// - 'DENY': Prevents any framing (most secure)
  /// - 'SAMEORIGIN': Allows framing from same origin only
  ///
  /// Default: 'DENY'
  final String frameOptions;

  /// Referrer-Policy value.
  ///
  /// Controls how much referrer information is sent with requests.
  ///
  /// Default: 'strict-origin-when-cross-origin'
  final String referrerPolicy;

  /// Content-Security-Policy directive.
  ///
  /// Controls which resources can be loaded. Set to null to disable.
  ///
  /// Default: A policy that allows self-hosted resources and inline styles/scripts
  /// for Alpine.js compatibility.
  final String? contentSecurityPolicy;

  /// Permissions-Policy (formerly Feature-Policy).
  ///
  /// Controls which browser features are available.
  ///
  /// Default: Disables geolocation, microphone, and camera.
  final String permissionsPolicy;

  /// Whether to enable HSTS (HTTP Strict Transport Security).
  ///
  /// Only applied when running in production mode.
  ///
  /// Default: true
  final bool enableHsts;

  /// HSTS max-age in seconds.
  ///
  /// Default: 31536000 (1 year)
  final int hstsMaxAge;

  SecurityHeadersConfig({
    this.frameOptions = 'DENY',
    this.referrerPolicy = 'strict-origin-when-cross-origin',
    this.contentSecurityPolicy = _defaultCsp,
    this.permissionsPolicy = 'geolocation=(), microphone=(), camera=()',
    this.enableHsts = true,
    this.hstsMaxAge = 31536000,
  });

  /// Default Content-Security-Policy.
  ///
  /// This policy:
  /// - Allows resources from same origin ('self')
  /// - Allows inline scripts and styles (required for Alpine.js and Tailwind)
  /// - Allows cdn.tailwindcss.com for Tailwind CDN (development)
  /// - Allows data: URIs for images (for inline SVGs and base64 images)
  /// - Blocks all object/embed elements
  /// - Restricts form actions to same origin
  /// - Restricts base URI to same origin
  static const _defaultCsp =
      "default-src 'self'; "
      "script-src 'self' 'unsafe-inline' 'unsafe-eval' https://cdn.tailwindcss.com; "
      "style-src 'self' 'unsafe-inline'; "
      "img-src 'self' data: blob:; "
      "font-src 'self' data:; "
      "connect-src 'self'; "
      "object-src 'none'; "
      "base-uri 'self'; "
      "form-action 'self'; "
      "frame-ancestors 'none'";
}

/// Whether the application is running in production mode.
bool get _isProduction => Platform.environment['DASH_ENV'] == 'production';
