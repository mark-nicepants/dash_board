import 'dart:io';

import 'package:dash_board/src/panel/panel.dart';
import 'package:dash_board/src/panel/panel_config_loader.dart';
import 'package:test/test.dart';

void main() {
  group('PanelConfigData', () {
    test('creates with default values', () {
      const config = PanelConfigData();

      expect(config.id, equals('admin'));
      expect(config.path, equals('/admin'));
      expect(config.storage, isNull);
      expect(config.session, isNull);
      expect(config.database, isNull);
    });

    test('parses from YAML map', () {
      final yaml = {
        'panel': {'id': 'dashboard', 'path': '/dashboard'},
        'storage': {
          'basePath': 'data',
          'defaultDisk': 'local',
          'disks': {
            'local': {'driver': 'local', 'path': 'files'},
          },
        },
        'session': {'driver': 'file', 'path': 'sessions'},
        'database': {
          'driver': 'sqlite',
          'path': 'app.db',
          'migrations': {'auto': true, 'verbose': true},
        },
      };

      final config = PanelConfigData.fromYaml(yaml);

      expect(config.id, equals('dashboard'));
      expect(config.path, equals('/dashboard'));
      expect(config.storage, isNotNull);
      expect(config.storage!.basePath, equals('data'));
      expect(config.storage!.defaultDisk, equals('local'));
      expect(config.storage!.disks['local'], isNotNull);
      expect(config.session, isNotNull);
      expect(config.session!.driver, equals('file'));
      expect(config.database, isNotNull);
      expect(config.database!.driver, equals('sqlite'));
      expect(config.database!.path, equals('app.db'));
      expect(config.database!.autoMigrate, isTrue);
      expect(config.database!.verbose, isTrue);
    });

    test('uses defaults for missing sections', () {
      final config = PanelConfigData.fromYaml({});

      expect(config.id, equals('admin'));
      expect(config.path, equals('/admin'));
    });
  });

  group('StorageConfigData', () {
    test('creates with default values', () {
      const config = StorageConfigData();

      expect(config.basePath, equals('storage'));
      expect(config.defaultDisk, equals('public'));
      expect(config.disks, isEmpty);
    });

    test('parses disks from YAML', () {
      final yaml = {
        'basePath': 'data',
        'defaultDisk': 'public',
        'disks': {
          'public': {'driver': 'local', 'path': 'public', 'urlPrefix': '/storage/public'},
          'local': {'driver': 'local', 'path': 'app'},
        },
      };

      final config = StorageConfigData.fromYaml(yaml);

      expect(config.basePath, equals('data'));
      expect(config.defaultDisk, equals('public'));
      expect(config.disks, hasLength(2));
      expect(config.disks['public']!.urlPrefix, equals('/storage/public'));
      expect(config.disks['local']!.path, equals('app'));
    });
  });

  group('SessionConfigData', () {
    test('creates with default values', () {
      const config = SessionConfigData();

      expect(config.driver, equals('file'));
      expect(config.path, equals('sessions'));
    });

    test('parses from YAML', () {
      final config = SessionConfigData.fromYaml({'driver': 'memory', 'path': 'custom/sessions'});

      expect(config.driver, equals('memory'));
      expect(config.path, equals('custom/sessions'));
    });
  });

  group('DbConfigData', () {
    test('parses SQLite config from YAML', () {
      final yaml = {
        'driver': 'sqlite',
        'path': 'database.db',
        'migrations': {'auto': false, 'verbose': true},
      };

      final config = DbConfigData.fromYaml(yaml);

      expect(config.driver, equals('sqlite'));
      expect(config.path, equals('database.db'));
      expect(config.autoMigrate, isFalse);
      expect(config.verbose, isTrue);
    });

    test('uses default migration settings', () {
      final config = DbConfigData.fromYaml({'driver': 'sqlite', 'path': 'app.db'});

      expect(config.autoMigrate, isTrue);
      expect(config.verbose, isFalse);
    });
  });

  group('PanelConfigLoader', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('panel_config_test');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('loads config from YAML file asynchronously', () async {
      final configFile = File('${tempDir.path}/panel.yaml');
      await configFile.writeAsString('''
panel:
  id: test-panel
  path: /test

storage:
  basePath: storage
  defaultDisk: public
  disks:
    public:
      driver: local
      path: public
''');

      final config = await PanelConfigLoader.load(configFile.path);

      expect(config.id, equals('test-panel'));
      expect(config.path, equals('/test'));
      expect(config.storage!.basePath, equals('storage'));
    });

    test('loads config from YAML file synchronously', () async {
      final configFile = File('${tempDir.path}/panel.yaml');
      await configFile.writeAsString('''
panel:
  id: sync-panel
  path: /sync

session:
  driver: memory
  path: sessions
''');

      final config = PanelConfigLoader.loadSync(configFile.path);

      expect(config.id, equals('sync-panel'));
      expect(config.path, equals('/sync'));
      expect(config.session!.driver, equals('memory'));
    });

    test('throws for missing config file (async)', () {
      expect(() => PanelConfigLoader.load('${tempDir.path}/nonexistent.yaml'), throwsStateError);
    });

    test('throws for missing config file (sync)', () {
      expect(() => PanelConfigLoader.loadSync('${tempDir.path}/nonexistent.yaml'), throwsStateError);
    });
  });

  group('PanelConfigExtension', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('panel_config_ext_test');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('applies basic panel settings from YAML file', () async {
      final configFile = File('${tempDir.path}/panel.yaml');
      await configFile.writeAsString('''
panel:
  id: custom
  path: /custom
''');

      final panel = Panel()..applyConfig(configFile.path);

      expect(panel.id, equals('custom'));
      expect(panel.path, equals('/custom'));
    });

    test('applies memory session store', () async {
      final configFile = File('${tempDir.path}/panel.yaml');
      await configFile.writeAsString('''
panel:
  id: test
  path: /test

session:
  driver: memory
  path: sessions
''');

      // Just verify it doesn't throw
      expect(() => Panel()..applyConfig(configFile.path), returnsNormally);
    });

    test('throws for unknown session driver', () async {
      final configFile = File('${tempDir.path}/panel.yaml');
      await configFile.writeAsString('''
panel:
  id: test
  path: /test

session:
  driver: redis
  path: sessions
''');

      expect(() => Panel()..applyConfig(configFile.path), throwsStateError);
    });

    test('throws for unknown storage driver', () async {
      final configFile = File('${tempDir.path}/panel.yaml');
      await configFile.writeAsString('''
panel:
  id: test
  path: /test

storage:
  basePath: storage
  defaultDisk: cloud
  disks:
    cloud:
      driver: s3
      path: bucket
''');

      expect(() => Panel()..applyConfig(configFile.path), throwsStateError);
    });
  });
}
