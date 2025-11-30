import 'dart:io';

import 'package:dash/src/utils/resource_loader.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('ResourceLoader', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('dash_resource_loader_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('renderTemplate', () {
      test('replaces all placeholders', () async {
        final loader = await _createTestLoader(tempDir);

        final html = loader.renderTemplate(title: 'My Dashboard', body: '<h1>Hello</h1>', basePath: '/admin');

        expect(html, contains('<title>My Dashboard</title>'));
        expect(html, contains('<h1>Hello</h1>'));
        expect(html, contains('/admin/assets/css/'));
        expect(html, contains('/admin/assets/js/'));
      });

      test('includes page head assets', () async {
        final loader = await _createTestLoader(tempDir);

        final html = loader.renderTemplate(
          title: 'Test',
          body: '<div></div>',
          pageHeadAssets: '<link rel="stylesheet" href="/custom.css">',
        );

        expect(html, contains('<link rel="stylesheet" href="/custom.css">'));
      });

      test('includes page body assets', () async {
        final loader = await _createTestLoader(tempDir);

        final html = loader.renderTemplate(
          title: 'Test',
          body: '<div></div>',
          pageBodyAssets: '<script src="/custom.js"></script>',
        );

        expect(html, contains('<script src="/custom.js"></script>'));
      });

      test('uses correct basePath for asset URLs', () async {
        final loader = await _createTestLoader(tempDir);

        final html = loader.renderTemplate(title: 'Test', body: '<div></div>', basePath: '/dashboard');

        expect(html, contains('/dashboard/assets/css/'));
        expect(html, contains('/dashboard/assets/js/'));
      });

      test('uses development assets by default', () async {
        final loader = await _createTestLoader(tempDir);

        expect(loader.isProduction, isFalse);

        final html = loader.renderTemplate(title: 'Test', body: '<div></div>');

        expect(html, contains('dash.css'));
        expect(html, contains('app.js'));
        // Development mode includes Tailwind CDN
        expect(html, contains('cdn.tailwindcss.com'));
      });
    });

    group('getters', () {
      test('css returns loaded CSS content', () async {
        final loader = await _createTestLoader(tempDir, css: '.test { color: red; }');

        expect(loader.css, equals('.test { color: red; }'));
      });

      test('js returns loaded JS content', () async {
        final loader = await _createTestLoader(tempDir, js: 'console.log("test");');

        expect(loader.js, equals('console.log("test");'));
      });

      test('htmlTemplate returns loaded template', () async {
        final loader = await _createTestLoader(tempDir);

        expect(loader.htmlTemplate, contains('<html'));
        expect(loader.htmlTemplate, contains('@title'));
      });

      test('resourcesDir returns absolute path', () async {
        final loader = await _createTestLoader(tempDir);

        expect(p.isAbsolute(loader.resourcesDir), isTrue);
      });

      test('imagesDir returns path to img subdirectory', () async {
        final loader = await _createTestLoader(tempDir);

        expect(loader.imagesDir, endsWith('img'));
      });

      test('distDir returns path to dist subdirectory', () async {
        final loader = await _createTestLoader(tempDir);

        expect(loader.distDir, endsWith('dist'));
      });
    });

    group('initialize', () {
      test('throws StateError when resources directory not found', () async {
        // Change to a directory without resources
        final originalDir = Directory.current;
        Directory.current = tempDir;

        try {
          await expectLater(
            ResourceLoader.initialize(),
            throwsA(
              isA<StateError>().having(
                (e) => e.message,
                'message',
                contains('Could not find dash resources directory'),
              ),
            ),
          );
        } finally {
          Directory.current = originalDir;
        }
      });

      test('loads resources from resources directory', () async {
        // Create a resources directory structure in temp
        final resourcesDir = Directory(p.join(tempDir.path, 'resources'));
        await _createResourcesStructure(resourcesDir.path);

        final originalDir = Directory.current;
        Directory.current = tempDir;

        try {
          final loader = await ResourceLoader.initialize();

          expect(loader.htmlTemplate, isNotEmpty);
          expect(loader.css, isNotEmpty);
          expect(loader.js, isNotEmpty);
        } finally {
          Directory.current = originalDir;
        }
      });
    });
  });
}

/// Creates a test ResourceLoader with mock resources.
Future<ResourceLoader> _createTestLoader(Directory tempDir, {String? css, String? js}) async {
  final resourcesDir = Directory(p.join(tempDir.path, 'resources'));
  await _createResourcesStructure(resourcesDir.path, css: css, js: js);

  final originalDir = Directory.current;
  Directory.current = tempDir;

  try {
    return await ResourceLoader.initialize();
  } finally {
    Directory.current = originalDir;
  }
}

/// Creates a minimal resources directory structure for testing.
Future<void> _createResourcesStructure(String resourcesPath, {String? css, String? js}) async {
  // Create directories
  await Directory(p.join(resourcesPath, 'dist', 'css')).create(recursive: true);
  await Directory(p.join(resourcesPath, 'dist', 'js')).create(recursive: true);
  await Directory(p.join(resourcesPath, 'img')).create(recursive: true);

  // Create index.html template
  await File(p.join(resourcesPath, 'index.html')).writeAsString('''
<!DOCTYPE html>
<html>
<head>
  <title>@title</title>
  @styles
  @pageHeadAssets
</head>
<body>
  @body
  @scripts
  @pageBodyAssets
</body>
</html>
''');

  // Create CSS file
  await File(p.join(resourcesPath, 'dist', 'css', 'dash.css')).writeAsString(css ?? '/* test css */');

  // Create JS file
  await File(p.join(resourcesPath, 'dist', 'js', 'app.js')).writeAsString(js ?? '// test js');
}
