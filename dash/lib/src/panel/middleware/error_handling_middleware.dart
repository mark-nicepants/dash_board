import 'package:dash_board/src/cli/cli_logger.dart';
import 'package:dash_board/src/panel/middleware_stack.dart';
import 'package:shelf/shelf.dart' hide Middleware;

/// Middleware that catches and logs unhandled exceptions in request handlers.
class ErrorHandlingMiddleware implements Middleware {
  @override
  Handler call(Handler innerHandler) {
    return (Request request) async {
      try {
        return await innerHandler(request);
      } catch (e, stackTrace) {
        cliLogException(e, stackTrace: stackTrace, context: 'Request handler');
        return Response.internalServerError(body: 'Internal Server Error');
      }
    };
  }

  @override
  MiddlewareEntry toEntry() {
    return MiddlewareEntry.make(stage: MiddlewareStage.errorHandling, middleware: this, id: 'error-handler');
  }
}
