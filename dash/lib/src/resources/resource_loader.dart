import 'dart:io';

/// Loads and caches static resources (CSS, JS, HTML templates) from the resources directory.
class ResourceLoader {
  final String _htmlTemplate;
  final String _css;
  final String _js;
  final bool _useMinified;

  ResourceLoader._({required String htmlTemplate, required String css, required String js, required bool useMinified})
    : _htmlTemplate = htmlTemplate,
      _css = css,
      _js = js,
      _useMinified = useMinified;

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

    print('🔧 Initializing ResourceLoader (${useMinified ? 'production' : 'development'} mode)...');

    final resourcesDir = await _findResourcesDir();
    if (resourcesDir == null) {
      throw StateError(
        'Could not find dash resources directory. '
        'Looked in: resources/, dash/resources/'
      );
    }

    print('📂 Found resources at: $resourcesDir');

    final htmlTemplate = await _loadHtmlTemplate(resourcesDir);
    final css = await _loadCss(resourcesDir, useMinified);
    final js = await _loadAppJs(resourcesDir, useMinified);

    print('✅ Resources loaded successfully');

    return ResourceLoader._(htmlTemplate: htmlTemplate, css: css, js: js, useMinified: useMinified);
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
  String renderTemplate({required String title, required String body}) {
    return _htmlTemplate
        .replaceAll('@title', title)
        .replaceAll('@styles', '<style>$_css</style>')
        .replaceAll('@scripts', '<script>$_js</script>')
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
}
