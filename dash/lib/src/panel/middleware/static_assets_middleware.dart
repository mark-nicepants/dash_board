import 'package:dash_board/src/panel/middleware_stack.dart';
import 'package:dash_board/src/panel/panel_config.dart';
import 'package:dash_board/src/utils/resource_loader.dart';
import 'package:shelf/shelf.dart' hide Middleware;
import 'package:shelf_static/shelf_static.dart';

/// Middleware that serves static assets (CSS, JS, images) before auth.
///
/// Assets are served from:
/// - /admin/assets/css/* -> resources/dist/css/*
/// - /admin/assets/js/*  -> resources/dist/js/*
/// - /admin/assets/img/* -> resources/img/*
///
/// Uses shelf_static for efficient file serving with proper MIME types,
/// ETags, and range request support.
class StaticAssetsMiddleware implements Middleware {
  final PanelConfig config;
  final ResourceLoader resourceLoader;

  StaticAssetsMiddleware(this.config, this.resourceLoader);

  @override
  Handler call(Handler innerHandler) {
    final basePath = config.path.replaceFirst('/', '');
    final assetsPrefix = '$basePath/assets/';

    // Create static handlers for each directory
    final distHandler = createStaticHandler(resourceLoader.distDir, defaultDocument: null);

    final imagesHandler = createStaticHandler(resourceLoader.imagesDir, defaultDocument: null);

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
        final response = await distHandler(Request(request.method, request.requestedUri.replace(path: '/$assetPath')));
        if (response.statusCode != 404) {
          return _addCacheHeaders(response);
        }
      } else if (assetPath.startsWith('img/')) {
        // Image files from img/
        final subPath = assetPath.substring(4); // Remove 'img/' prefix
        final response = await imagesHandler(Request(request.method, request.requestedUri.replace(path: '/$subPath')));
        if (response.statusCode != 404) {
          return _addCacheHeaders(response);
        }
      }

      // Asset not found or unknown type
      return Response.notFound('Asset not found: $assetPath');
    };
  }

  /// Adds cache control headers to static asset responses.
  Response _addCacheHeaders(Response response) {
    final cacheControl = resourceLoader.isProduction
        ? 'public, max-age=31536000' // 1 year for production
        : 'no-cache'; // No cache for development

    return response.change(headers: {'cache-control': cacheControl});
  }

  @override
  MiddlewareEntry toEntry() {
    return MiddlewareEntry.make(stage: MiddlewareStage.asset, middleware: this, id: 'static-assets', priority: 400);
  }
}
