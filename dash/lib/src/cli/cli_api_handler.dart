import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dash/src/cli/log_writer.dart';
import 'package:dash/src/panel/panel_config.dart';
import 'package:shelf/shelf.dart';

/// HTTP API handler for CLI commands.
///
/// Provides REST endpoints for the dash_cli tool to interact with
/// the running server. Endpoints include:
///
/// - GET /_cli/status - Server status and health
/// - GET /_cli/logs - Query log entries
/// - GET /_cli/schema - Database schema information
///
/// Log messages can be written using the global [cliLog] function
/// or by calling [log] directly on the handler instance.
class CliApiHandler {
  final PanelConfig _config;
  final DateTime _startTime = DateTime.now();
  final LogWriter _logWriter = LogWriter();

  /// List of log entries for the CLI
  final List<Map<String, dynamic>> _logs = [];

  /// Maximum number of log entries to keep.
  static const int _maxLogs = 1000;

  CliApiHandler(this._config);

  /// Log a message that will be available to the CLI.
  ///
  /// [level] can be: 'debug', 'info', 'warning', 'error', 'request', 'query'
  void log(String message, {String level = 'info'}) {
    final timestamp = DateTime.now();
    final entry = {'timestamp': timestamp.toIso8601String(), 'level': level, 'message': message};

    _logs.add(entry);

    // Write to file if enabled
    _logToFile(timestamp, level, message);

    // Trim old logs
    while (_logs.length > _maxLogs) {
      _logs.removeAt(0);
    }
  }

  /// Writes a log entry to the log file via LogWriter.
  void _logToFile(DateTime timestamp, String level, String message) {
    final logLine = _formatLogLine(timestamp, level, message);
    _logWriter.write(logLine);
  }

  /// Formats a log entry as a single line for the log file.
  ///
  /// Format: `[YYYY-MM-DD HH:MM:SS] [LEVEL] message\n`
  String _formatLogLine(DateTime timestamp, String level, String message) {
    final date = timestamp.toIso8601String().replaceFirst('T', ' ').split('.').first;
    final levelPadded = level.toUpperCase().padRight(7);
    return '[$date] [$levelPadded] $message\n';
  }

  /// Get the current log entries.
  List<Map<String, dynamic>> get logs => List.unmodifiable(_logs);

  /// Clear all log entries.
  void clearLogs() {
    _logs.clear();
  }

  /// Handle CLI API requests.
  ///
  /// Returns null if the request is not a CLI API request.
  Future<Response?> handle(Request request) async {
    final path = request.url.path;

    // The path includes the base path, e.g., 'admin/_cli/status'
    // Extract the endpoint after '_cli/'
    final cliIndex = path.indexOf('_cli/');
    if (cliIndex == -1) {
      return null;
    }

    final endpoint = path.substring(cliIndex + 5); // Remove everything up to and including '_cli/'

    switch (endpoint) {
      case 'status':
        return _handleStatus(request);
      case 'logs':
        return _handleLogs(request);
      case 'health':
        return _handleHealth(request);
      default:
        return Response.notFound(
          jsonEncode({'error': 'Unknown endpoint: $endpoint'}),
          headers: {'content-type': 'application/json'},
        );
    }
  }

  /// GET /_cli/status - Server status and resource information.
  Response _handleStatus(Request request) {
    final uptime = DateTime.now().difference(_startTime);

    final resourceList = _config.resources.map((r) => {'name': r.singularLabel, 'slug': r.slug}).toList();

    final data = {
      'status': 'running',
      'version': '0.1.0',
      'uptime': uptime.inSeconds,
      'resources': _config.resources.length,
      'database': _config.databaseConfig != null,
      'resourceList': resourceList,
      'memory': {'heapUsed': ProcessInfo.currentRss, 'heapTotal': ProcessInfo.maxRss},
    };

    return Response.ok(jsonEncode(data), headers: {'content-type': 'application/json'});
  }

  /// GET /_cli/logs - Query logs with optional filtering.
  ///
  /// Query parameters:
  /// - lines: Number of lines to return (default: 50)
  /// - since: Return only logs after this ISO timestamp
  /// - level: Filter by log level (debug, info, warning, error, request, query)
  Response _handleLogs(Request request) {
    final params = request.url.queryParameters;
    final lines = int.tryParse(params['lines'] ?? '50') ?? 50;
    final since = params['since'];
    final level = params['level'];

    var logs = _logs.toList();

    // Filter by timestamp
    if (since != null) {
      try {
        final sinceTime = DateTime.parse(since);
        logs = logs.where((l) {
          final ts = DateTime.tryParse(l['timestamp'] as String);
          return ts != null && ts.isAfter(sinceTime);
        }).toList();
      } catch (_) {
        // Invalid timestamp, ignore filter
      }
    }

    // Filter by level (supports comma-separated values)
    if (level != null) {
      final levels = level.split(',').map((l) => l.trim()).toSet();
      logs = logs.where((l) => levels.contains(l['level'])).toList();
    }

    // Limit results
    if (logs.length > lines) {
      logs = logs.sublist(logs.length - lines);
    }

    return Response.ok(jsonEncode({'logs': logs}), headers: {'content-type': 'application/json'});
  }

  /// GET /_cli/health - Simple health check endpoint.
  Response _handleHealth(Request request) {
    return Response.ok(jsonEncode({'status': 'ok'}), headers: {'content-type': 'application/json'});
  }
}
