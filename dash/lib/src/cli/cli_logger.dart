import 'package:dash_board/src/cli/cli_api_handler.dart';
import 'package:dash_board/src/service_locator.dart';

/// Log levels for CLI logging.
enum LogLevel { debug, info, warning, error }

/// Global function to log messages to the CLI API handler.
///
/// This function gracefully returns `null` if no [CliApiHandler] is registered,
/// allowing it to be used anywhere in the codebase without checking for registration.
///
/// Example:
/// ```dart
/// cliLog('User logged in', level: LogLevel.info);
/// cliLog('Database query failed', level: LogLevel.error);
/// ```
void cliLog(String message, {LogLevel level = LogLevel.info}) {
  if (!inject.isRegistered<CliApiHandler>()) {
    return;
  }

  final handler = inject<CliApiHandler>();
  handler.log(message, level: level.name);
}

/// Log a request with timing information.
///
/// Returns `null` if no [CliApiHandler] is registered.
void cliLogRequest({
  required String method,
  required String path,
  required int statusCode,
  required Duration duration,
}) {
  if (!inject.isRegistered<CliApiHandler>()) {
    return;
  }

  final handler = inject<CliApiHandler>();
  final durationMs = duration.inMicroseconds / 1000;
  handler.log('$method $path -> $statusCode (${durationMs.toStringAsFixed(2)}ms)', level: 'request');
}

/// Log a database query with timing information.
///
/// Returns `null` if no [CliApiHandler] is registered.
void cliLogQuery({required String sql, List<dynamic>? parameters, Duration? duration, int? rowCount}) {
  if (!inject.isRegistered<CliApiHandler>()) {
    return;
  }

  final handler = inject<CliApiHandler>();
  final buffer = StringBuffer(sql);

  if (parameters != null && parameters.isNotEmpty) {
    buffer.write(' [${parameters.join(', ')}]');
  }

  if (duration != null) {
    final durationMs = duration.inMicroseconds / 1000;
    buffer.write(' (${durationMs.toStringAsFixed(2)}ms)');
  }

  if (rowCount != null) {
    buffer.write(' -> $rowCount rows');
  }

  handler.log(buffer.toString(), level: 'query');
}

/// Log an exception with optional stack trace.
///
/// Returns `null` if no [CliApiHandler] is registered.
void cliLogException(Object error, {StackTrace? stackTrace, String? context}) {
  if (!inject.isRegistered<CliApiHandler>()) {
    return;
  }

  final handler = inject<CliApiHandler>();
  final buffer = StringBuffer();

  if (context != null) {
    buffer.write('[$context] ');
  }

  buffer.write(error.toString());

  handler.log(buffer.toString(), level: 'error');

  // Log stack trace as separate entry if provided
  if (stackTrace != null) {
    // Only log first few lines of stack trace to avoid flooding
    final lines = stackTrace.toString().split('\n').take(5).join('\n');
    handler.log('Stack trace:\n$lines', level: 'error');
  }
}
