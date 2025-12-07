import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dash_panel_cli/dash_panel_cli.dart';

/// Main entry point for the Dash CLI.
///
/// Usage:
///   dash command [arguments]
void main(List<String> args) async {
  final runner =
      CommandRunner<int>(
          'dcli',
          'Dash CLI - Command-line tools for Dash admin panel framework\n\n'
              'Available command groups:\n'
              '  generate:*  Code generation commands\n'
              '  db:*        Database commands\n'
              '  server:*    Server monitoring commands\n'
              '  mcp-server  MCP server for LLM integration',
        )
        // Code generation commands
        ..addCommand(GenerateModelsCommand())
        // Database commands
        ..addCommand(DbSchemaCommand())
        ..addCommand(DbSeedCommand())
        ..addCommand(DbClearCommand())
        ..addCommand(DbCreateCommand())
        // Server commands
        ..addCommand(ServerLogCommand())
        ..addCommand(ServerStatusCommand())
        // MCP Server command
        ..addCommand(McpServerCommand())
        // Utility commands
        ..addCommand(CompletionCommand());

  try {
    final result = await runner.run(args);
    exit(result ?? 0);
  } on UsageException catch (e) {
    print('${_red}Error:$_reset ${e.message}\n');
    print(e.usage);
    exit(64);
  } catch (e) {
    print('${_red}Error:$_reset $e');
    exit(1);
  }
}

const _red = '\x1B[31m';
const _reset = '\x1B[0m';
