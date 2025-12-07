import 'package:dash_board/src/panel/panel_storage.dart';
import 'package:dash_board/src/storage/storage.dart';
import 'package:test/test.dart';

void main() {
  group('PanelStorageManager', () {
    test('isConfigured is false initially', () {
      final manager = PanelStorageManager();
      expect(manager.isConfigured, isFalse);
    });

    test('configure sets isConfigured to true', () {
      final manager = PanelStorageManager();
      final config = StorageConfig();

      manager.configure(config);

      expect(manager.isConfigured, isTrue);
    });

    test('configure accepts StorageConfig with disks', () {
      final manager = PanelStorageManager();
      final config = StorageConfig(
        defaultDisk: 'public',
        disks: {
          'local': LocalStorage(basePath: '/tmp/local'),
          'public': LocalStorage(basePath: '/tmp/public', urlPrefix: '/storage'),
        },
      );

      manager.configure(config);

      expect(manager.isConfigured, isTrue);
    });
  });
}
