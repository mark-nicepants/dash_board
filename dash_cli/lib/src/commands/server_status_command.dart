import 'dart:convert';
import 'dart:io';

import 'package:dash_panel_cli/src/commands/base_command.dart';
import 'package:dash_panel_cli/src/commands/completion_configuration.dart';
import 'package:dash_panel_cli/src/commands/dcli_argument.dart';
import 'package:dash_panel_cli/src/utils/console_utils.dart';
import 'package:http/http.dart' as http;

/// Display server status and health information.
///
/// Usage:
///   dcli server:status [options]
///
/// Options:
///   --url    Server URL (default: http://localhost:8080)
///   --path   Admin panel base path (default: /admin)
class ServerStatusCommand extends BaseCommand {
  ServerStatusCommand() {
    DcliArgument.addToParser(argParser, _arguments);
  }

  /// Unified argument definitions.
  static final _arguments = [
    DcliArgument.option(name: 'url', help: 'Server URL', defaultsTo: 'http://localhost:8080'),
    DcliArgument.option(name: 'path', help: 'Admin panel base path', defaultsTo: '/admin'),
  ];

  @override
  final String name = 'server:status';

  @override
  final String description = 'Display server status and health information';

  @override
  final List<String> aliases = ['status'];

  @override
  Future<int> run() async {
    final serverUrl = argResults!['url'] as String;
    final basePath = argResults!['path'] as String;

    final fullUrl = '$serverUrl$basePath';
    final apiUrl = '$fullUrl/_cli/status';

    ConsoleUtils.header('📊 Server Status');
    print('');

    try {
      // First check if server is reachable
      final pingStart = DateTime.now();
      final response = await http
          .get(Uri.parse(apiUrl))
          .timeout(const Duration(seconds: 5), onTimeout: () => throw Exception('Connection timeout'));
      final pingDuration = DateTime.now().difference(pingStart);

      if (response.statusCode == 404) {
        // CLI API not enabled, but server is running
        // Fall back to basic health check
        return await _basicHealthCheck(fullUrl, pingDuration);
      }

      if (response.statusCode != 200) {
        ConsoleUtils.error('Server returned error: ${response.statusCode}');
        return 1;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _printStatus(data, pingDuration);

      return 0;
    } on SocketException catch (e) {
      _printOfflineStatus(fullUrl, e.message);
      return 1;
    } catch (e) {
      _printOfflineStatus(fullUrl, e.toString());
      return 1;
    }
  }

  Future<int> _basicHealthCheck(String serverUrl, Duration pingDuration) async {
    // Try to fetch the login page to check if server is running
    try {
      final response = await http.get(Uri.parse('$serverUrl/login'));

      if (response.statusCode == 200) {
        print('  ${ConsoleUtils.green}●${ConsoleUtils.reset} Status:        Online');
        print('  ${ConsoleUtils.gray}○${ConsoleUtils.reset} URL:           $serverUrl');
        print('  ${ConsoleUtils.gray}○${ConsoleUtils.reset} Response time: ${pingDuration.inMilliseconds}ms');
        print('');
        ConsoleUtils.warning('CLI API not enabled. Enable with enableCliApi: true');
        print('');
        return 0;
      }
    } catch (_) {}

    return 1;
  }

  void _printStatus(Map<String, dynamic> data, Duration pingDuration) {
    final status = data['status'] as String? ?? 'unknown';
    final uptime = data['uptime'] as int?;
    final resources = data['resources'] as int? ?? 0;
    final dbConnected = data['database'] as bool? ?? false;
    final memory = data['memory'] as Map<String, dynamic>?;
    final version = data['version'] as String?;

    // Status indicator
    final statusColor = status == 'running' ? ConsoleUtils.green : ConsoleUtils.red;
    final statusIcon = status == 'running' ? '●' : '○';

    print('  $statusColor$statusIcon${ConsoleUtils.reset} Status:        ${_capitalize(status)}');

    if (version != null) {
      print('  ${ConsoleUtils.gray}○${ConsoleUtils.reset} Version:       $version');
    }

    print('  ${ConsoleUtils.gray}○${ConsoleUtils.reset} Response time: ${pingDuration.inMilliseconds}ms');

    if (uptime != null) {
      print('  ${ConsoleUtils.gray}○${ConsoleUtils.reset} Uptime:        ${_formatUptime(uptime)}');
    }

    print('');
    ConsoleUtils.subHeader('Resources');
    print('  ${ConsoleUtils.gray}○${ConsoleUtils.reset} Resources:     $resources registered');

    final dbIcon = dbConnected
        ? '${ConsoleUtils.green}●${ConsoleUtils.reset}'
        : '${ConsoleUtils.red}●${ConsoleUtils.reset}';
    final dbStatus = dbConnected ? 'Connected' : 'Not connected';
    print('  $dbIcon Database:      $dbStatus');

    if (memory != null) {
      print('');
      ConsoleUtils.subHeader('Memory');
      final heapUsed = memory['heapUsed'] as int? ?? 0;
      final heapTotal = memory['heapTotal'] as int? ?? 0;
      print('  ${ConsoleUtils.gray}○${ConsoleUtils.reset} Heap used:     ${_formatBytes(heapUsed)}');
      print('  ${ConsoleUtils.gray}○${ConsoleUtils.reset} Heap total:    ${_formatBytes(heapTotal)}');
    }

    // Registered resources list
    final resourceList = data['resourceList'] as List<dynamic>?;
    if (resourceList != null && resourceList.isNotEmpty) {
      print('');
      ConsoleUtils.subHeader('Registered Resources');
      for (final resource in resourceList) {
        final name = resource['name'] as String? ?? 'Unknown';
        final slug = resource['slug'] as String? ?? '';
        print('  ${ConsoleUtils.gray}○${ConsoleUtils.reset} $name ${ConsoleUtils.gray}(/$slug)${ConsoleUtils.reset}');
      }
    }

    print('');
  }

  void _printOfflineStatus(String serverUrl, String error) {
    print('  ${ConsoleUtils.red}●${ConsoleUtils.reset} Status:        Offline');
    print('  ${ConsoleUtils.gray}○${ConsoleUtils.reset} URL:           $serverUrl');
    print('');
    ConsoleUtils.error('Cannot connect to server');
    print('  ${ConsoleUtils.gray}$error${ConsoleUtils.reset}');
    print('');
  }

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

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
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
