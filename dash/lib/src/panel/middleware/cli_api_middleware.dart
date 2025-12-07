import 'package:dash_board/src/cli/cli_api_handler.dart';
import 'package:dash_board/src/panel/middleware_stack.dart';
import 'package:dash_board/src/panel/panel_config.dart';
import 'package:shelf/shelf.dart' hide Middleware;

/// Middleware that handles CLI API requests before auth.
///
/// This allows the CLI tool to access server status and logs
/// without authentication.
class CliApiMiddleware implements Middleware {
  final PanelConfig config;
  final CliApiHandler cliApiHandler;
  final bool enableCliApi;

  CliApiMiddleware(this.config, this.cliApiHandler, this.enableCliApi);

  @override
  Handler call(Handler innerHandler) {
    final basePath = config.path.replaceFirst('/', '');
    final cliPrefix = '$basePath/_cli/';

    return (Request request) async {
      final path = request.url.path;

      // Handle CLI API request
      if (path.startsWith(cliPrefix) && enableCliApi) {
        final cliResponse = await cliApiHandler.handle(request);
        if (cliResponse != null) {
          return cliResponse;
        }
      }

      return innerHandler(request);
    };
  }

  @override
  MiddlewareEntry toEntry() {
    return MiddlewareEntry.make(stage: MiddlewareStage.cli, middleware: this, id: 'cli-api');
  }
}
