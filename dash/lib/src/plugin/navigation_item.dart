import 'package:dash_board/src/components/partials/heroicon.dart';

/// A custom navigation item that can be added by plugins.
///
/// Navigation items appear in the sidebar alongside resource links.
/// They can link to custom pages, external URLs, or plugin-specific routes.
///
/// Example:
/// ```dart
/// NavigationItem.make('Documentation')
///   .url('https://docs.example.com')
///   .icon(HeroIcons.bookOpen)
///   .group('Help')
///   .openInNewTab()
/// ```
class NavigationItem {
  final String _label;
  String? _url;
  HeroIcons? _icon;
  String _group = 'Main';
  int _sort = 0;
  bool _openInNewTab = false;
  bool Function()? _visibleWhen;

  NavigationItem._(this._label);

  /// Creates a new navigation item with the given label.
  ///
  /// This is the preferred way to create navigation items:
  /// ```dart
  /// NavigationItem.make('Settings')
  ///   .url('/settings')
  ///   .icon(HeroIcons.cog6Tooth)
  /// ```
  static NavigationItem make(String label) => NavigationItem._(label);

  // ============================================================
  // Configuration Methods
  // ============================================================

  /// Sets the URL for this navigation item.
  ///
  /// Can be a relative path (e.g., '/settings') or absolute URL.
  /// Relative paths will be prefixed with the panel's base path.
  NavigationItem url(String url) {
    _url = url;
    return this;
  }

  /// Sets the icon for this navigation item.
  ///
  /// Uses Heroicons for consistency with the rest of Dash.
  NavigationItem icon(HeroIcons icon) {
    _icon = icon;
    return this;
  }

  /// Sets the navigation group for this item.
  ///
  /// Items with the same group are displayed together under a header.
  /// Defaults to 'Main'.
  NavigationItem group(String group) {
    _group = group;
    return this;
  }

  /// Sets the sort order within the navigation group.
  ///
  /// Lower values appear first. Defaults to 0.
  NavigationItem sort(int sort) {
    _sort = sort;
    return this;
  }

  /// Opens the link in a new browser tab.
  NavigationItem openInNewTab([bool condition = true]) {
    _openInNewTab = condition;
    return this;
  }

  /// Sets a condition for when this item should be visible.
  ///
  /// The callback is evaluated each time navigation is rendered.
  NavigationItem visibleWhen(bool Function() condition) {
    _visibleWhen = condition;
    return this;
  }

  // ============================================================
  // Getters
  // ============================================================

  /// The display label for this navigation item.
  String get label => _label;

  /// The URL this item links to.
  String? get getUrl => _url;

  /// The icon for this item, or null if none set.
  HeroIcons? get getIcon => _icon;

  /// The navigation group this item belongs to.
  String get getGroup => _group;

  /// The sort order for this item.
  int get getSort => _sort;

  /// Whether to open the link in a new tab.
  bool get shouldOpenInNewTab => _openInNewTab;

  /// Whether this item should be visible.
  bool get isVisible => _visibleWhen?.call() ?? true;

  /// Resolves the URL with the given base path.
  ///
  /// - Absolute URLs (http://, https://) are returned unchanged
  /// - Relative paths are prefixed with the base path
  String resolveUrl(String basePath) {
    final url = _url ?? '';
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    if (url.startsWith('/')) {
      return '$basePath$url';
    }
    return '$basePath/$url';
  }
}
