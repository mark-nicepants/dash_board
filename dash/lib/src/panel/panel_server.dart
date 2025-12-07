import 'dart:async';
import 'dart:io';

import 'package:dash_board/dash_board.dart';
import 'package:dash_board/src/cli/cli_api_handler.dart';
import 'package:dash_board/src/panel/middleware/auth_middleware.dart';
import 'package:dash_board/src/panel/middleware/cli_api_middleware.dart';
import 'package:dash_board/src/panel/middleware/conditional_log_requests_middleware.dart';
import 'package:dash_board/src/panel/middleware/error_handling_middleware.dart';
import 'package:dash_board/src/panel/middleware/static_assets_middleware.dart';
import 'package:dash_board/src/panel/middleware/storage_assets_middleware.dart';
import 'package:dash_board/src/utils/resource_loader.dart';
import 'package:jaspr/server.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

/// Manages the HTTP server for the Dash panel.
///
/// Responsible for starting/stopping the server, setting up middleware,
/// and coordinating between the router and request handlers.
class PanelServer {
  final PanelConfig _config;
  final AuthService<Model> _authService;
  final ResourceLoader _resourceLoader;
  late final PanelRouter _router;
  late final RequestHandler _requestHandler;
  late final WireHandler _wireHandler;
  late final CliApiHandler _cliApiHandler;
  HttpServer? _server;

  /// Storage manager for file uploads.
  StorageManager? _storageManager;

  /// Whether to enable CLI API endpoints (/_cli/*).
  /// Defaults to true unless DASH_ENV is set to 'production'.
  bool enableCliApi = Platform.environment['DASH_ENV'] != 'production';

  PanelServer(this._config, this._authService, this._resourceLoader) {
    _router = PanelRouter(_config, _resourceLoader);
    _requestHandler = RequestHandler(_config, _authService);
    _wireHandler = WireHandler(basePath: _config.path);
    _cliApiHandler = CliApiHandler(_config);
  }

  /// Gets the CLI API handler for logging.
  CliApiHandler get cliApi => _cliApiHandler;

  /// Configures storage for file uploads.
  ///
  /// Example:
  /// ```dart
  /// server.configureStorage(StorageConfig(
  ///   defaultDisk: 'public',
  ///   disks: {
  ///     'local': LocalStorage(basePath: 'storage/app'),
  ///     'public': LocalStorage(basePath: 'storage/public', urlPrefix: '/storage'),
  ///   },
  /// ));
  /// ```
  void configureStorage(StorageConfig config) {
    _storageManager = config.createManager();
    _requestHandler.setStorageManager(_storageManager!);
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

    if (enableCliApi) {
      inject.registerSingleton(cliApi);
    }

    // Initialize Jaspr
    Jaspr.initializeApp();

    // Build the middleware stack
    final stack = _buildMiddlewareStack();
    final handler = stack.build(_handleRequest);

    // Start the server
    _server = await shelf_io.serve(handler, host, port);

    print('✓ Dash server started');
    print('  URL: http://$host:$port${_config.path}');
    print('  Login: http://$host:$port${_config.path}/login');
  }

  /// Builds the middleware stack with built-in and plugin middleware.
  ///
  /// Built-in middleware is registered at specific stages with default
  /// priority (400-600). Plugin middleware can be inserted before/after
  /// using lower/higher priority values.
  MiddlewareStack _buildMiddlewareStack() {
    final stack = MiddlewareStack();

    stack.addMiddleware(ErrorHandlingMiddleware());
    stack.addMiddleware(SecurityHeadersMiddleware());
    stack.addMiddleware(LogRequestsMiddleware());
    stack.addMiddleware(StaticAssetsMiddleware(_config, _resourceLoader));
    stack.addMiddleware(StorageAssetsMiddleware(_config, _storageManager));
    stack.addMiddleware(CliApiMiddleware(_config, _cliApiHandler, enableCliApi));
    stack.addMiddleware(AuthMiddleware(_authService, basePath: _config.path));

    // Add plugin-registered middleware
    for (final entry in _config.middlewareEntries) {
      stack.add(entry);
    }

    return stack;
  }

  /// Main request handler that coordinates between custom and routed requests.
  Future<Response> _handleRequest(Request request) async {
    // Fire request callbacks (for analytics, logging, etc.)
    await _config.fireRequestCallbacks(request);

    // Handle wire requests (interactive component actions)
    if (_wireHandler.isWireRequest(request)) {
      return await _wireHandler.handle(request);
    }

    // Try custom handler (login, logout, etc.)
    final customResponse = await _requestHandler.handle(request);
    if (customResponse.statusCode != 404) {
      return customResponse;
    }

    // Fall back to router for page rendering
    return await _router.route(request);
  }
}
