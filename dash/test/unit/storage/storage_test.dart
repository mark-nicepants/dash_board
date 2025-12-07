import 'dart:io';
import 'dart:typed_data';

import 'package:dash_board/src/storage/storage.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('LocalStorage', () {
    late Directory tempDir;
    late LocalStorage storage;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('dash_storage_test_');
      storage = LocalStorage(basePath: tempDir.path, urlPrefix: '/uploads');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('put', () {
      test('stores bytes at given path', () async {
        final data = Uint8List.fromList([1, 2, 3, 4, 5]);
        final result = await storage.put('test.bin', data);

        expect(result, equals('test.bin'));

        final file = File(p.join(tempDir.path, 'test.bin'));
        expect(await file.exists(), isTrue);
        expect(await file.readAsBytes(), equals(data));
      });

      test('creates nested directories automatically', () async {
        final data = Uint8List.fromList([10, 20, 30]);
        await storage.put('a/b/c/nested.bin', data);

        final file = File(p.join(tempDir.path, 'a', 'b', 'c', 'nested.bin'));
        expect(await file.exists(), isTrue);
        expect(await file.readAsBytes(), equals(data));
      });

      test('overwrites existing file', () async {
        final initialData = Uint8List.fromList([1, 2, 3]);
        final updatedData = Uint8List.fromList([4, 5, 6, 7]);

        await storage.put('overwrite.bin', initialData);
        await storage.put('overwrite.bin', updatedData);

        final file = File(p.join(tempDir.path, 'overwrite.bin'));
        expect(await file.readAsBytes(), equals(updatedData));
      });
    });

    group('putFile', () {
      test('copies source file to storage path', () async {
        // Create a temp source file
        final sourceFile = File(p.join(tempDir.path, '_source.tmp'));
        await sourceFile.writeAsBytes([100, 101, 102]);

        await storage.putFile('copied.bin', sourceFile);

        final storedFile = File(p.join(tempDir.path, 'copied.bin'));
        expect(await storedFile.exists(), isTrue);
        expect(await storedFile.readAsBytes(), equals([100, 101, 102]));
      });
    });

    group('get', () {
      test('returns file bytes when file exists', () async {
        final data = Uint8List.fromList([11, 22, 33]);
        await storage.put('retrieve.bin', data);

        final result = await storage.get('retrieve.bin');
        expect(result, equals(data));
      });

      test('returns null when file does not exist', () async {
        final result = await storage.get('nonexistent.bin');
        expect(result, isNull);
      });
    });

    group('exists', () {
      test('returns true when file exists', () async {
        await storage.put('exists.txt', Uint8List.fromList([1]));
        expect(await storage.exists('exists.txt'), isTrue);
      });

      test('returns false when file does not exist', () async {
        expect(await storage.exists('missing.txt'), isFalse);
      });
    });

    group('delete', () {
      test('deletes existing file and returns true', () async {
        await storage.put('deleteme.txt', Uint8List.fromList([1]));
        final result = await storage.delete('deleteme.txt');

        expect(result, isTrue);
        expect(await storage.exists('deleteme.txt'), isFalse);
      });

      test('returns false when file does not exist', () async {
        final result = await storage.delete('ghost.txt');
        expect(result, isFalse);
      });
    });

    group('url', () {
      test('generates URL with configured prefix', () {
        expect(storage.url('avatar.jpg'), equals('/uploads/avatar.jpg'));
      });

      test('handles nested paths', () {
        expect(storage.url('users/1/avatar.jpg'), equals('/uploads/users/1/avatar.jpg'));
      });

      test('normalizes backslashes to forward slashes', () {
        expect(storage.url(r'users\1\avatar.jpg'), equals('/uploads/users/1/avatar.jpg'));
      });
    });

    group('path', () {
      test('returns full filesystem path', () {
        final expectedPath = p.join(tempDir.path, 'somefile.txt');
        expect(storage.path('somefile.txt'), equals(expectedPath));
      });

      test('handles nested paths', () {
        final expectedPath = p.join(tempDir.path, 'a', 'b', 'c.txt');
        expect(storage.path('a/b/c.txt'), equals(expectedPath));
      });
    });

    group('size', () {
      test('returns file size in bytes', () async {
        final data = Uint8List.fromList(List.generate(100, (i) => i));
        await storage.put('sized.bin', data);

        expect(await storage.size('sized.bin'), equals(100));
      });

      test('returns null for missing file', () async {
        expect(await storage.size('missing.bin'), isNull);
      });
    });

    group('mimeType', () {
      test('returns correct MIME type for known extensions', () async {
        expect(await storage.mimeType('photo.jpg'), equals('image/jpeg'));
        expect(await storage.mimeType('photo.jpeg'), equals('image/jpeg'));
        expect(await storage.mimeType('logo.png'), equals('image/png'));
        expect(await storage.mimeType('doc.pdf'), equals('application/pdf'));
        expect(await storage.mimeType('data.json'), equals('application/json'));
        expect(await storage.mimeType('song.mp3'), equals('audio/mpeg'));
        expect(await storage.mimeType('video.mp4'), equals('video/mp4'));
      });

      test('returns octet-stream for unknown extensions', () async {
        expect(await storage.mimeType('file.xyz'), equals('application/octet-stream'));
        expect(await storage.mimeType('noext'), equals('application/octet-stream'));
      });
    });

    group('visibility', () {
      test('getVisibility returns default visibility', () async {
        expect(await storage.getVisibility('any.txt'), equals('public'));
      });

      test('setVisibility is a no-op for local storage', () async {
        // Should not throw
        await storage.setVisibility('any.txt', 'private');
        // Visibility unchanged (local storage doesn't support it)
        expect(await storage.getVisibility('any.txt'), equals('public'));
      });

      test('respects custom default visibility', () async {
        final privateStorage = LocalStorage(basePath: tempDir.path, defaultVisibility: 'private');
        expect(await privateStorage.getVisibility('any.txt'), equals('private'));
      });
    });

    group('temporaryUrl', () {
      test('falls back to regular url for local storage', () async {
        final tempUrl = await storage.temporaryUrl('file.txt', const Duration(hours: 1));
        expect(tempUrl, equals(storage.url('file.txt')));
      });
    });
  });

  group('StorageManager', () {
    late StorageManager manager;
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('dash_storage_mgr_test_');
      manager = StorageManager();
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('registerDisk and disk retrieval', () {
      final localDisk = LocalStorage(basePath: tempDir.path);
      manager.registerDisk('local', localDisk);

      expect(manager.disk('local'), same(localDisk));
    });

    test('setDefaultDisk changes default disk', () {
      final disk1 = LocalStorage(basePath: p.join(tempDir.path, 'disk1'));
      final disk2 = LocalStorage(basePath: p.join(tempDir.path, 'disk2'));

      manager.registerDisk('disk1', disk1);
      manager.registerDisk('disk2', disk2);
      manager.setDefaultDisk('disk2');

      expect(manager.disk(), same(disk2));
      expect(manager.defaultDisk, same(disk2));
    });

    test('disk() throws for unregistered disk', () {
      expect(() => manager.disk('unknown'), throwsStateError);
    });

    test('hasDisk returns correct status', () {
      manager.registerDisk('exists', LocalStorage(basePath: tempDir.path));

      expect(manager.hasDisk('exists'), isTrue);
      expect(manager.hasDisk('missing'), isFalse);
    });

    test('diskNames returns all registered names', () {
      manager.registerDisk('a', LocalStorage(basePath: tempDir.path));
      manager.registerDisk('b', LocalStorage(basePath: tempDir.path));

      expect(manager.diskNames, containsAll(['a', 'b']));
    });
  });

  group('StorageConfig', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('dash_storage_cfg_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('createManager creates manager with configured disks', () {
      final config = StorageConfig(
        defaultDisk: 'public',
        disks: {
          'local': LocalStorage(basePath: p.join(tempDir.path, 'local')),
          'public': LocalStorage(basePath: p.join(tempDir.path, 'public'), urlPrefix: '/storage'),
        },
      );

      final manager = config.createManager();

      expect(manager.hasDisk('local'), isTrue);
      expect(manager.hasDisk('public'), isTrue);
      expect(manager.disk().url('test.txt'), equals('/storage/test.txt'));
    });

    test('default values', () {
      final config = StorageConfig();

      expect(config.defaultDisk, equals('public'));
      expect(config.disks, isEmpty);
    });
  });
}
