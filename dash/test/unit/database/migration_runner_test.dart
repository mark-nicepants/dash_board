import 'package:dash_board/src/database/connectors/sqlite/sqlite_connector.dart';
import 'package:dash_board/src/database/connectors/sqlite/sqlite_migration_builder.dart';
import 'package:dash_board/src/database/migrations/migration_runner.dart';
import 'package:dash_board/src/database/migrations/schema_definition.dart';
import 'package:test/test.dart';

void main() {
  group('Migration Runner', () {
    late SqliteConnector connector;
    late MigrationRunner runner;

    setUp(() async {
      connector = SqliteConnector(':memory:');
      await connector.connect();

      final inspector = connector.createSchemaInspector();
      final builder = SqliteMigrationBuilder();

      runner = MigrationRunner(connector: connector, inspector: inspector, builder: builder);
    });

    tearDown(() async {
      await connector.close();
    });

    test('creates new table when it does not exist', () async {
      final schema = const TableSchema(
        name: 'users',
        columns: [
          ColumnDefinition(name: 'id', type: ColumnType.integer, isPrimaryKey: true, autoIncrement: true),
          ColumnDefinition(name: 'name', type: ColumnType.text, nullable: false),
        ],
      );

      final statements = await runner.runMigrations([schema]);

      expect(statements.length, equals(1));
      expect(statements[0], contains('CREATE TABLE'));

      // Verify table was created
      final result = await connector.query("SELECT name FROM sqlite_master WHERE type='table' AND name='users'");
      expect(result.length, equals(1));
    });

    test('adds missing columns to existing table', () async {
      // Create initial table
      await connector.execute('''
        CREATE TABLE posts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL
        )
      ''');

      // Define schema with additional columns
      final schema = const TableSchema(
        name: 'posts',
        columns: [
          ColumnDefinition(name: 'id', type: ColumnType.integer, isPrimaryKey: true, autoIncrement: true),
          ColumnDefinition(name: 'title', type: ColumnType.text, nullable: false),
          ColumnDefinition(name: 'content', type: ColumnType.text),
          ColumnDefinition(name: 'published', type: ColumnType.boolean, defaultValue: false),
        ],
      );

      final statements = await runner.runMigrations([schema]);

      expect(statements.length, equals(2)); // Two ALTER TABLE statements
      expect(statements[0], contains('ALTER TABLE posts ADD COLUMN'));
      expect(statements[0], contains('content'));
      expect(statements[1], contains('published'));

      // Verify columns were added
      final result = await connector.query('PRAGMA table_info(posts)');
      final columnNames = result.map((row) => row['name']).toList();
      expect(columnNames, containsAll(['id', 'title', 'content', 'published']));
    });

    test('does nothing when table already matches schema', () async {
      // Create table with exact schema
      await connector.execute('''
        CREATE TABLE categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          slug TEXT UNIQUE
        )
      ''');

      final schema = const TableSchema(
        name: 'categories',
        columns: [
          ColumnDefinition(name: 'id', type: ColumnType.integer, isPrimaryKey: true, autoIncrement: true),
          ColumnDefinition(name: 'name', type: ColumnType.text, nullable: false),
          ColumnDefinition(name: 'slug', type: ColumnType.text, unique: true),
        ],
      );

      final statements = await runner.runMigrations([schema]);

      expect(statements, isEmpty); // No migrations needed
    });

    test('handles multiple tables in one migration', () async {
      final schemas = [
        const TableSchema(
          name: 'users',
          columns: [
            ColumnDefinition(name: 'id', type: ColumnType.integer, isPrimaryKey: true, autoIncrement: true),
            ColumnDefinition(name: 'name', type: ColumnType.text),
          ],
        ),
        const TableSchema(
          name: 'posts',
          columns: [
            ColumnDefinition(name: 'id', type: ColumnType.integer, isPrimaryKey: true, autoIncrement: true),
            ColumnDefinition(name: 'title', type: ColumnType.text),
          ],
        ),
      ];

      final statements = await runner.runMigrations(schemas);

      expect(statements.length, equals(2)); // Two CREATE TABLE statements

      // Verify both tables were created
      final users = await connector.query("SELECT name FROM sqlite_master WHERE type='table' AND name='users'");
      final posts = await connector.query("SELECT name FROM sqlite_master WHERE type='table' AND name='posts'");

      expect(users.length, equals(1));
      expect(posts.length, equals(1));
    });

    test('needsMigration returns true for non-existent table', () async {
      final schema = const TableSchema(
        name: 'new_table',
        columns: [ColumnDefinition(name: 'id', type: ColumnType.integer, isPrimaryKey: true)],
      );

      final needs = await runner.needsMigration(schema);
      expect(needs, isTrue);
    });

    test('needsMigration returns true for missing columns', () async {
      await connector.execute('''
        CREATE TABLE items (
          id INTEGER PRIMARY KEY
        )
      ''');

      final schema = const TableSchema(
        name: 'items',
        columns: [
          ColumnDefinition(name: 'id', type: ColumnType.integer, isPrimaryKey: true),
          ColumnDefinition(name: 'name', type: ColumnType.text),
        ],
      );

      final needs = await runner.needsMigration(schema);
      expect(needs, isTrue);
    });

    test('needsMigration returns false when table matches schema', () async {
      await connector.execute('''
        CREATE TABLE complete (
          id INTEGER PRIMARY KEY,
          name TEXT
        )
      ''');

      final schema = const TableSchema(
        name: 'complete',
        columns: [
          ColumnDefinition(name: 'id', type: ColumnType.integer, isPrimaryKey: true),
          ColumnDefinition(name: 'name', type: ColumnType.text),
        ],
      );

      final needs = await runner.needsMigration(schema);
      expect(needs, isFalse);
    });

    test('getMissingColumns returns all columns for new table', () async {
      final schema = const TableSchema(
        name: 'new_table',
        columns: [
          ColumnDefinition(name: 'id', type: ColumnType.integer, isPrimaryKey: true),
          ColumnDefinition(name: 'name', type: ColumnType.text),
        ],
      );

      final missing = await runner.getMissingColumns(schema);
      expect(missing.length, equals(2));
    });

    test('getMissingColumns returns only missing columns', () async {
      await connector.execute('''
        CREATE TABLE partial (
          id INTEGER PRIMARY KEY
        )
      ''');

      final schema = const TableSchema(
        name: 'partial',
        columns: [
          ColumnDefinition(name: 'id', type: ColumnType.integer, isPrimaryKey: true),
          ColumnDefinition(name: 'name', type: ColumnType.text),
          ColumnDefinition(name: 'email', type: ColumnType.text),
        ],
      );

      final missing = await runner.getMissingColumns(schema);
      expect(missing.length, equals(2));
      expect(missing.map((c) => c.name), containsAll(['name', 'email']));
    });
  });
}
