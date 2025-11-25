import 'package:dash/dash.dart';
import 'package:test/test.dart';

void main() {
  group('Schema Inspector (SQLite)', () {
    late SqliteConnector connector;
    late SqliteSchemaInspector inspector;

    setUp(() async {
      // Use in-memory database for testing
      connector = SqliteConnector(':memory:');
      await connector.connect();
      inspector = connector.createSchemaInspector();
    });

    tearDown(() async {
      await connector.close();
    });

    test('detects non-existent table', () async {
      final exists = await inspector.tableExists('users');
      expect(exists, isFalse);
    });

    test('detects existing table', () async {
      await connector.execute('''
        CREATE TABLE users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL
        )
      ''');

      final exists = await inspector.tableExists('users');
      expect(exists, isTrue);
    });

    test('gets list of tables', () async {
      await connector.execute('''
        CREATE TABLE users (id INTEGER PRIMARY KEY)
      ''');
      await connector.execute('''
        CREATE TABLE posts (id INTEGER PRIMARY KEY)
      ''');

      final tables = await inspector.getTables();
      expect(tables, containsAll(['users', 'posts']));
      expect(tables.length, equals(2));
    });

    test('gets table schema with columns', () async {
      await connector.execute('''
        CREATE TABLE users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          email TEXT UNIQUE,
          age INTEGER DEFAULT 0
        )
      ''');

      final schema = await inspector.getTableSchema('users');
      expect(schema, isNotNull);
      expect(schema!.name, equals('users'));
      expect(schema.columns.length, equals(4));

      final idColumn = schema.getColumn('id');
      expect(idColumn, isNotNull);
      expect(idColumn!.isPrimaryKey, isTrue);
      expect(idColumn.type, equals(ColumnType.integer));

      final nameColumn = schema.getColumn('name');
      expect(nameColumn, isNotNull);
      expect(nameColumn!.nullable, isFalse);

      final ageColumn = schema.getColumn('age');
      expect(ageColumn, isNotNull);
      expect(ageColumn!.defaultValue, isNotNull);
    });

    test('returns null for non-existent table schema', () async {
      final schema = await inspector.getTableSchema('nonexistent');
      expect(schema, isNull);
    });

    test('gets table columns', () async {
      await connector.execute('''
        CREATE TABLE posts (
          id INTEGER PRIMARY KEY,
          title TEXT,
          content TEXT,
          created_at TEXT
        )
      ''');

      final columns = await inspector.getTableColumns('posts');
      expect(columns, equals(['id', 'title', 'content', 'created_at']));
    });

    test('returns empty list for non-existent table columns', () async {
      final columns = await inspector.getTableColumns('nonexistent');
      expect(columns, isEmpty);
    });

    test('parses different column types correctly', () async {
      await connector.execute('''
        CREATE TABLE test_types (
          int_col INTEGER,
          text_col TEXT,
          real_col REAL,
          blob_col BLOB,
          varchar_col VARCHAR(255),
          double_col DOUBLE
        )
      ''');

      final schema = await inspector.getTableSchema('test_types');
      expect(schema, isNotNull);

      expect(schema!.getColumn('int_col')!.type, equals(ColumnType.integer));
      expect(schema.getColumn('text_col')!.type, equals(ColumnType.text));
      expect(schema.getColumn('real_col')!.type, equals(ColumnType.real));
      expect(schema.getColumn('blob_col')!.type, equals(ColumnType.blob));
      expect(schema.getColumn('varchar_col')!.type, equals(ColumnType.text));
      expect(schema.getColumn('double_col')!.type, equals(ColumnType.real));
    });
  });
}
