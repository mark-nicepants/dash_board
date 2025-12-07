import 'dart:io';
import 'dart:math';

import 'package:dash_board/dash_board.dart';
import 'package:dash_cli/src/commands/base_command.dart';
import 'package:dash_cli/src/commands/completion_configuration.dart';
import 'package:dash_cli/src/commands/dcli_argument.dart';
import 'package:dash_cli/src/utils/console_utils.dart';
import 'package:dash_cli/src/utils/field_generator.dart';

/// Seed the database with fake data.
///
/// Usage:
///   dcli db:seed table [count] [options]
///
/// Examples:
///   dcli db:seed users 100
///   dcli db:seed posts 50 --database storage/app.db
///
/// Options:
///   -d, --database    Path to database file
class DbSeedCommand extends BaseCommand with DatabaseCommandMixin {
  DbSeedCommand() {
    DcliArgument.addToParser(argParser, _arguments);
  }

  /// Unified argument definitions for both argParser and completion.
  static final _arguments = [
    // Positional arguments
    DcliArgument.positional(
      name: 'table',
      help: 'Table name to seed (e.g., users, posts)',
      completionType: CompletionType.table,
    ),
    DcliArgument.positional(
      name: 'count',
      help: 'Number of records to create (default: 10)',
      completionType: CompletionType.number,
    ),
    // Options
    DcliArgument.option(
      name: 'database',
      abbr: 'd',
      help: 'Path to database file',
      completionType: CompletionType.file,
      filePattern: '*.db',
    ),
    // Flags
    DcliArgument.flag(name: 'verbose', abbr: 'v', help: 'Show detailed output'),
    DcliArgument.flag(name: 'list', abbr: 'l', help: 'List available tables to seed'),
  ];

  @override
  final String name = 'db:seed';

  @override
  final String description = 'Seed the database with fake data';

  @override
  final List<String> aliases = ['seed'];

  @override
  final String invocation = 'dcli db:seed <table> [count]';

  final _fieldGenerator = FieldGenerator();
  final _random = Random();

