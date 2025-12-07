import 'package:dash/dash.dart';
import 'package:dash/src/database/connectors/sqlite/sqlite_migration_builder.dart';
import 'package:test/test.dart';

void main() {
  group('MigrationBuilder', () {
    late SqliteMigrationBuilder builder;

    setUp(() {
      builder = SqliteMigrationBuilder();
    });

    test('builds CREATE TABLE statement with primary key', () {
      final schema = const TableSchema(
        name: 'users',
        columns: [
          ColumnDefinition(name: 'id', type: ColumnType.integer, isPrimaryKey: true, autoIncrement: true),
          ColumnDefinition(name: 'name', type: ColumnType.text, nullable: false),
          ColumnDefinition(name: 'email', type: ColumnType.text, nullable: false, unique: true),
        ],
      );

      final sql = builder.buildCreateTable(schema);

      expect(sql, contains('CREATE TABLE IF NOT EXISTS users'));
      expect(sql, contains('id INTEGER PRIMARY KEY AUTOINCREMENT'));
      expect(sql, contains('name TEXT NOT NULL'));
      expect(sql, contains('email TEXT NOT NULL UNIQUE'));
    });

    test('builds CREATE TABLE with default values', () {
      final schema = const TableSchema(
        name: 'posts',
        columns: [
          ColumnDefinition(name: 'id', type: ColumnType.integer, isPrimaryKey: true, autoIncrement: true),
          ColumnDefinition(name: 'status', type: ColumnType.text, defaultValue: 'draft'),
          ColumnDefinition(name: 'views', type: ColumnType.integer, defaultValue: 0),
          ColumnDefinition(name: 'published', type: ColumnType.boolean, defaultValue: false),
        ],
      );

      final sql = builder.buildCreateTable(schema);

      expect(sql, contains("status TEXT DEFAULT 'draft'"));
      expect(sql, contains('views INTEGER DEFAULT 0'));
      expect(sql, contains('published INTEGER DEFAULT 0'));
    });

    test('builds ADD COLUMN statement', () {
      const column = ColumnDefinition(name: 'age', type: ColumnType.integer, nullable: true);

      final sql = builder.buildAddColumn('users', column);

      expect(sql, equals('ALTER TABLE users ADD COLUMN   age INTEGER'));
    });

    test('builds multiple ADD COLUMN statements', () {
      const columns = [
        ColumnDefinition(name: 'age', type: ColumnType.integer),
        ColumnDefinition(name: 'bio', type: ColumnType.text),
      ];

      final statements = builder.buildAddColumns('users', columns);

      expect(statements.length, equals(2));
      expect(statements[0], contains('ALTER TABLE users ADD COLUMN'));
      expect(statements[0], contains('age'));
      expect(statements[1], contains('bio'));
    });

    test('handles different column types correctly', () {
      final schema = const TableSchema(
        name: 'test_types',
        columns: [
          ColumnDefinition(name: 'int_col', type: ColumnType.integer),
          ColumnDefinition(name: 'text_col', type: ColumnType.text),
          ColumnDefinition(name: 'real_col', type: ColumnType.real),
          ColumnDefinition(name: 'blob_col', type: ColumnType.blob),
          ColumnDefinition(name: 'bool_col', type: ColumnType.boolean),
          ColumnDefinition(name: 'datetime_col', type: ColumnType.datetime),
        ],
      );

      final sql = builder.buildCreateTable(schema);

      expect(sql, contains('int_col INTEGER'));
      expect(sql, contains('text_col TEXT'));
      expect(sql, contains('real_col REAL'));
      expect(sql, contains('blob_col BLOB'));
      expect(sql, contains('bool_col INTEGER')); // Boolean maps to INTEGER
      expect(sql, contains('datetime_col TEXT')); // DateTime maps to TEXT
    });

    test('escapes single quotes in default string values', () {
      final schema = const TableSchema(
        name: 'tests',
        columns: [
          ColumnDefinition(name: 'id', type: ColumnType.integer, isPrimaryKey: true),
          ColumnDefinition(name: 'message', type: ColumnType.text, defaultValue: "It's a test"),
        ],
      );

      final sql = builder.buildCreateTable(schema);

      expect(sql, contains("DEFAULT 'It''s a test'")); // Single quote escaped
    });
  });
}
