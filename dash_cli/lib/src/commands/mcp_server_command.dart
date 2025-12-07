import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dash_panel_cli/src/mcp/dash_mcp_server.dart';

/// Start an MCP server for LLM integration.
///
/// Usage:
///   dcli mcp-server [options]
///
/// Options:
///   --url    Server URL (default: http://localhost:8080)
///   --path   Admin panel base path (default: /admin)
///
/// The MCP server provides tools for LLMs to interact with a running
/// Dash server, including:
/// - Server status and health monitoring
/// - Request log querying
/// - SQL query log inspection
/// - Exception/error log viewing
/// - Slow request/query analysis
class McpServerCommand extends Command<int> {
  McpServerCommand() {
    argParser
      ..addOption('url', help: 'Dash server URL', defaultsTo: 'http://localhost:8080')
      ..addOption('path', help: 'Admin panel base path', defaultsTo: '/admin');
  }

  @override
  final String name = 'mcp-server';

  @override
  final String description = 'Start an MCP server for LLM integration with Dash';

  @override
  final List<String> aliases = ['mcp'];

  @override
  Future<int> run() async {
    final serverUrl = argResults!['url'] as String;
    final basePath = argResults!['path'] as String;

    // Write startup message to stderr so it doesn't interfere with MCP protocol
    stderr.writeln('Starting Dash MCP Server...');
    stderr.writeln('Connecting to: $serverUrl$basePath');
    stderr.writeln('');

    // Run the MCP server (this blocks until shutdown)
    await DashMcpServer.run(serverUrl: serverUrl, basePath: basePath);

    return 0;
  }
}
