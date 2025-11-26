import 'dart:async';
import 'dart:io';

import 'package:dash/src/auth/auth_middleware.dart';
import 'package:dash/src/auth/auth_service.dart';
import 'package:dash/src/panel/panel_config.dart';
import 'package:dash/src/panel/panel_router.dart';
import 'package:dash/src/panel/request_handler.dart';
import 'package:dash/src/resources/resource_loader.dart';
import 'package:jaspr/server.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

/// Manages the HTTP server for the Dash panel.
///
/// Responsible for starting/stopping the server, setting up middleware,
/// and coordinating between the router and request handlers.
class PanelServer {
  final PanelConfig _config;
  final AuthService _authService;
  final ResourceLoader _resourceLoader;
  late final PanelRouter _router;
  late final RequestHandler _requestHandler;
  HttpServer? _server;

  PanelServer(this._config, this._authService, this._resourceLoader) {
    _router = PanelRouter(_config, _resourceLoader);
    _requestHandler = RequestHandler(_config, _authService);
  }

  /// Whether the server is currently running.
  bool get isRunning => _server != null;

  /// Starts the HTTP server.
  ///
  /// [host] - The host to bind to (default: 'localhost')
  /// [port] - The port to listen on (default: 8080)
  Future<void> start({String host = 'localhost', int port = 8080}) async {
    if (_server != null) {
      throw StateError('Server is already running');
    }

    // Initialize Jaspr
    Jaspr.initializeApp();

    // Build request pipeline
    final pipeline = const Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware(authMiddleware(_authService, basePath: _config.path))
        .addHandler(_handleRequest);

    // Start the server
    _server = await shelf_io.serve(pipeline, host, port);

    print('✓ Dash server started');
    print('  URL: http://$host:$port${_config.path}');
    print('  Login: http://$host:$port${_config.path}/login');
  }

  /// Stops the HTTP server.
  Future<void> stop({bool force = false}) async {
    if (_server == null) {
      return;
    }

    await _server!.close(force: force);
    _server = null;
    print('✓ Dash server stopped');
  }

  /// Main request handler that coordinates between custom and routed requests.
  Future<Response> _handleRequest(Request request) async {
    // Try custom handler first (login, logout, etc.)
    final customResponse = await _requestHandler.handle(request);
    if (customResponse.statusCode != 404) {
      return customResponse;
    }

    // Fall back to router for page rendering
    return await _router.route(request);
  }
}
