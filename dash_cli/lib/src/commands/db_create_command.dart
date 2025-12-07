import 'dart:io';

import 'package:dash_panel_cli/src/commands/base_command.dart';
import 'package:dash_panel_cli/src/commands/completion_configuration.dart';
import 'package:dash_panel_cli/src/commands/dcli_argument.dart';
import 'package:dash_panel_cli/src/utils/console_utils.dart';
import 'package:dash_panel_cli/src/utils/field_generator.dart';
import 'package:dash_panel/dash_panel.dart';

/// Interactively create a single database record.
///
/// Usage:
///   dcli db:create [table] [options]
///
/// Examples:
///   dcli db:create users
///   dcli db:create posts --non-interactive
///
/// Options:
///   -d, --database         Path to database file
///   --non-interactive      Use generated values without prompting
///   -l, --list             List available tables
class DbCreateCommand extends BaseCommand with DatabaseCommandMixin {
  DbCreateCommand() {
    DcliArgument.addToParser(argParser, _arguments);
  }

  /// Unified argument definitions.
  static final _arguments = [
    // Positional
    DcliArgument.positional(
      name: 'table',
      help: 'The table to create a record in',
      completionType: CompletionType.table,
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
    DcliArgument.flag(name: 'non-interactive', abbr: 'n', help: 'Use generated values without prompting'),
    DcliArgument.flag(name: 'list', abbr: 'l', help: 'List available tables'),
    DcliArgument.flag(name: 'verbose', abbr: 'v', help: 'Show detailed output'),
  ];

  @override
  final String name = 'db:create';

  @override
  final String description = 'Interactively create a single database record';

  @override
  final List<String> aliases = ['create'];

  @override
  final String invocation = 'dcli db:create <table>';

  final FieldGenerator _fieldGenerator = FieldGenerator();

  @override
  Future<int> run() async {
    final listTables = argResults!['list'] as bool;
    final nonInteractive = argResults!['non-interactive'] as bool;
    final verbose = argResults!['verbose'] as bool;
    final rest = argResults!.rest;

    ConsoleUtils.header('✨ Create Record');

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

      // Validate table argument
      if (rest.isEmpty) {
        ConsoleUtils.error('Please specify a table to create a record in');
        print('');
        await _printAvailableTables(db, tables);
        await db.close();
        return 1;
      }

      final tableName = rest[0].toLowerCase();

      // Check if table exists (case-insensitive match)
      final matchedTable = tables.firstWhere((t) => t.toLowerCase() == tableName, orElse: () => '');

      if (matchedTable.isEmpty) {
        ConsoleUtils.error('Table not found: ${rest[0]}');
        print('');
        await _printAvailableTables(db, tables);
        await db.close();
        return 1;
      }

      // Get table columns
      final columns = await db.getTableInfo(matchedTable);
      final foreignKeys = await db.getForeignKeys(matchedTable);

      ConsoleUtils.info('Table: $matchedTable');
      ConsoleUtils.info('Database: $effectiveDatabasePath');
      print('');

      // Load foreign key values for FK columns
      final foreignKeyValues = await _loadForeignKeyValues(db, foreignKeys);

      // Collect field values
      Map<String, dynamic> data;
      if (nonInteractive) {
        data = await _generateAllValues(columns, foreignKeys, foreignKeyValues, matchedTable);
      } else {
        data = await _promptForValues(db, columns, foreignKeys, foreignKeyValues, matchedTable, verbose);
        if (data.isEmpty) {
          ConsoleUtils.info('Operation cancelled');
          await db.close();
          return 0;
        }
      }

      if (data.isEmpty) {
        ConsoleUtils.error('No data to insert');
        await db.close();
        return 1;
      }

      // Insert the record
      if (verbose) {
        print('');
        ConsoleUtils.info('Inserting data:');
        for (final entry in data.entries) {
          final displayValue = entry.key.toLowerCase().contains('password') ? '********' : entry.value.toString();
          print('  ${entry.key}: $displayValue');
        }
      }

      final insertedId = await db.insert(matchedTable, data);
      await db.close();

      print('');
      ConsoleUtils.line();
      ConsoleUtils.success('Created record #$insertedId in $matchedTable');
      print('');

      // Show the created record
      if (!nonInteractive || verbose) {
        _printCreatedRecord(data, insertedId, matchedTable);
      }

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
    print('Usage: dcli db:create <table>');
  }

  Future<Map<String, List<dynamic>>> _loadForeignKeyValues(
    DatabaseConnector db,
    List<Map<String, dynamic>> foreignKeys,
  ) async {
    final foreignKeyValues = <String, List<dynamic>>{};

    for (final fk in foreignKeys) {
      final fromColumn = fk['from'] as String;
      final toTable = fk['table'] as String;
      final toColumn = fk['to'] as String;

      try {
        final values = await db.getColumnValues(toTable, toColumn);
        if (values.isNotEmpty) {
          foreignKeyValues[fromColumn] = values;
        }
      } catch (_) {
        // Table might not exist
      }
    }

    return foreignKeyValues;
  }

  Future<Map<String, dynamic>> _generateAllValues(
    List<Map<String, dynamic>> columns,
    List<Map<String, dynamic>> foreignKeys,
    Map<String, List<dynamic>> foreignKeyValues,
    String tableName,
  ) async {
    final data = <String, dynamic>{};
    final fkColumns = foreignKeys.map((fk) => fk['from'] as String).toSet();

    for (final column in columns) {
      final columnName = column['name'] as String;
      final isPrimaryKey = column['primaryKey'] as bool? ?? false;

      // Skip primary keys
      if (isPrimaryKey) continue;

      // Skip timestamp fields
      if (_isTimestampColumn(columnName)) continue;

      // Handle foreign keys
      if (fkColumns.contains(columnName)) {
        final fkValues = foreignKeyValues[columnName];
        if (fkValues != null && fkValues.isNotEmpty) {
          data[columnName] = fkValues[0]; // Use first available
        }
        continue;
      }

      // Generate value
      final value = _fieldGenerator.generateValueForColumn(column, tableName, hashPasswords: true);
      if (value != null) {
        data[columnName] = value;
      }
    }

    return data;
  }

  Future<Map<String, dynamic>> _promptForValues(
    DatabaseConnector db,
    List<Map<String, dynamic>> columns,
    List<Map<String, dynamic>> foreignKeys,
    Map<String, List<dynamic>> foreignKeyValues,
    String tableName,
    bool verbose,
  ) async {
    final data = <String, dynamic>{};
    final fkColumns = foreignKeys.map((fk) => fk['from'] as String).toSet();
    final fkInfo = {for (var fk in foreignKeys) fk['from'] as String: fk};

    print('${ConsoleUtils.gray}Enter values for each field (press Enter for generated default):${ConsoleUtils.reset}');
    print('${ConsoleUtils.gray}Type "cancel" to abort.${ConsoleUtils.reset}');
    print('');

    for (final column in columns) {
      final columnName = column['name'] as String;
      final isPrimaryKey = column['primaryKey'] as bool? ?? false;
      final nullable = column['nullable'] as bool? ?? true;

      // Skip primary keys
      if (isPrimaryKey) continue;

      // Skip timestamp fields
      if (_isTimestampColumn(columnName)) continue;

      // Handle foreign keys
      if (fkColumns.contains(columnName)) {
        final fkValues = foreignKeyValues[columnName];
        final fk = fkInfo[columnName]!;
        final refTable = fk['table'] as String;
        final value = await _promptForeignKey(columnName, refTable, fkValues);
        if (value == 'cancel') return {};
        if (value != null) {
          data[columnName] = value;
        }
        continue;
      }

      // Prompt for regular fields
      final value = await _promptColumn(column, tableName, nullable);
      if (value == 'cancel') return {};
      if (value != null) {
        data[columnName] = value;
      } else if (!nullable && column['defaultValue'] == null) {
        // Required field with no value - generate one
        final generated = _fieldGenerator.generateValueForColumn(column, tableName, hashPasswords: true);
        if (generated != null) {
          data[columnName] = generated;
        }
      }
    }

    return data;
  }

  Future<dynamic> _promptColumn(Map<String, dynamic> column, String tableName, bool nullable) async {
    final columnName = column['name'] as String;
    final columnType = column['type'] as String? ?? 'TEXT';
    final isPassword = columnName.toLowerCase().contains('password');
    final defaultValue = _fieldGenerator.generateDefaultForColumnPrompt(column);

    // Build prompt string
    final buffer = StringBuffer();
    buffer.write('${ConsoleUtils.cyan}$columnName${ConsoleUtils.reset}');
    buffer.write(' ${ConsoleUtils.gray}($columnType');
    if (!nullable) buffer.write(', required');
    buffer.write(')${ConsoleUtils.reset}');

    if (defaultValue.isNotEmpty && !isPassword) {
      final displayDefault = defaultValue.length > 30 ? '${defaultValue.substring(0, 27)}...' : defaultValue;
      buffer.write(' [${ConsoleUtils.gray}$displayDefault${ConsoleUtils.reset}]');
    }
    buffer.write(': ');

    stdout.write(buffer.toString());
    final input = stdin.readLineSync() ?? '';

    if (input.toLowerCase() == 'cancel') {
      return 'cancel';
    }

    if (input.isEmpty) {
      // Use generated value
      return _fieldGenerator.generateValueForColumn(column, tableName, hashPasswords: true);
    }

    // Parse the input
    return _fieldGenerator.parseInputForColumn(input, column, hashPasswords: true);
  }

  Future<dynamic> _promptForeignKey(String columnName, String refTable, List<dynamic>? availableValues) async {
    final buffer = StringBuffer();
    buffer.write('${ConsoleUtils.cyan}$columnName${ConsoleUtils.reset}');
    buffer.write(' ${ConsoleUtils.gray}(foreign key to $refTable)${ConsoleUtils.reset}');

    if (availableValues != null && availableValues.isNotEmpty) {
      buffer.write(' ${ConsoleUtils.gray}[available: ${availableValues.take(5).join(', ')}');
      if (availableValues.length > 5) {
        buffer.write('...');
      }
      buffer.write(']${ConsoleUtils.reset}');
    }
    buffer.write(': ');

    stdout.write(buffer.toString());
    final input = stdin.readLineSync() ?? '';

    if (input.toLowerCase() == 'cancel') {
      return 'cancel';
    }

    if (input.isEmpty) {
      // Use first available value or null
      return availableValues?.firstOrNull;
    }

    return int.tryParse(input) ?? input;
  }

  bool _isTimestampColumn(String name) {
    final lower = name.toLowerCase();
    return lower == 'created_at' || lower == 'updated_at' || lower == 'deleted_at';
  }

  void _printCreatedRecord(Map<String, dynamic> data, int id, String tableName) {
    print('');
    print('${ConsoleUtils.bold}Created Record in $tableName:${ConsoleUtils.reset}');
    print('  id: $id');
    for (final entry in data.entries) {
      final displayValue = entry.key.toLowerCase().contains('password') ? '********' : entry.value.toString();
      // Truncate long values
      final truncated = displayValue.length > 50 ? '${displayValue.substring(0, 47)}...' : displayValue;
      print('  ${entry.key}: $truncated');
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
