import 'package:dash_board/src/cli/cli_logger.dart';
import 'package:dash_board/src/panel/middleware_stack.dart';
import 'package:shelf/shelf.dart' hide Middleware;

/// Creates a middleware that logs requests except for CLI API requests.
class LogRequestsMiddleware implements Middleware {
  @override
  Handler call(Handler innerHandler) {
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
  }

  @override
  MiddlewareEntry toEntry() {
    return MiddlewareEntry.make(stage: MiddlewareStage.logging, middleware: this, id: 'log-requests');
  }
}
