import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:dart_mcp/server.dart';
import 'package:dart_mcp/stdio.dart';
import 'package:http/http.dart' as http;

/// MCP Server for Dash admin panel.
///
/// Provides tools for LLMs to interact with a running Dash server,
/// including access to:
/// - Server status and health
/// - Request logs
/// - SQL query logs
/// - Exception logs
/// - Database schema
final class DashMcpServer extends MCPServer with ToolsSupport, LoggingSupport {
  DashMcpServer(super.channel, {required this.serverUrl, required this.basePath, http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client(),
      super.fromStreamChannel(
        implementation: Implementation(name: 'dash-mcp-server', version: '0.1.0'),
        instructions: '''
This MCP server provides tools to interact with a running Dash admin panel server.
Use these tools to:
- Check server status and health
- Query request logs to debug HTTP requests
- Query SQL logs to debug database queries
- View exceptions and errors
- Inspect database schema

The server must be running for these tools to work.
''',
      );

  /// The base URL of the Dash server.
  final String serverUrl;

  /// The admin panel path.
  final String basePath;

  /// HTTP client for making requests to the Dash server.
  final http.Client _httpClient;

  /// Run the MCP server with stdio transport.
  static Future<void> run({required String serverUrl, required String basePath}) async {
    final server = DashMcpServer(
      stdioChannel(input: io.stdin, output: io.stdout),
      serverUrl: serverUrl,
      basePath: basePath,
    );
    // Wait for the server to complete (keeps the process alive)
    await server.done;
  }

  @override
  FutureOr<InitializeResult> initialize(InitializeRequest request) {
    _registerTools();
    return super.initialize(request);
  }

  void _registerTools() {
    // Server status tool
    registerTool(
      Tool(
        name: 'get_server_status',
        description: '''
Get the current status of the Dash server including:
- Server status (running/offline)
- Uptime
- Number of registered resources
- Database connection status
- Memory usage
''',
        inputSchema: Schema.object(),
      ),
      _handleGetServerStatus,
    );

    // Get registered resources
    registerTool(
      Tool(
        name: 'get_registered_resources',
        description: '''
Get a list of all registered resources in the Dash admin panel.
Returns the name and slug for each resource.
''',
        inputSchema: Schema.object(),
      ),
      _handleGetResources,
    );

    // Get request logs
    registerTool(
      Tool(
        name: 'get_request_logs',
        description: '''
Query HTTP request logs from the Dash server.
Useful for debugging request handling and seeing what endpoints are being called.
''',
        inputSchema: Schema.object(
          properties: {
            'lines': Schema.int(description: 'Number of log entries to return (default: 50, max: 200)'),
            'since': Schema.string(
              description: 'Return only logs after this ISO timestamp (e.g., 2025-12-04T10:00:00)',
            ),
          },
        ),
      ),
      _handleGetRequestLogs,
    );

    // Get SQL query logs
    registerTool(
      Tool(
        name: 'get_sql_logs',
        description: '''
Query SQL execution logs from the Dash server.
Shows SQL queries with their parameters, execution time, and row counts.
Useful for debugging database queries and finding slow queries.
''',
        inputSchema: Schema.object(
          properties: {
            'lines': Schema.int(description: 'Number of log entries to return (default: 50, max: 200)'),
            'since': Schema.string(description: 'Return only logs after this ISO timestamp'),
          },
        ),
      ),
      _handleGetSqlLogs,
    );

    // Get exceptions/errors
    registerTool(
      Tool(
        name: 'get_exceptions',
        description: '''
Query error and exception logs from the Dash server.
Shows errors with stack traces for debugging.
''',
        inputSchema: Schema.object(
          properties: {
            'lines': Schema.int(description: 'Number of log entries to return (default: 50, max: 200)'),
            'since': Schema.string(description: 'Return only logs after this ISO timestamp'),
          },
        ),
      ),
      _handleGetExceptions,
    );

    // Get all logs (combined)
    registerTool(
      Tool(
        name: 'get_all_logs',
        description: '''
Query all logs from the Dash server including requests, SQL queries, and errors.
Useful for getting a complete picture of server activity.
''',
        inputSchema: Schema.object(
          properties: {
            'lines': Schema.int(description: 'Number of log entries to return (default: 50, max: 200)'),
            'since': Schema.string(description: 'Return only logs after this ISO timestamp'),
            'level': Schema.string(
              description: 'Filter by log level. Comma-separated values: debug,info,warning,error,request,query',
            ),
          },
        ),
      ),
      _handleGetAllLogs,
    );

    // Get slow requests
    registerTool(
      Tool(
        name: 'get_slow_requests',
        description: '''
Find HTTP requests that took longer than a specified threshold.
Useful for identifying performance issues.
''',
        inputSchema: Schema.object(
          properties: {
            'threshold_ms': Schema.int(
              description: 'Minimum request duration in milliseconds to include (default: 100)',
            ),
            'lines': Schema.int(description: 'Maximum number of slow requests to return (default: 20)'),
          },
        ),
      ),
      _handleGetSlowRequests,
    );

    // Get slow SQL queries
    registerTool(
      Tool(
        name: 'get_slow_queries',
        description: '''
Find SQL queries that took longer than a specified threshold.
Useful for identifying database performance issues.
''',
        inputSchema: Schema.object(
          properties: {
            'threshold_ms': Schema.int(description: 'Minimum query duration in milliseconds to include (default: 10)'),
            'lines': Schema.int(description: 'Maximum number of slow queries to return (default: 20)'),
          },
        ),
      ),
      _handleGetSlowQueries,
    );

    // Generate models tool
    registerTool(
      Tool(
        name: 'generate_models',
        description: '''
Generate Dart model and resource classes from YAML schema files.
This runs the 'dcli generate:models' command in the current working directory.

Use this tool after updating or creating schema YAML files to regenerate the Dart code.
The generated files include:
- Model classes with Active Record pattern
- Resource classes for the admin panel
- Barrel export file for easy imports
''',
        inputSchema: Schema.object(
          properties: {
            'schemas_path': Schema.string(description: 'Path to schema YAML files directory (default: schemas/models)'),
            'output_path': Schema.string(description: 'Output directory for generated code (default: lib)'),
            'force': Schema.bool(description: 'Overwrite existing resource files (default: false)'),
          },
        ),
      ),
      _handleGenerateModels,
    );
  }

  /// Build the API URL for a given endpoint.
  String _apiUrl(String endpoint) => '$serverUrl$basePath/_cli/$endpoint';

  /// Make an HTTP request to the server.
  Future<Map<String, dynamic>?> _fetchJson(String endpoint, {Map<String, String>? queryParams}) async {
    try {
      var uri = Uri.parse(_apiUrl(endpoint));
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final response = await _httpClient.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        return {'error': 'CLI API not enabled on server. Enable with enableCliApi: true'};
      } else {
        return {'error': 'Server returned status ${response.statusCode}'};
      }
    } on io.SocketException catch (e) {
      return {'error': 'Cannot connect to server: ${e.message}'};
    } on TimeoutException {
      return {'error': 'Connection timeout'};
    } catch (e) {
      return {'error': 'Request failed: $e'};
    }
  }

  /// Handle get_server_status tool call.
  Future<CallToolResult> _handleGetServerStatus(CallToolRequest request) async {
    final data = await _fetchJson('status');
    if (data == null) {
      return _errorResult('Failed to fetch server status');
    }
    if (data.containsKey('error')) {
      return _errorResult(data['error'] as String);
    }

    final buffer = StringBuffer();
    buffer.writeln('## Dash Server Status');
    buffer.writeln();
    buffer.writeln('**Status:** ${data['status'] ?? 'unknown'}');
    buffer.writeln('**Version:** ${data['version'] ?? 'unknown'}');

    if (data['uptime'] != null) {
      buffer.writeln('**Uptime:** ${_formatUptime(data['uptime'] as int)}');
    }

    buffer.writeln('**Resources:** ${data['resources'] ?? 0} registered');
    buffer.writeln('**Database:** ${data['database'] == true ? 'Connected' : 'Not connected'}');

    if (data['memory'] != null) {
      final memory = data['memory'] as Map<String, dynamic>;
      buffer.writeln();
      buffer.writeln('### Memory');
      buffer.writeln('- Heap used: ${_formatBytes(memory['heapUsed'] as int? ?? 0)}');
      buffer.writeln('- Heap total: ${_formatBytes(memory['heapTotal'] as int? ?? 0)}');
    }

    return CallToolResult(content: [TextContent(text: buffer.toString())]);
  }

  /// Handle get_registered_resources tool call.
  Future<CallToolResult> _handleGetResources(CallToolRequest request) async {
    final data = await _fetchJson('status');
    if (data == null) {
      return _errorResult('Failed to fetch resources');
    }
    if (data.containsKey('error')) {
      return _errorResult(data['error'] as String);
    }

    final resourceList = data['resourceList'] as List<dynamic>? ?? [];
    if (resourceList.isEmpty) {
      return CallToolResult(content: [TextContent(text: 'No resources registered')]);
    }

    final buffer = StringBuffer();
    buffer.writeln('## Registered Resources');
    buffer.writeln();

    for (final resource in resourceList) {
      final r = resource as Map<String, dynamic>;
      buffer.writeln('- **${r['name']}** (/${r['slug']})');
    }

    return CallToolResult(content: [TextContent(text: buffer.toString())]);
  }

  /// Handle get_request_logs tool call.
  Future<CallToolResult> _handleGetRequestLogs(CallToolRequest request) async {
    final args = request.arguments ?? {};
    final lines = (args['lines'] as int?)?.clamp(1, 200) ?? 50;
    final since = args['since'] as String?;

    final queryParams = <String, String>{'lines': lines.toString(), 'level': 'request'};
    if (since != null) queryParams['since'] = since;

    final data = await _fetchJson('logs', queryParams: queryParams);
    if (data == null) {
      return _errorResult('Failed to fetch logs');
    }
    if (data.containsKey('error')) {
      return _errorResult(data['error'] as String);
    }

    return _formatLogs(data, 'Request Logs');
  }

  /// Handle get_sql_logs tool call.
  Future<CallToolResult> _handleGetSqlLogs(CallToolRequest request) async {
    final args = request.arguments ?? {};
    final lines = (args['lines'] as int?)?.clamp(1, 200) ?? 50;
    final since = args['since'] as String?;

    final queryParams = <String, String>{'lines': lines.toString(), 'level': 'query'};
    if (since != null) queryParams['since'] = since;

    final data = await _fetchJson('logs', queryParams: queryParams);
    if (data == null) {
      return _errorResult('Failed to fetch logs');
    }
    if (data.containsKey('error')) {
      return _errorResult(data['error'] as String);
    }

    return _formatLogs(data, 'SQL Query Logs');
  }

  /// Handle get_exceptions tool call.
  Future<CallToolResult> _handleGetExceptions(CallToolRequest request) async {
    final args = request.arguments ?? {};
    final lines = (args['lines'] as int?)?.clamp(1, 200) ?? 50;
    final since = args['since'] as String?;

    final queryParams = <String, String>{'lines': lines.toString(), 'level': 'error'};
    if (since != null) queryParams['since'] = since;

    final data = await _fetchJson('logs', queryParams: queryParams);
    if (data == null) {
      return _errorResult('Failed to fetch logs');
    }
    if (data.containsKey('error')) {
      return _errorResult(data['error'] as String);
    }

    return _formatLogs(data, 'Exception Logs');
  }

  /// Handle get_all_logs tool call.
  Future<CallToolResult> _handleGetAllLogs(CallToolRequest request) async {
    final args = request.arguments ?? {};
    final lines = (args['lines'] as int?)?.clamp(1, 200) ?? 50;
    final since = args['since'] as String?;
    final level = args['level'] as String?;

    final queryParams = <String, String>{'lines': lines.toString()};
    if (since != null) queryParams['since'] = since;
    if (level != null) queryParams['level'] = level;

    final data = await _fetchJson('logs', queryParams: queryParams);
    if (data == null) {
      return _errorResult('Failed to fetch logs');
    }
    if (data.containsKey('error')) {
      return _errorResult(data['error'] as String);
    }

    return _formatLogs(data, 'Server Logs');
  }

  /// Handle get_slow_requests tool call.
  Future<CallToolResult> _handleGetSlowRequests(CallToolRequest request) async {
    final args = request.arguments ?? {};
    final thresholdMs = args['threshold_ms'] as int? ?? 100;
    final maxLines = (args['lines'] as int?)?.clamp(1, 100) ?? 20;

    // Fetch a large batch of request logs
    final data = await _fetchJson('logs', queryParams: {'lines': '200', 'level': 'request'});

    if (data == null) {
      return _errorResult('Failed to fetch logs');
    }
    if (data.containsKey('error')) {
      return _errorResult(data['error'] as String);
    }

    final logs = data['logs'] as List<dynamic>? ?? [];
    final slowRequests = <Map<String, dynamic>>[];

    // Parse and filter for slow requests
    final durationPattern = RegExp(r'\((\d+\.?\d*)ms\)');
    for (final log in logs) {
      final entry = log as Map<String, dynamic>;
      final message = entry['message'] as String? ?? '';
      final match = durationPattern.firstMatch(message);
      if (match != null) {
        final duration = double.tryParse(match.group(1) ?? '') ?? 0;
        if (duration >= thresholdMs) {
          slowRequests.add({...entry, '_duration': duration});
        }
      }
    }

    // Sort by duration descending
    slowRequests.sort((a, b) => (b['_duration'] as double).compareTo(a['_duration'] as double));

    // Limit results
    final limitedRequests = slowRequests.take(maxLines).toList();

    if (limitedRequests.isEmpty) {
      return CallToolResult(content: [TextContent(text: 'No requests found slower than ${thresholdMs}ms')]);
    }

    final buffer = StringBuffer();
    buffer.writeln('## Slow Requests (>${thresholdMs}ms)');
    buffer.writeln();

    for (final entry in limitedRequests) {
      final timestamp = entry['timestamp'] as String? ?? '';
      final time = timestamp.isNotEmpty ? timestamp.split('T').last.split('.').first : '';
      final message = entry['message'] as String? ?? '';
      buffer.writeln('**$time** $message');
    }

    return CallToolResult(content: [TextContent(text: buffer.toString())]);
  }

  /// Handle get_slow_queries tool call.
  Future<CallToolResult> _handleGetSlowQueries(CallToolRequest request) async {
    final args = request.arguments ?? {};
    final thresholdMs = args['threshold_ms'] as int? ?? 10;
    final maxLines = (args['lines'] as int?)?.clamp(1, 100) ?? 20;

    // Fetch a large batch of query logs
    final data = await _fetchJson('logs', queryParams: {'lines': '200', 'level': 'query'});

    if (data == null) {
      return _errorResult('Failed to fetch logs');
    }
    if (data.containsKey('error')) {
      return _errorResult(data['error'] as String);
    }

    final logs = data['logs'] as List<dynamic>? ?? [];
    final slowQueries = <Map<String, dynamic>>[];

    // Parse and filter for slow queries
    final durationPattern = RegExp(r'\((\d+\.?\d*)ms\)');
    for (final log in logs) {
      final entry = log as Map<String, dynamic>;
      final message = entry['message'] as String? ?? '';
      final match = durationPattern.firstMatch(message);
      if (match != null) {
        final duration = double.tryParse(match.group(1) ?? '') ?? 0;
        if (duration >= thresholdMs) {
          slowQueries.add({...entry, '_duration': duration});
        }
      }
    }

    // Sort by duration descending
    slowQueries.sort((a, b) => (b['_duration'] as double).compareTo(a['_duration'] as double));

    // Limit results
    final limitedQueries = slowQueries.take(maxLines).toList();

    if (limitedQueries.isEmpty) {
      return CallToolResult(content: [TextContent(text: 'No queries found slower than ${thresholdMs}ms')]);
    }

    final buffer = StringBuffer();
    buffer.writeln('## Slow SQL Queries (>${thresholdMs}ms)');
    buffer.writeln();

    for (final entry in limitedQueries) {
      final timestamp = entry['timestamp'] as String? ?? '';
      final time = timestamp.isNotEmpty ? timestamp.split('T').last.split('.').first : '';
      final message = entry['message'] as String? ?? '';
      buffer.writeln('**$time** `$message`');
      buffer.writeln();
    }

    return CallToolResult(content: [TextContent(text: buffer.toString())]);
  }

  /// Handle generate_models tool call.
  Future<CallToolResult> _handleGenerateModels(CallToolRequest request) async {
    final args = request.arguments ?? {};
    final schemasPath = args['schemas_path'] as String?;
    final outputPath = args['output_path'] as String?;
    final force = args['force'] as bool? ?? false;

    // Build command arguments
    final commandArgs = <String>['generate:models'];
    if (schemasPath != null) {
      commandArgs.addAll(['-s', schemasPath]);
    }
    if (outputPath != null) {
      commandArgs.addAll(['-o', outputPath]);
    }
    if (force) {
      commandArgs.add('--force');
    }

    try {
      // Run dcli generate:models command
      final result = await io.Process.run('dcli', commandArgs, workingDirectory: io.Directory.current.path);

      final buffer = StringBuffer();
      buffer.writeln('## Generate Models Result');
      buffer.writeln();

      if (result.exitCode == 0) {
        buffer.writeln('**Status:** ✅ Success');
        buffer.writeln();
        // Strip ANSI codes from output for clean display
        final output = _stripAnsiCodes(result.stdout as String);
        if (output.isNotEmpty) {
          buffer.writeln('```');
          buffer.writeln(output.trim());
          buffer.writeln('```');
        }
      } else {
        buffer.writeln('**Status:** ❌ Failed (exit code: ${result.exitCode})');
        buffer.writeln();
        final stderr = _stripAnsiCodes(result.stderr as String);
        final stdout = _stripAnsiCodes(result.stdout as String);
        if (stderr.isNotEmpty) {
          buffer.writeln('**Error:**');
          buffer.writeln('```');
          buffer.writeln(stderr.trim());
          buffer.writeln('```');
        }
        if (stdout.isNotEmpty) {
          buffer.writeln('**Output:**');
          buffer.writeln('```');
          buffer.writeln(stdout.trim());
          buffer.writeln('```');
        }
      }

      return CallToolResult(
        isError: result.exitCode != 0,
        content: [TextContent(text: buffer.toString())],
      );
    } catch (e) {
      return _errorResult('Failed to run generate:models command: $e');
    }
  }

  /// Strip ANSI escape codes from a string.
  String _stripAnsiCodes(String input) {
    return input.replaceAll(RegExp(r'\x1B\[[0-9;]*[a-zA-Z]'), '');
  }

  /// Format log data into a readable result.
  CallToolResult _formatLogs(Map<String, dynamic> data, String title) {
    final logs = data['logs'] as List<dynamic>? ?? [];
    if (logs.isEmpty) {
      return CallToolResult(content: [TextContent(text: 'No $title found')]);
    }

    final buffer = StringBuffer();
    buffer.writeln('## $title');
    buffer.writeln();

    for (final log in logs) {
      final entry = log as Map<String, dynamic>;
      final timestamp = entry['timestamp'] as String? ?? '';
      final level = entry['level'] as String? ?? 'info';
      final message = entry['message'] as String? ?? '';

      final time = timestamp.isNotEmpty ? timestamp.split('T').last.split('.').first : '';

      buffer.writeln('**$time** [$level] $message');
    }

    return CallToolResult(content: [TextContent(text: buffer.toString())]);
  }

  /// Create an error result.
  CallToolResult _errorResult(String message) {
    return CallToolResult(isError: true, content: [TextContent(text: 'Error: $message')]);
  }

  /// Format uptime in human-readable format.
  String _formatUptime(int seconds) {
    final duration = Duration(seconds: seconds);

    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h ${duration.inMinutes % 60}m';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m ${duration.inSeconds % 60}s';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  /// Format bytes in human-readable format.
  String _formatBytes(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB'];
    var value = bytes.toDouble();
    var unitIndex = 0;

    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex++;
    }

    return '${value.toStringAsFixed(1)} ${units[unitIndex]}';
  }
}
