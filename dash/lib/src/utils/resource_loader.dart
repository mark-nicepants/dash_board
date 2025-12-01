import 'dart:io';

import 'package:path/path.dart' as p;

/// Loads and caches static resources (CSS, JS, HTML templates) from the resources directory.
class ResourceLoader {
  final String _htmlTemplate;
  final String _css;
  final String _js;
  final bool _useMinified;
  final String _resourcesDir;

  ResourceLoader._({
    required String htmlTemplate,
    required String css,
    required String js,
    required bool useMinified,
    required String resourcesDir,
  }) : _htmlTemplate = htmlTemplate,
       _css = css,
       _js = js,
       _useMinified = useMinified,
       _resourcesDir = resourcesDir;

  /// Finds the resources directory by checking multiple possible locations.
  /// Returns the path to the resources directory, or null if not found.
  static Future<String?> _findResourcesDir() async {
    // Possible locations for the resources directory:
    // 1. Direct path (when running from dash project root)
    // 2. Package path (when dash is a dependency)
    final possiblePaths = [
      'resources', // Running from dash project root
      'dash/resources', // dash is a local path dependency
      '.dart_tool/package_config_packages/dash/resources', // Cached package
    ];

    for (final path in possiblePaths) {
      final dir = Directory(path);
      if (await dir.exists()) {
        return path;
      }
    }

    return null;
  }

  /// Initializes and loads all resources from disk.
  static Future<ResourceLoader> initialize() async {
    final useMinified = Platform.environment['DASH_ENV'] == 'production';

    final resourcesDir = await _findResourcesDir();
    if (resourcesDir == null) {
      throw StateError(
        'Could not find dash resources directory. '
        'Looked in: resources/, dash/resources/',
      );
    }

    final htmlTemplate = await _loadHtmlTemplate(resourcesDir);
    final css = await _loadCss(resourcesDir, useMinified);
    final js = await _loadAppJs(resourcesDir, useMinified);

    return ResourceLoader._(
      htmlTemplate: htmlTemplate,
      css: css,
      js: js,
      useMinified: useMinified,
      resourcesDir: resourcesDir,
    );
  }

  /// Loads the HTML template.
  static Future<String> _loadHtmlTemplate(String resourcesDir) async {
    final file = File('$resourcesDir/index.html');
    return await file.readAsString();
  }

  /// Loads the main CSS file.
  static Future<String> _loadCss(String resourcesDir, bool useMinified) async {
    final cssPath = useMinified ? '$resourcesDir/dist/css/dash.min.css' : '$resourcesDir/dist/css/dash.css';

    final file = File(cssPath);
    if (await file.exists()) {
      return await file.readAsString();
    }

    print('⚠️  CSS file not found at $cssPath - minified: $useMinified');
    return '';
  }

  /// Loads the main application JavaScript.
  static Future<String> _loadAppJs(String resourcesDir, bool useMinified) async {
    final jsPath = useMinified ? '$resourcesDir/dist/js/app.min.js' : '$resourcesDir/dist/js/app.js';

    final file = File(jsPath);
    if (await file.exists()) {
      return await file.readAsString();
    }

    print('⚠️  JS file not found at $jsPath - minified: $useMinified');
    return '';
  }

  /// Renders an HTML template with the given variables.
  ///
  /// [basePath] is the panel's base path (e.g., '/admin') used to construct
  /// static asset URLs.
  ///
  /// [pageHeadAssets] and [pageBodyAssets] are optional page-specific assets
  /// that get injected into the head and body sections respectively.
  String renderTemplate({
    required String title,
    required String body,
    String basePath = '/admin',
    String pageHeadAssets = '',
    String pageBodyAssets = '',
  }) {
    // Use static file serving for CSS and JS
    final cssFile = _useMinified ? 'dash.min.css' : 'dash.css';
    final jsFile = _useMinified ? 'app.min.js' : 'app.js';

    // In development, also add Tailwind CDN for full utility access
    final styles = _useMinified
        ? '<link rel="stylesheet" href="$basePath/assets/css/$cssFile">'
        : '<script src="https://cdn.tailwindcss.com"></script>'
              '<link rel="stylesheet" href="$basePath/assets/css/$cssFile">';

    final scripts = '<script src="$basePath/assets/js/$jsFile"></script>';

    return _htmlTemplate
        .replaceAll('@title', title)
        .replaceAll('@styles', styles)
        .replaceAll('@scripts', scripts)
        .replaceAll('@pageHeadAssets', pageHeadAssets)
        .replaceAll('@pageBodyAssets', pageBodyAssets)
        .replaceAll('@basePath', basePath)
        .replaceAll('@body', body);
  }

  /// Gets the loaded CSS content.
  String get css => _css;

  /// Gets the loaded JS content.
  String get js => _js;

  /// Gets the HTML template.
  String get htmlTemplate => _htmlTemplate;

  /// Whether production assets are being used.
  bool get isProduction => _useMinified;

  /// Gets the absolute path to the resources directory.
  String get resourcesDir => p.absolute(_resourcesDir);

  /// Gets the path to the images directory.
  String get imagesDir => p.join(resourcesDir, 'img');

  /// Gets the path to the dist directory (for built CSS/JS).
  String get distDir => p.join(resourcesDir, 'dist');
}
