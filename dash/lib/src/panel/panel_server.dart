import 'dart:async';
import 'dart:io';

import 'package:dash/dash.dart';
import 'package:dash/src/auth/auth_middleware.dart';
import 'package:dash/src/cli/cli_api_handler.dart';
import 'package:dash/src/cli/cli_logger.dart';
import 'package:dash/src/utils/resource_loader.dart';
import 'package:jaspr/server.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';

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

    // Build request pipeline
    // Static assets are served BEFORE auth middleware to avoid redirects
    // CLI API is also served before auth for CLI tool access
    final pipeline = const Pipeline()
        .addMiddleware(_conditionalLogRequests())
        .addMiddleware(_staticAssetsMiddleware())
        .addMiddleware(_storageAssetsMiddleware())
        .addMiddleware(_cliApiMiddleware())
        .addMiddleware(authMiddleware(_authService, basePath: _config.path))
        .addHandler(_handleRequest);

    // Start the server
    _server = await shelf_io.serve(pipeline, host, port);

    print('✓ Dash server started');
    print('  URL: http://$host:$port${_config.path}');
    print('  Login: http://$host:$port${_config.path}/login');
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

  /// Middleware that handles CLI API requests before auth.
  ///
  /// This allows the CLI tool to access server status and logs
  /// without authentication.
  Middleware _cliApiMiddleware() {
    final basePath = _config.path.replaceFirst('/', '');
    final cliPrefix = '$basePath/_cli/';

    return (Handler innerHandler) {
      return (Request request) async {
        final path = request.url.path;

        // Handle CLI API request
        if (path.startsWith(cliPrefix) && enableCliApi) {
          final cliResponse = await _cliApiHandler.handle(request);
          if (cliResponse != null) {
            return cliResponse;
          }
        }

        return innerHandler(request);
      };
    };
  }

  /// Middleware that serves static assets (CSS, JS, images) before auth.
  ///
  /// Assets are served from:
  /// - /admin/assets/css/* -> resources/dist/css/*
  /// - /admin/assets/js/*  -> resources/dist/js/*
  /// - /admin/assets/img/* -> resources/img/*
  ///
  /// Uses shelf_static for efficient file serving with proper MIME types,
  /// ETags, and range request support.
  Middleware _staticAssetsMiddleware() {
    final basePath = _config.path.replaceFirst('/', '');
    final assetsPrefix = '$basePath/assets/';

    // Create static handlers for each directory
    final distHandler = createStaticHandler(_resourceLoader.distDir, defaultDocument: null);

    final imagesHandler = createStaticHandler(_resourceLoader.imagesDir, defaultDocument: null);

    return (Handler innerHandler) {
      return (Request request) async {
        final path = request.url.path;

        // Not an asset request, continue to next handler
        if (!path.startsWith(assetsPrefix)) {
          return innerHandler(request);
        }

        final assetPath = path.substring(assetsPrefix.length);

        // Route to appropriate handler based on path prefix
        if (assetPath.startsWith('css/') || assetPath.startsWith('js/')) {
          // CSS/JS files from dist/
          final response = await distHandler(
            Request(request.method, request.requestedUri.replace(path: '/$assetPath')),
          );
          if (response.statusCode != 404) {
            return _addCacheHeaders(response);
          }
        } else if (assetPath.startsWith('img/')) {
          // Image files from img/
          final subPath = assetPath.substring(4); // Remove 'img/' prefix
          final response = await imagesHandler(
            Request(request.method, request.requestedUri.replace(path: '/$subPath')),
          );
          if (response.statusCode != 404) {
            return _addCacheHeaders(response);
          }
        }

        // Asset not found or unknown type
        return Response.notFound('Asset not found: $assetPath');
      };
    };
  }

  /// Adds cache control headers to static asset responses.
  Response _addCacheHeaders(Response response) {
    final cacheControl = _resourceLoader.isProduction
        ? 'public, max-age=31536000' // 1 year for production
        : 'no-cache'; // No cache for development

    return response.change(headers: {'cache-control': cacheControl});
  }

  /// Creates middleware to serve files from storage.
  ///
  /// Handles requests to /storage/* and serves files from the configured
  /// storage disks.
  Middleware _storageAssetsMiddleware() {
    final basePath = _config.path.replaceFirst('/', '');
    final storagePrefix = '$basePath/storage/';

    return (Handler innerHandler) {
      return (Request request) async {
        final path = request.url.path;

        // Not a storage request, continue to next handler
        if (!path.startsWith(storagePrefix)) {
          return innerHandler(request);
        }

        // No storage manager configured
        if (_storageManager == null) {
          return Response.notFound('Storage not configured');
        }

        // Extract the file path from the URL
        // Format: /admin/storage/{disk}/{path...}
        final storagePath = path.substring(storagePrefix.length);
        final segments = storagePath.split('/');

        if (segments.isEmpty) {
          return Response.notFound('Invalid storage path');
        }

        // First segment is the disk name, rest is the file path
        final diskName = segments.first;
        final filePath = segments.skip(1).join('/');

        if (filePath.isEmpty) {
          return Response.notFound('No file specified');
        }

        try {
          final storage = _storageManager!.disk(diskName);

          // Check if file exists
          if (!await storage.exists(filePath)) {
            return Response.notFound('File not found: $filePath');
          }

          // Read file data
          final data = await storage.get(filePath);
          if (data == null) {
            return Response.notFound('Could not read file: $filePath');
          }

          // Get MIME type
          final mimeType = await storage.mimeType(filePath) ?? 'application/octet-stream';

          return Response.ok(data, headers: {'content-type': mimeType, 'cache-control': 'public, max-age=31536000'});
        } on StateError catch (e) {
          cliLogException(e);
          return Response.notFound('Storage error: ${e.message}');
        }
      };
    };
  }

  /// Creates a middleware that logs requests except for CLI API requests.
  Middleware _conditionalLogRequests() {
    return (Handler innerHandler) {
      return (Request request) async {
        if (request.url.path.contains('_cli/')) {
          // Skip logging for CLI API requests to avoid clutter
          return await innerHandler(request);
        }

        final startTime = DateTime.now();
        final response = await innerHandler(request);

        final duration = DateTime.now().difference(startTime);
        final method = request.method.padRight(7);
        final statusCode = response.statusCode;

        cliLogRequest(method: method, path: request.requestedUri.path, statusCode: statusCode, duration: duration);

        return response;
      };
    };
  }
}
