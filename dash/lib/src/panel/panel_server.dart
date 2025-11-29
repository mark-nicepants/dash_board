import 'dart:async';
import 'dart:io';

import 'package:dash/src/auth/auth_middleware.dart';
import 'package:dash/src/auth/auth_service.dart';
import 'package:dash/src/interactive/wire_handler.dart';
import 'package:dash/src/model/model.dart';
import 'package:dash/src/panel/dev_console.dart';
import 'package:dash/src/panel/panel_config.dart';
import 'package:dash/src/panel/panel_router.dart';
import 'package:dash/src/panel/request_handler.dart';
import 'package:dash/src/storage/storage.dart';
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
  HttpServer? _server;
  DevConsole? _devConsole;

  /// Storage manager for file uploads.
  StorageManager? _storageManager;

  /// Whether to enable interactive dev console mode.
  /// Defaults to true unless DASH_ENV is set to 'production'.
  bool enableDevConsole = Platform.environment['DASH_ENV'] != 'production';

  /// Whether HTTP request logging is enabled.
  bool httpLoggingEnabled = Platform.environment['DASH_ENV'] == 'production';

  PanelServer(this._config, this._authService, this._resourceLoader) {
    _router = PanelRouter(_config, _resourceLoader);
    _requestHandler = RequestHandler(_config, _authService);
    _wireHandler = WireHandler(basePath: _config.path);
  }

  /// Configures storage for file uploads.
  ///
  /// Example:
  /// ```dart
  /// server.configureStorage(StorageConfig()
  ///   ..defaultDisk = 'public'
  ///   ..disks = {
  ///     'local': LocalStorage(basePath: 'storage/app'),
  ///     'public': LocalStorage(basePath: 'storage/public', urlPrefix: '/storage'),
  ///   });
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

    // Initialize Jaspr
    Jaspr.initializeApp();

    // Build request pipeline
    // Static assets are served BEFORE auth middleware to avoid redirects
    final pipeline = const Pipeline()
        .addMiddleware(_conditionalLogRequests())
        .addMiddleware(_staticAssetsMiddleware())
        .addMiddleware(_storageAssetsMiddleware())
        .addMiddleware(authMiddleware(_authService, basePath: _config.path))
        .addHandler(_handleRequest);

    // Start the server
    _server = await shelf_io.serve(pipeline, host, port);

    print('✓ Dash server started');
    print('  URL: http://$host:$port${_config.path}');
    print('  Login: http://$host:$port${_config.path}/login');

    // Start interactive dev console
    if (enableDevConsole) {
      await _startDevConsole();
    }
  }

  /// Starts the interactive development console.
  Future<void> _startDevConsole() async {
    _devConsole = DevConsole();

    // Configure callbacks
    _devConsole!.onStop = () async {
      await stop();
    };

    final basePath = _config.path;

    // Set up route printer with actual routes
    _devConsole!.setRoutePrinter(() {
      print('');
      print('🛤️  Registered Routes:');
      print('');
      print('  GET    $basePath                  Dashboard');
      print('  GET    $basePath/login            Login page');
      print('  POST   $basePath/login            Login action');
      print('  POST   $basePath/logout           Logout action');
      print('');
      if (_config.resources.isNotEmpty) {
        print('  Resource Routes:');
        for (final resource in _config.resources) {
          final slug = resource.slug;
          print('');
          print('  ${resource.singularLabel}:');
          print('    GET    $basePath/$slug              List');
          print('    GET    $basePath/$slug/create       Create form');
          print('    POST   $basePath/$slug              Create action');
          print('    GET    $basePath/$slug/{id}         Edit form');
          print('    POST   $basePath/$slug/{id}         Update action');
          print('    DELETE $basePath/$slug/{id}         Delete action');
        }
      }
      print('');
    });

    // Set up resource printer with actual resources
    _devConsole!.setResourcePrinter(() {
      print('');
      print('📦 Registered Resources:');
      print('');
      if (_config.resources.isEmpty) {
        print('   (No resources registered)');
      } else {
        for (final resource in _config.resources) {
          final modelName = resource.singularLabel;
          final resourceSlug = resource.slug;
          print('   • $modelName → /${_config.path.replaceFirst('/', '')}/$resourceSlug');
        }
      }
      print('');
    });

    // Register custom commands
    _devConsole!.registerCommand(
      DevCommand(
        name: 'url',
        description: 'Print the server URL',
        handler: (_) async {
          final addr = _server?.address;
          final port = _server?.port;
          if (addr != null && port != null) {
            print('\n🌐 Server URL: http://${addr.host}:$port${_config.path}\n');
          }
        },
      ),
    );

    _devConsole!.registerCommand(
      DevCommand(
        name: 'open',
        shortName: 'o',
        description: 'Open server URL in browser',
        handler: (_) async {
          final addr = _server?.address;
          final port = _server?.port;
          if (addr != null && port != null) {
            final url = 'http://${addr.host}:$port${_config.path}';
            print('\n🌐 Opening $url in browser...\n');
            await _openInBrowser(url);
          }
        },
      ),
    );

    _devConsole!.registerCommand(
      DevCommand(
        name: 'status',
        description: 'Show server status',
        handler: (_) async {
          final addr = _server?.address;
          final port = _server?.port;
          print('');
          print('📊 Server Status:');
          print('');
          print('   Status:     ${_server != null ? '🟢 Running' : '🔴 Stopped'}');
          if (addr != null && port != null) {
            print('   Host:       ${addr.host}');
            print('   Port:       $port');
            print('   URL:        http://${addr.host}:$port${_config.path}');
          }
          print('   Resources:  ${_config.resources.length}');
          print('   Database:   ${_config.databaseConfig != null ? '✓ Connected' : '✗ Not configured'}');
          print('   Logging:    ${httpLoggingEnabled ? '✓ Enabled' : '✗ Disabled'}');
          print('');
        },
      ),
    );

    _devConsole!.registerCommand(
      DevCommand(
        name: 'logs',
        shortName: 'l',
        description: 'Toggle HTTP request logging',
        handler: (_) async {
          httpLoggingEnabled = !httpLoggingEnabled;
          final status = httpLoggingEnabled ? '✓ enabled' : '✗ disabled';
          print('\n📝 HTTP logging $status\n');
        },
      ),
    );

    // Register custom dev commands from the panel config
    for (final command in _config.devCommands) {
      _devConsole!.registerCommand(command);
    }

    await _devConsole!.start();
  }

  /// Opens a URL in the default browser.
  Future<void> _openInBrowser(String url) async {
    try {
      if (Platform.isMacOS) {
        await Process.run('open', [url]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [url]);
      } else if (Platform.isWindows) {
        await Process.run('start', [url], runInShell: true);
      }
    } catch (e) {
      print('   Could not open browser: $e');
    }
  }

  /// Stops the HTTP server.
  Future<void> stop({bool force = false}) async {
    // Stop dev console first
    if (_devConsole != null) {
      await _devConsole!.stop();
      _devConsole = null;
    }

    if (_server == null) {
      return;
    }

    await _server!.close(force: force);
    _server = null;
    print('✓ Dash server stopped');
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
          return Response.notFound('Storage error: ${e.message}');
        }
      };
    };
  }

  /// Creates a middleware that conditionally logs requests based on [httpLoggingEnabled].
  Middleware _conditionalLogRequests() {
    return (Handler innerHandler) {
      return (Request request) async {
        final startTime = DateTime.now();
        final response = await innerHandler(request);

        if (httpLoggingEnabled) {
          final duration = DateTime.now().difference(startTime);
          final method = request.method.padRight(7);
          final statusCode = response.statusCode;
          print('$startTime  ${duration.toString().padRight(15)} $method [$statusCode] ${request.requestedUri.path}');
        }

        return response;
      };
    };
  }
}
