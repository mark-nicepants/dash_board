import 'dart:io';

import 'package:dash_board/dash_board.dart';
import 'package:dash_cli/src/commands/base_command.dart';
import 'package:dash_cli/src/commands/completion_configuration.dart';
import 'package:dash_cli/src/commands/dcli_argument.dart';
import 'package:dash_cli/src/utils/console_utils.dart';

/// Clear all data from database tables.
///
/// Usage:
///   dcli db:clear [options]
///
/// Options:
///   -d, --database    Path to database file
///   -t, --table       Clear only specific table
///   --force           Skip confirmation prompt
class DbClearCommand extends BaseCommand with DatabaseCommandMixin {
  DbClearCommand() {
    DcliArgument.addToParser(argParser, _arguments);
  }

  /// Unified argument definitions.
  static final _arguments = [
    DcliArgument.option(
      name: 'database',
      abbr: 'd',
      help: 'Path to database file',
      completionType: CompletionType.file,
      filePattern: '*.db',
    ),
    DcliArgument.option(
      name: 'table',
      abbr: 't',
      help: 'Clear only specific table',
      completionType: CompletionType.table,
    ),
    DcliArgument.flag(name: 'force', abbr: 'f', help: 'Skip confirmation prompt'),
  ];

  @override
  final String name = 'db:clear';

  @override
  final String description = 'Clear all data from database tables (keeps table structure)';

  @override
  final List<String> aliases = ['clear'];

  @override
  Future<int> run() async {
    final specificTable = argResults!['table'] as String?;
    final force = argResults!['force'] as bool;

    ConsoleUtils.header('🗑️  Database Cleaner');

    // Check database exists
    if (!File(effectiveDatabasePath).existsSync()) {
      ConsoleUtils.error('Database not found: $effectiveDatabasePath');
      return 1;
    }

    try {
      final db = await getDatabase(databasePath: effectiveDatabasePath);

      // Get list of tables
      final tables = await db.getTables();

      if (tables.isEmpty) {
        ConsoleUtils.warning('No tables found in database');
        await db.close();
        return 0;
      }

      // Filter to specific table if provided
      final tablesToClear = specificTable != null ? tables.where((t) => t == specificTable).toList() : tables;

      if (tablesToClear.isEmpty) {
        ConsoleUtils.error('Table "$specificTable" not found');
        print('');
        print('Available tables:');
        for (final t in tables) {
          print('  • $t');
        }
        await db.close();
        return 1;
      }

      // Show what will be cleared
      ConsoleUtils.info('Database: $effectiveDatabasePath (${config.databaseDriver})');
      print('');
      print('Tables to clear:');

      var totalRows = 0;
      final rowCounts = <String, int>{};
      for (final tableName in tablesToClear) {
        final rows = await db.getRowCount(tableName);
        rowCounts[tableName] = rows;
        totalRows += rows;
        print('  • $tableName ($rows rows)');
      }
      print('');
      print('${ConsoleUtils.yellow}Total: $totalRows rows will be deleted${ConsoleUtils.reset}');
      print('');

      // Confirm unless --force
      if (!force) {
        final confirmed = ConsoleUtils.confirm('Are you sure you want to delete all data?');
        if (!confirmed) {
          print('');
          ConsoleUtils.info('Operation cancelled');
          await db.close();
          return 0;
        }
      }

      print('');

      // Disable foreign key checks
      await db.disableForeignKeys();

      // Clear tables
      var clearedRows = 0;
      for (final tableName in tablesToClear) {
        try {
          final rowsBefore = rowCounts[tableName] ?? 0;
          await db.execute('DELETE FROM "$tableName"');
          clearedRows += rowsBefore;
          ConsoleUtils.success('Cleared $tableName ($rowsBefore rows)');
        } catch (e) {
          ConsoleUtils.error('Failed to clear $tableName: $e');
        }
      }

      // Re-enable foreign key checks and vacuum
      await db.enableForeignKeys();
      await db.vacuum();

      await db.close();

      print('');
      ConsoleUtils.line();
      ConsoleUtils.success('Cleared $clearedRows total rows from ${tablesToClear.length} table(s)');
      print('');

      return 0;
    } catch (e) {
      ConsoleUtils.error('Database error: $e');
      return 1;
    }
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
