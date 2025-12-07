import 'dart:io';

import 'package:dash_panel_cli/src/utils/config_loader.dart';
import 'package:test/test.dart';

void main() {
  group('DashConfig', () {
    test('defaults returns expected values', () {
      final config = DashConfig.defaults();

      expect(config.databasePath, 'storage/app.db');
      expect(config.schemasPath, 'schemas/models');
      expect(config.outputPath, 'lib');
      expect(config.serverUrl, 'http://localhost');
      expect(config.serverPort, 8080);
      expect(config.basePath, '/admin');
    });

    test('fullServerUrl combines url, port, and path', () {
      final config = DashConfig.defaults();
      expect(config.fullServerUrl, 'http://localhost:8080/admin');
    });

    test('apiUrl includes _cli path', () {
      final config = DashConfig.defaults();
      expect(config.apiUrl, 'http://localhost:8080/admin/_cli');
    });
  });

  group('ConfigLoader', () {
    test('findProjectRoot finds directory with pubspec.yaml', () {
      // This test uses the actual dash_cli directory
      final root = ConfigLoader.findProjectRoot(Directory.current.path);
      expect(root, isNotNull);
      expect(File('$root/pubspec.yaml').existsSync(), isTrue);
    });

    test('getPackageName returns package name from pubspec', () {
      final name = ConfigLoader.getPackageName();
      expect(name, 'dash_cli');
    });
  });
}
