import 'package:dash/src/database/connectors/sqlite_connector.dart';
import 'package:dash/src/database/database_connector.dart';
import 'package:dash/src/settings/settings_service.dart';
import 'package:test/test.dart';

void main() {
  late DatabaseConnector connector;
  late SettingsService settings;

  setUp(() async {
    // Use in-memory SQLite for testing
    connector = SqliteConnector(':memory:');
    await connector.connect();

    // Create the settings table
    await connector.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT NOT NULL UNIQUE,
        value TEXT,
        type TEXT NOT NULL DEFAULT 'string',
        created_at TEXT,
        updated_at TEXT
      )
    ''');
    await connector.execute('CREATE INDEX IF NOT EXISTS idx_settings_key ON settings(key)');

    settings = SettingsService(connector);
    await settings.init();
  });

  tearDown(() async {
    await connector.close();
  });

  group('SettingsService', () {
    group('schema', () {
      test('should have correct table name', () {
        expect(SettingsService.tableName, equals('settings'));
      });

      test('should have correct schema definition', () {
        final schema = SettingsService.schema;
        expect(schema.name, equals('settings'));
        expect(schema.columns.length, equals(6));
        expect(schema.columns.any((c) => c.name == 'key' && c.unique), isTrue);
        expect(schema.indexes.any((i) => i.name == 'idx_settings_key'), isTrue);
      });
    });

    group('set and get', () {
      test('should set and get a string value', () async {
        await settings.set('app.name', 'Test App');

        final result = await settings.getString('app.name');
        expect(result, equals('Test App'));
      });

      test('should set and get an int value', () async {
        await settings.set('app.port', 8080);

        final result = await settings.getInt('app.port');
        expect(result, equals(8080));
      });

      test('should set and get a double value', () async {
        await settings.set('app.rate', 0.21);

        final result = await settings.getDouble('app.rate');
        expect(result, closeTo(0.21, 0.001));
      });

      test('should set and get a bool value', () async {
        await settings.set('app.debug', true);

        final result = await settings.getBool('app.debug');
        expect(result, isTrue);
      });

      test('should set and get a bool value (false)', () async {
        await settings.set('app.maintenance', false);

        final result = await settings.getBool('app.maintenance');
        expect(result, isFalse);
      });

      test('should set and get a JSON map value', () async {
        await settings.set('app.config', {'key': 'value', 'count': 42});

        final result = await settings.getJson('app.config');
        expect(result, equals({'key': 'value', 'count': 42}));
      });

      test('should set and get a JSON list value', () async {
        await settings.set('app.features', ['feature1', 'feature2']);

        final result = await settings.getList('app.features');
        expect(result, equals(['feature1', 'feature2']));
      });

      test('should update existing value', () async {
        await settings.set('app.name', 'Old Name');
        await settings.set('app.name', 'New Name');

        final result = await settings.getString('app.name');
        expect(result, equals('New Name'));
      });
    });

    group('get with defaults', () {
      test('should return default for missing string', () async {
        final result = await settings.getString('missing.key', defaultValue: 'default');
        expect(result, equals('default'));
      });

      test('should return default for missing int', () async {
        final result = await settings.getInt('missing.key', defaultValue: 42);
        expect(result, equals(42));
      });

      test('should return default for missing bool', () async {
        final result = await settings.getBool('missing.key', defaultValue: true);
        expect(result, isTrue);
      });

      test('should return default for missing double', () async {
        final result = await settings.getDouble('missing.key', defaultValue: 3.14);
        expect(result, closeTo(3.14, 0.001));
      });

      test('should return default for missing JSON', () async {
        final result = await settings.getJson('missing.key', defaultValue: {'default': true});
        expect(result, equals({'default': true}));
      });

      test('should return default for missing list', () async {
        final result = await settings.getList('missing.key', defaultValue: ['a', 'b']);
        expect(result, equals(['a', 'b']));
      });
    });

    group('generic get', () {
      test('should get string value with generic method', () async {
        await settings.set('test.key', 'value');

        final result = await settings.get<String>('test.key');
        expect(result, equals('value'));
      });

      test('should get int value with generic method', () async {
        await settings.set('test.key', 123);

        final result = await settings.get<int>('test.key');
        expect(result, equals(123));
      });

      test('should return default for wrong type', () async {
        await settings.set('test.key', 'string value');

        final result = await settings.get<int>('test.key', defaultValue: 99);
        expect(result, equals(99));
      });
    });

    group('has', () {
      test('should return true for existing key', () async {
        await settings.set('app.name', 'Test');

        final result = await settings.has('app.name');
        expect(result, isTrue);
      });

      test('should return false for missing key', () async {
        final result = await settings.has('missing.key');
        expect(result, isFalse);
      });
    });

    group('delete', () {
      test('should delete existing setting', () async {
        await settings.set('app.name', 'Test');
        final deleted = await settings.delete('app.name');

        expect(deleted, isTrue);
        expect(await settings.has('app.name'), isFalse);
      });

      test('should return false for non-existing key', () async {
        final deleted = await settings.delete('missing.key');
        expect(deleted, isFalse);
      });
    });

    group('clear', () {
      test('should clear all settings', () async {
        await settings.set('app.name', 'Test');
        await settings.set('app.debug', true);
        await settings.set('mail.host', 'localhost');

        final count = await settings.clear();
        expect(count, equals(3));

        expect(await settings.has('app.name'), isFalse);
        expect(await settings.has('app.debug'), isFalse);
        expect(await settings.has('mail.host'), isFalse);
      });

      test('should clear settings by prefix', () async {
        await settings.set('app.name', 'Test');
        await settings.set('app.debug', true);
        await settings.set('mail.host', 'localhost');

        final count = await settings.clear(prefix: 'app.');
        expect(count, equals(2));

        expect(await settings.has('app.name'), isFalse);
        expect(await settings.has('app.debug'), isFalse);
        expect(await settings.has('mail.host'), isTrue);
      });
    });

    group('all', () {
      test('should return all settings', () async {
        await settings.set('app.name', 'Test');
        await settings.set('app.debug', true);
        await settings.set('mail.host', 'localhost');

        final all = await settings.all();
        expect(all.length, equals(3));
        expect(all['app.name'], equals('Test'));
        expect(all['app.debug'], isTrue);
        expect(all['mail.host'], equals('localhost'));
      });

      test('should filter by prefix', () async {
        await settings.set('app.name', 'Test');
        await settings.set('app.debug', true);
        await settings.set('mail.host', 'localhost');

        final appSettings = await settings.all(prefix: 'app.');
        expect(appSettings.length, equals(2));
        expect(appSettings['app.name'], equals('Test'));
        expect(appSettings['app.debug'], isTrue);
        expect(appSettings.containsKey('mail.host'), isFalse);
      });
    });

    group('setMany', () {
      test('should set multiple values at once', () async {
        await settings.setMany({'app.name': 'Test App', 'app.debug': true, 'app.port': 8080});

        expect(await settings.getString('app.name'), equals('Test App'));
        expect(await settings.getBool('app.debug'), isTrue);
        expect(await settings.getInt('app.port'), equals(8080));
      });
    });

    group('refresh', () {
      test('should reload cache from database', () async {
        await settings.set('app.name', 'Original');

        // Directly modify database bypassing cache
        await connector.update('settings', {'value': 'Modified'}, where: 'key = ?', whereArgs: ['app.name']);

        // Cache still has original
        expect(await settings.getString('app.name'), equals('Original'));

        // After refresh, should have new value
        await settings.refresh();
        expect(await settings.getString('app.name'), equals('Modified'));
      });
    });

    group('dot notation', () {
      test('should support nested dot notation keys', () async {
        await settings.set('mail.smtp.host', 'smtp.example.com');
        await settings.set('mail.smtp.port', 587);
        await settings.set('mail.smtp.username', 'user@example.com');

        final host = await settings.getString('mail.smtp.host');
        final port = await settings.getInt('mail.smtp.port');
        final username = await settings.getString('mail.smtp.username');

        expect(host, equals('smtp.example.com'));
        expect(port, equals(587));
        expect(username, equals('user@example.com'));
      });

      test('should filter by dot notation prefix', () async {
        await settings.set('mail.smtp.host', 'smtp.example.com');
        await settings.set('mail.smtp.port', 587);
        await settings.set('mail.sendmail.path', '/usr/sbin/sendmail');

        final smtpSettings = await settings.all(prefix: 'mail.smtp.');
        expect(smtpSettings.length, equals(2));
        expect(smtpSettings.containsKey('mail.sendmail.path'), isFalse);
      });
    });

    group('type coercion', () {
      test('should coerce string to int when possible', () async {
        await settings.set('numeric', '123');

        final result = await settings.getInt('numeric');
        expect(result, equals(123));
      });

      test('should coerce string to bool', () async {
        await settings.set('truthy', 'true');
        await settings.set('falsy', 'false');

        expect(await settings.getBool('truthy'), isTrue);
        expect(await settings.getBool('falsy'), isFalse);
      });

      test('should coerce numeric string to double', () async {
        await settings.set('rate', '3.14');

        final result = await settings.getDouble('rate');
        expect(result, closeTo(3.14, 0.001));
      });
    });
  });
}
