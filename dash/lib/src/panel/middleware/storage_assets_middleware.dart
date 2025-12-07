import 'package:dash_board/src/cli/cli_logger.dart';
import 'package:dash_board/src/panel/middleware_stack.dart';
import 'package:dash_board/src/panel/panel_config.dart';
import 'package:dash_board/src/storage/storage.dart';
import 'package:shelf/shelf.dart' hide Middleware;

/// Creates middleware to serve files from storage.
///
/// Handles requests to /storage/* and serves files from the configured
/// storage disks.
class StorageAssetsMiddleware implements Middleware {
  final PanelConfig config;
  final StorageManager? storageManager;

  StorageAssetsMiddleware(this.config, this.storageManager);

  @override
  Handler call(Handler innerHandler) {
    final basePath = config.path.replaceFirst('/', '');
    final storagePrefix = '$basePath/storage/';

    return (Request request) async {
      final path = request.url.path;

      // Not a storage request, continue to next handler
      if (!path.startsWith(storagePrefix)) {
        return innerHandler(request);
      }

      // No storage manager configured
      if (storageManager == null) {
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
        final storage = storageManager!.disk(diskName);

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
  }

  @override
  MiddlewareEntry toEntry() {
    return MiddlewareEntry.make(stage: MiddlewareStage.asset, middleware: this, id: 'storage-assets', priority: 600);
  }
}
