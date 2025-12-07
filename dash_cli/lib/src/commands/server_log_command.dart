import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dash_panel_cli/src/commands/base_command.dart';
import 'package:dash_panel_cli/src/commands/completion_configuration.dart';
import 'package:dash_panel_cli/src/commands/dcli_argument.dart';
import 'package:dash_panel_cli/src/utils/console_utils.dart';
import 'package:http/http.dart' as http;

/// Stream server logs to the console.
///
/// Usage:
///   dcli server:log [options]
///
/// Options:
///   -f, --follow      Follow log output (tail mode)
///   -n, --lines       Number of lines to show (default: 50)
///   --url             Server URL (default: http://localhost:8080)
class ServerLogCommand extends BaseCommand {
  ServerLogCommand() {
    DcliArgument.addToParser(argParser, _arguments);
  }

  /// Unified argument definitions.
  static final _arguments = [
    DcliArgument.flag(name: 'follow', abbr: 'f', help: 'Follow log output (like tail -f)'),
    DcliArgument.option(
      name: 'lines',
      abbr: 'n',
      help: 'Number of lines to show',
      defaultsTo: '50',
      completionType: CompletionType.number,
    ),
    DcliArgument.option(name: 'url', help: 'Server URL', defaultsTo: 'http://localhost:8080'),
    DcliArgument.option(name: 'path', help: 'Admin panel base path', defaultsTo: '/admin'),
  ];

  @override
  final String name = 'server:log';

  @override
  final String description = 'Stream server logs to the console';

  @override
  final List<String> aliases = ['log', 'logs'];

  @override
  Future<int> run() async {
    final follow = argResults!['follow'] as bool;
    final lines = int.tryParse(argResults!['lines'] as String) ?? 50;
    final serverUrl = argResults!['url'] as String;
    final basePath = argResults!['path'] as String;

    final apiUrl = '$serverUrl$basePath/_cli/logs';

    ConsoleUtils.header('📋 Server Logs');
    ConsoleUtils.info('Server: $serverUrl$basePath');
    print('');

    try {
      if (follow) {
        // Follow mode - poll for new logs
        return await _followLogs(apiUrl, lines);
      } else {
        // One-shot mode - fetch and display logs
        return await _fetchLogs(apiUrl, lines);
      }
    } on SocketException catch (e) {
      ConsoleUtils.error('Cannot connect to server: ${e.message}');
      print('');
      print('Make sure the Dash server is running at $serverUrl$basePath');
      return 1;
    } catch (e) {
      ConsoleUtils.error('Failed to fetch logs: $e');
      return 1;
    }
  }

  Future<int> _fetchLogs(String apiUrl, int lines) async {
    final response = await http.get(Uri.parse('$apiUrl?lines=$lines'));

    if (response.statusCode == 404) {
      ConsoleUtils.warning('CLI API not enabled on server');
      print('');
      print('Add enableCliApi: true to your panel configuration to enable CLI commands.');
      return 1;
    }

    if (response.statusCode != 200) {
      ConsoleUtils.error('Server returned error: ${response.statusCode}');
      return 1;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final logs = data['logs'] as List<dynamic>? ?? [];

    if (logs.isEmpty) {
      ConsoleUtils.info('No logs available');
      return 0;
    }

    for (final log in logs) {
      _printLogEntry(log as Map<String, dynamic>);
    }

    return 0;
  }

  Future<int> _followLogs(String apiUrl, int initialLines) async {
    var lastTimestamp = '';
    var firstFetch = true;

    print('${ConsoleUtils.gray}Streaming logs... Press Ctrl+C to stop${ConsoleUtils.reset}');
    print('');

    // Handle Ctrl+C gracefully
    ProcessSignal.sigint.watch().listen((_) {
      print('');
      ConsoleUtils.info('Stopped following logs');
      exit(0);
    });

    while (true) {
      try {
        final url = firstFetch ? '$apiUrl?lines=$initialLines' : '$apiUrl?since=${Uri.encodeComponent(lastTimestamp)}';

        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final logs = data['logs'] as List<dynamic>? ?? [];

          for (final log in logs) {
            final entry = log as Map<String, dynamic>;
            _printLogEntry(entry);

            // Track last timestamp for incremental fetching
            if (entry['timestamp'] != null) {
              lastTimestamp = entry['timestamp'] as String;
            }
          }

          firstFetch = false;
        }
      } catch (_) {
        // Silently ignore connection errors during polling
      }

      // Poll every second
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  void _printLogEntry(Map<String, dynamic> entry) {
    final level = entry['level'] as String? ?? 'info';
    final message = entry['message'] as String? ?? '';
    final timestamp = entry['timestamp'] as String? ?? '';

    // Format timestamp
    final time = timestamp.isNotEmpty ? timestamp.split('T').last.split('.').first : '';

    // Color based on level
    String levelColor;
    switch (level.toLowerCase()) {
      case 'error':
        levelColor = ConsoleUtils.red;
        break;
      case 'warning':
      case 'warn':
        levelColor = ConsoleUtils.yellow;
        break;
      case 'debug':
        levelColor = ConsoleUtils.gray;
        break;
      default:
        levelColor = ConsoleUtils.blue;
    }

    print(
      '${ConsoleUtils.gray}$time${ConsoleUtils.reset} '
      '$levelColor[${level.toUpperCase().padRight(5)}]${ConsoleUtils.reset} '
      '$message',
    );
  }

  @override
  CompletionConfiguration getCompletionConfig() {
    return DcliArgument.toCompletionConfig(
      name: name,
      description: description,
      arguments: _arguments,
      aliases: aliases,
    );
  }
}
