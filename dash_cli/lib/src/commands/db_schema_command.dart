import 'dart:io';

import 'package:dash_board/dash_board.dart';
import 'package:dash_cli/src/commands/base_command.dart';
import 'package:dash_cli/src/commands/completion_configuration.dart';
import 'package:dash_cli/src/commands/dcli_argument.dart';
import 'package:dash_cli/src/utils/console_utils.dart';

/// Display database table schemas.
///
/// Usage:
///   dcli db:schema [options]
///
/// Options:
///   -d, --database    Path to database file
///   -t, --table       Show only specific table
class DbSchemaCommand extends BaseCommand with DatabaseCommandMixin {
  DbSchemaCommand() {
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
      help: 'Show schema for specific table only',
      completionType: CompletionType.table,
    ),
    DcliArgument.flag(name: 'compact', abbr: 'c', help: 'Show compact output without column details'),
  ];

  @override
  final String name = 'db:schema';

  @override
  final String description = 'Display database table schemas';

  @override
  final List<String> aliases = ['schema'];

  @override
  Future<int> run() async {
    final specificTable = argResults!['table'] as String?;
    final compact = argResults!['compact'] as bool;

    ConsoleUtils.header('📊 Database Schema');

    // Check if database exists
    if (!File(effectiveDatabasePath).existsSync()) {
      ConsoleUtils.error('Database not found: $effectiveDatabasePath');
      print('');
      print('Make sure the database file exists. Run your Dash server first to create it.');
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

      ConsoleUtils.info('Database: $effectiveDatabasePath (${config.databaseDriver})');
      ConsoleUtils.info('Tables: ${tables.length}');
      print('');

      for (final tableName in tables) {
        // Filter by specific table if provided
        if (specificTable != null && tableName != specificTable) {
          continue;
        }

        // Get row count
        final rowCount = await db.getRowCount(tableName);

        // Get table info (columns)
        final columns = await db.getTableInfo(tableName);

        // Print table header
        print(
          '${ConsoleUtils.bold}${ConsoleUtils.cyan}$tableName${ConsoleUtils.reset} '
          '${ConsoleUtils.gray}($rowCount rows)${ConsoleUtils.reset}',
        );

        if (!compact) {
          // Print column details
          final widths = [25, 15, 8, 10, 15];

          print('${ConsoleUtils.gray}${'─' * 75}${ConsoleUtils.reset}');
          ConsoleUtils.tableRow(['Column', 'Type', 'Null', 'Primary', 'Default'], widths);
          print('${ConsoleUtils.gray}${'─' * 75}${ConsoleUtils.reset}');

          for (final col in columns) {
            final name = col['name'] as String;
            final type = col['type'] as String;
            final nullable = col['nullable'] as bool;
            final pk = col['primaryKey'] as bool;
            final defaultValue = col['defaultValue'];

            final nullStr = nullable ? 'YES' : 'NO';
            final pkStr = pk ? '✓ PK' : '';
            final defaultStr = defaultValue?.toString() ?? '';

            ConsoleUtils.tableRow([name, type, nullStr, pkStr, defaultStr], widths);
          }

          // Get indexes
          final indexes = await db.getIndexes(tableName);
          if (indexes.isNotEmpty) {
            print('${ConsoleUtils.gray}  Indexes:${ConsoleUtils.reset}');
            for (final idx in indexes) {
              final indexName = idx['name'] as String;
              final unique = idx['unique'] as bool;
              final uniqueStr = unique ? ' (UNIQUE)' : '';
              final indexCols = (idx['columns'] as List).join(', ');
              print('    • $indexName: $indexCols$uniqueStr');
            }
          }

          // Get foreign keys
          final foreignKeys = await db.getForeignKeys(tableName);
          if (foreignKeys.isNotEmpty) {
            print('${ConsoleUtils.gray}  Foreign Keys:${ConsoleUtils.reset}');
            for (final fk in foreignKeys) {
              final from = fk['from'] as String;
              final toTable = fk['table'] as String;
              final to = fk['to'] as String;
              print('    • $from → $toTable($to)');
            }
          }

          print('');
        } else {
          // Compact mode: just list columns
          final colNames = columns.map((c) => c['name'] as String).join(', ');
          print('  ${ConsoleUtils.gray}$colNames${ConsoleUtils.reset}');
          print('');
        }
      }

      // If specific table was requested but not found
      if (specificTable != null && !tables.contains(specificTable)) {
        ConsoleUtils.error('Table "$specificTable" not found');
        print('');
        print('Available tables:');
        for (final t in tables) {
          print('  • $t');
        }
        await db.close();
        return 1;
      }

      await db.close();
      return 0;
    } catch (e) {
      ConsoleUtils.error('Failed to read database: $e');
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
