import 'dart:io';

import 'package:dash_cli/src/utils/field_generator.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  group('DbCreateCommand', () {
    group('Database Table Discovery', () {
      late Directory tempDir;
      late String dbPath;

      setUp(() {
        tempDir = Directory.systemTemp.createTempSync('dash_cli_db_create_test_');
        dbPath = '${tempDir.path}/test.db';

        // Create a test database with multiple tables
        final db = sqlite3.open(dbPath);

        db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT NOT NULL UNIQUE,
            password TEXT,
            is_active INTEGER DEFAULT 1,
            created_at TEXT,
            updated_at TEXT
          )
        ''');

        db.execute('''
          CREATE TABLE posts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            content TEXT,
            user_id INTEGER NOT NULL,
            created_at TEXT,
            FOREIGN KEY (user_id) REFERENCES users(id)
          )
        ''');

        db.execute('''
          CREATE TABLE permissions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            slug TEXT NOT NULL UNIQUE,
            description TEXT,
            created_at TEXT,
            updated_at TEXT
          )
        ''');

        db.execute('''
          CREATE TABLE roles (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            slug TEXT NOT NULL UNIQUE,
            description TEXT,
            is_default INTEGER,
            created_at TEXT,
            updated_at TEXT
          )
        ''');

        // Insert some test data
        db.execute("INSERT INTO users (name, email, password) VALUES ('Test User', 'test@example.com', 'hash')");

        db.close();
      });

      tearDown(() {
        tempDir.deleteSync(recursive: true);
      });

      test('finds all tables in database', () {
        final db = sqlite3.open(dbPath);
        final tables = db.select(
          "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name",
        );

        expect(tables.length, equals(4));
        expect(tables.map((t) => t['name']), containsAll(['users', 'posts', 'permissions', 'roles']));

        db.close();
      });

      test('gets column info for table', () {
        final db = sqlite3.open(dbPath);
        final columns = db.select('PRAGMA table_info("users")');

        expect(columns.length, equals(7));

        final names = columns.map((c) => c['name'] as String).toList();
        expect(names, containsAll(['id', 'name', 'email', 'password', 'is_active', 'created_at', 'updated_at']));

        // Check primary key
        final idCol = columns.firstWhere((c) => c['name'] == 'id');
        expect(idCol['pk'], equals(1));

        db.close();
      });

      test('gets foreign key info for table', () {
        final db = sqlite3.open(dbPath);
        final foreignKeys = db.select('PRAGMA foreign_key_list("posts")');

        expect(foreignKeys.length, equals(1));
        expect(foreignKeys.first['from'], equals('user_id'));
        expect(foreignKeys.first['table'], equals('users'));
        expect(foreignKeys.first['to'], equals('id'));

        db.close();
      });

      test('table without foreign keys returns empty list', () {
        final db = sqlite3.open(dbPath);
        final foreignKeys = db.select('PRAGMA foreign_key_list("permissions")');

        expect(foreignKeys, isEmpty);

        db.close();
      });
    });

    group('FieldGenerator for Columns', () {
      late FieldGenerator generator;

      setUp(() {
        generator = FieldGenerator();
      });

      test('generates string value for TEXT column', () {
        final column = {'name': 'email', 'type': 'TEXT', 'primaryKey': false};
        final value = generator.generateValueForColumn(column, 'users');

        expect(value, isA<String>());
        expect(value, contains('@')); // Email should have @
      });

      test('generates integer value for INTEGER column', () {
        final column = {'name': 'count', 'type': 'INTEGER', 'primaryKey': false};
        final value = generator.generateValueForColumn(column, 'users');

        expect(value, isA<int>());
      });

      test('generates boolean-like integer for is_active column', () {
        final column = {'name': 'is_active', 'type': 'INTEGER', 'primaryKey': false};
        final value = generator.generateValueForColumn(column, 'users');

        expect(value, anyOf(0, 1));
      });

      test('skips primary key columns', () {
        final column = {'name': 'id', 'type': 'INTEGER', 'primaryKey': true};
        final value = generator.generateValueForColumn(column, 'users');

        expect(value, isNull);
      });

      test('skips timestamp columns', () {
        for (final colName in ['created_at', 'updated_at', 'deleted_at']) {
          final column = {'name': colName, 'type': 'TEXT', 'primaryKey': false};
          final value = generator.generateValueForColumn(column, 'users');

          expect(value, isNull, reason: '$colName should be skipped');
        }
      });

      test('generates name for name column', () {
        final column = {'name': 'name', 'type': 'TEXT', 'primaryKey': false};
        final value = generator.generateValueForColumn(column, 'users');

        expect(value, isA<String>());
        expect(value.toString().isNotEmpty, isTrue);
      });

      test('generates slug for slug column', () {
        final column = {'name': 'slug', 'type': 'TEXT', 'primaryKey': false};
        final value = generator.generateValueForColumn(column, 'roles');

        expect(value, isA<String>());
        expect(value, matches(RegExp(r'^[a-z0-9-]+$'))); // Only lowercase, numbers, hyphens
      });

      test('identifies foreign key columns', () {
        expect(generator.isForeignKeyColumn('user_id'), isTrue);
        expect(generator.isForeignKeyColumn('post_id'), isTrue);
        expect(generator.isForeignKeyColumn('id'), isFalse);
        expect(generator.isForeignKeyColumn('email'), isFalse);
        expect(generator.isForeignKeyColumn('name_id'), isTrue);
      });
    });

    group('FieldGenerator parseInputForColumn', () {
      late FieldGenerator generator;

      setUp(() {
        generator = FieldGenerator();
      });

      test('parses integer input', () {
        final column = {'name': 'count', 'type': 'INTEGER'};
        expect(generator.parseInputForColumn('42', column), equals(42));
        expect(generator.parseInputForColumn('invalid', column), isNull);
      });

      test('parses boolean-like input for is_active', () {
        final column = {'name': 'is_active', 'type': 'INTEGER'};
        expect(generator.parseInputForColumn('true', column), equals(1));
        expect(generator.parseInputForColumn('yes', column), equals(1));
        expect(generator.parseInputForColumn('false', column), equals(0));
        expect(generator.parseInputForColumn('no', column), equals(0));
      });

      test('parses text input', () {
        final column = {'name': 'name', 'type': 'TEXT'};
        expect(generator.parseInputForColumn('John Doe', column), equals('John Doe'));
      });

      test('returns null for empty input', () {
        final column = {'name': 'name', 'type': 'TEXT'};
        expect(generator.parseInputForColumn('', column), isNull);
      });
    });

    group('Table Name Matching', () {
      test('table lookup is case-insensitive', () {
        final tables = ['users', 'posts', 'permissions', 'roles'];

        // Test matching function
        String? findTable(String input) {
          return tables.firstWhere((t) => t.toLowerCase() == input.toLowerCase(), orElse: () => '');
        }

        expect(findTable('users'), equals('users'));
        expect(findTable('USERS'), equals('users'));
        expect(findTable('Users'), equals('users'));
        expect(findTable('permissions'), equals('permissions'));
        expect(findTable('Permissions'), equals('permissions'));
        expect(findTable('nonexistent'), equals(''));
      });
    });
  });
}