  @override
  Future<int> run() async {
    final verbose = argResults!['verbose'] as bool;
    final listTables = argResults!['list'] as bool;

    // Parse positional arguments
    final rest = argResults!.rest;

    ConsoleUtils.header('🌱 Database Seeder');

    // Check database exists
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

      // List tables mode
      if (listTables) {
        await _printAvailableTables(db, tables);
        await db.close();
        return 0;
      }

      // Validate arguments
      if (rest.isEmpty) {
        ConsoleUtils.error('Please specify a table to seed');
        print('');
        await _printAvailableTables(db, tables);
        await db.close();
        return 1;
      }

      final tableName = rest[0].toLowerCase();
      final count = rest.length > 1 ? int.tryParse(rest[1]) ?? 10 : 10;

      // Check if table exists (case-insensitive match)
      final matchedTable = tables.firstWhere((t) => t.toLowerCase() == tableName, orElse: () => '');

      if (matchedTable.isEmpty) {
        ConsoleUtils.error('Table not found: ${rest[0]}');
        print('');
        await _printAvailableTables(db, tables);
        await db.close();
        return 1;
      }

      // Get table info
      final columns = await db.getTableInfo(matchedTable);
      final foreignKeys = await db.getForeignKeys(matchedTable);

      ConsoleUtils.info('Table: $matchedTable');
      ConsoleUtils.info('Database: $effectiveDatabasePath (${config.databaseDriver})');
      ConsoleUtils.info('Count: $count');
      print('');

      // Get existing foreign key values
      final foreignKeyValues = await _loadForeignKeyValues(db, foreignKeys);

      // Disable foreign key checks during bulk insert
      await db.disableForeignKeys();

      // Generate and insert records
      var inserted = 0;
      final startTime = DateTime.now();
      final fkColumns = foreignKeys.map((fk) => fk['from'] as String).toSet();

      for (var i = 0; i < count; i++) {
        final data = _generateFakeData(columns, fkColumns, foreignKeyValues, matchedTable);

        if (data.isEmpty) continue;

        try {
          final lastId = await db.insert(matchedTable, data);
          inserted++;

          if (verbose) {
            ConsoleUtils.success('Created record #$lastId');
          } else {
            ConsoleUtils.progressBar(i + 1, count, prefix: 'Seeding');
          }
        } catch (e) {
          if (verbose) {
            ConsoleUtils.error('Failed to insert record: $e');
          }
        }
      }

      // Re-enable foreign key checks
      await db.enableForeignKeys();

      final duration = DateTime.now().difference(startTime);
      await db.close();

      print('');
      ConsoleUtils.line();
      ConsoleUtils.success(
        'Inserted $inserted record(s) into $matchedTable in ${ConsoleUtils.formatDuration(duration)}',
      );
      print('');

      return 0;
    } catch (e) {
      ConsoleUtils.error('Database error: $e');
      return 1;
    }
  }

  Future<void> _printAvailableTables(DatabaseConnector db, List<String> tables) async {
    ConsoleUtils.info('Available tables:');
    print('');
    for (final tableName in tables) {
      final rowCount = await db.getRowCount(tableName);
      final columns = await db.getTableInfo(tableName);
      final columnCount = columns.where((c) => c['primaryKey'] != true).length;
      print(
        '  ${ConsoleUtils.cyan}$tableName${ConsoleUtils.reset} '
        '${ConsoleUtils.gray}($columnCount columns, $rowCount rows)${ConsoleUtils.reset}',
      );
    }
    print('');
    print('Usage: dcli db:seed <table> [count]');
  }

  Future<Map<String, List<int>>> _loadForeignKeyValues(
    DatabaseConnector db,
    List<Map<String, dynamic>> foreignKeys,
  ) async {
    final foreignKeyValues = <String, List<int>>{};

    for (final fk in foreignKeys) {
      final fromColumn = fk['from'] as String;
      final toTable = fk['table'] as String;
      final toColumn = fk['to'] as String;

      try {
        final rows = await db.query('SELECT "$toColumn" FROM "$toTable" LIMIT 1000');
        if (rows.isNotEmpty) {
          foreignKeyValues[fromColumn] = rows.map((r) => r[toColumn] as int).toList();
        }
      } catch (_) {
        // Table might not exist or have different structure
      }
    }

    return foreignKeyValues;
  }

  Map<String, dynamic> _generateFakeData(
    List<Map<String, dynamic>> columns,
    Set<String> fkColumns,
    Map<String, List<int>> foreignKeyValues,
    String tableName,
  ) {
    final data = <String, dynamic>{};

    for (final column in columns) {
      final columnName = column['name'] as String;
      final isPrimaryKey = column['primaryKey'] as bool? ?? false;
      final nullable = column['nullable'] as bool? ?? true;

      // Skip primary keys (auto-increment)
      if (isPrimaryKey) continue;

      // Skip timestamp fields (let DB handle them)
      if (_isTimestampColumn(columnName)) continue;

      // Handle foreign keys
      if (fkColumns.contains(columnName)) {
        final fkValues = foreignKeyValues[columnName];
        if (fkValues != null && fkValues.isNotEmpty) {
          data[columnName] = fkValues[_random.nextInt(fkValues.length)];
        } else if (!nullable) {
          // Skip record if required FK has no values
          return {};
        }
        continue;
      }

      // Handle nullable fields - sometimes generate null
      if (nullable && _random.nextDouble() < 0.1) {
        continue; // Skip (will be null)
      }

      // Generate value
      final value = _fieldGenerator.generateValueForColumn(column, tableName, hashPasswords: true);
      if (value != null) {
        data[columnName] = value;
      }
    }

    return data;
  }

  bool _isTimestampColumn(String name) {
    final lower = name.toLowerCase();
    return lower == 'created_at' || lower == 'updated_at' || lower == 'deleted_at';
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
