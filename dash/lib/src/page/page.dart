import 'dart:async';

import 'package:dash/src/components/partials/breadcrumbs.dart';
import 'package:dash/src/components/partials/heroicon.dart';
import 'package:dash/src/plugin/asset.dart';
import 'package:jaspr/jaspr.dart';
import 'package:shelf/shelf.dart';

/// Base class for custom pages in Dash.
///
/// A [Page] represents a non-CRUD page in the admin panel. Unlike [Resource]
/// which provides full CRUD operations for a model, a [Page] is a standalone
/// page that can display any content.
///
/// Pages automatically integrate with:
/// - The admin layout (sidebar, header, etc.)
/// - Breadcrumb navigation
/// - Optional sidebar navigation registration
///
/// Example:
/// ```dart
/// class SettingsPage extends Page {
///   static SettingsPage make() => SettingsPage();
///
///   @override
///   String get slug => 'settings';
///
///   @override
///   String get title => 'Settings';
///
///   @override
///   HeroIcons? get icon => HeroIcons.cog6Tooth;
///
///   @override
///   String? get navigationGroup => 'System';
///
///   @override
///   List<BreadCrumbItem> breadcrumbs(String basePath) => [
///     BreadCrumbItem(label: 'Settings'),
///   ];
///
///   @override
///   Future<Component> build(Request request, String basePath) async {
///     return div([text('Settings content')]);
///   }
/// }
/// ```
abstract class Page {
  /// The unique slug for this page, used in URL routing.
  ///
  /// Example: 'settings' results in URL `/admin/pages/settings`
  String get slug;

  /// The display title for this page.
  ///
  /// Shown in the page header and browser tab.
  String get title;

  /// Optional icon for navigation items.
  ///
  /// If [shouldRegisterNavigation] is true and this returns a value,
  /// the icon will be displayed in the sidebar navigation.
  HeroIcons? get icon => null;

  /// The navigation group this page belongs to.
  ///
  /// If set, the page will be added to the sidebar navigation under
  /// this group heading. If null, the page won't appear in navigation.
  ///
  /// Common groups: 'Main', 'Content', 'System', 'Settings'
  String? get navigationGroup => null;

  /// Sort order within the navigation group.
  ///
  /// Lower values appear first. Defaults to 0.
  int get navigationSort => 0;

  /// Whether this page should be registered in sidebar navigation.
  ///
  /// Returns true if [navigationGroup] is set.
  bool get shouldRegisterNavigation => navigationGroup != null;

  /// Returns the breadcrumb trail for this page.
  ///
  /// The [basePath] is the panel's base path (e.g., '/admin').
  /// Use it to construct URLs for parent breadcrumb items.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// List<BreadCrumbItem> breadcrumbs(String basePath) => [
  ///   BreadCrumbItem(label: 'Dashboard', url: basePath),
  ///   BreadCrumbItem(label: 'Settings'),
  /// ];
  /// ```
  List<BreadCrumbItem> breadcrumbs(String basePath);

  /// Builds the page content.
  ///
  /// This method receives the current [request] for accessing query parameters,
  /// the [basePath] for constructing URLs, and optionally [formData] when
  /// handling a POST request (the form data has already been parsed by the router).
  ///
  /// Return a Jaspr [Component] representing the page content.
  /// The content will be wrapped in the admin layout automatically.
  FutureOr<Component> build(Request request, String basePath, {Map<String, dynamic>? formData});

  /// Optional page-specific assets.
  ///
  /// Return a [PageAssetCollector] with any CSS or JS assets
  /// that should be loaded specifically for this page.
  PageAssetCollector? get assets => null;
}
