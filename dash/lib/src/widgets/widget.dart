import 'package:dash/src/plugin/asset.dart';
import 'package:jaspr/jaspr.dart';

/// Base class for dashboard widgets.
///
/// Widgets are self-contained UI components that can be displayed
/// on the dashboard or other pages. They support:
/// - Sorting for display order
/// - Column span for grid layout
/// - Visibility control via [canView]
/// - Headings and descriptions
/// - Asset dependencies via [requiredAssets]
///
/// Example:
/// ```dart
/// class MyStatsWidget extends Widget {
///   static MyStatsWidget make() => MyStatsWidget();
///
///   @override
///   int get sort => 1;
///
///   @override
///   String? get heading => 'My Stats';
///
///   @override
///   Component build() {
///     return div(classes: 'p-4', [
///       text('Widget content here'),
///     ]);
///   }
/// }
/// ```
abstract class Widget with AssetProvider {
  // ============================================================
  // Configuration Properties
  // ============================================================

  /// The sort order for this widget.
  ///
  /// Lower values appear first. Default is 0.
  int get sort => 0;

  /// The number of columns this widget spans in a 12-column grid.
  ///
  /// Common values:
  /// - 4 = 1/3 width (3 widgets per row)
  /// - 6 = 1/2 width (2 widgets per row)
  /// - 12 = full width
  ///
  /// Default is 6 (half width).
  int get columnSpan => 6;

  /// Optional heading displayed at the top of the widget.
  String? get heading => null;

  /// Optional description displayed below the heading.
  String? get description => null;

  // ============================================================
  // Assets
  // ============================================================

  /// Returns the list of CSS/JS assets required by this widget.
  ///
  /// Override to declare external dependencies like Chart.js.
  /// Assets are deduplicated and only loaded once per page.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// List<Asset> get requiredAssets => [
  ///   JsAsset.url('chartjs', 'https://cdn.jsdelivr.net/npm/chart.js'),
  /// ];
  /// ```
  @override
  List<Asset> get requiredAssets => [];

  // ============================================================
  // Visibility
  // ============================================================

  /// Determines whether this widget should be displayed.
  ///
  /// Override to implement authorization or conditional visibility.
  /// Returns true by default.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// bool canView() => currentUser?.isAdmin ?? false;
  /// ```
  bool canView() => true;

  // ============================================================
  // Data Loading
  // ============================================================

  /// Preloads any async data required by this widget.
  ///
  /// Override this method if your widget needs to fetch data before
  /// rendering. This is called by the dashboard before building
  /// the widget grid.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Future<void> preload() async {
  ///   _data = await fetchMyData();
  /// }
  /// ```
  Future<void> preload() async {}

  // ============================================================
  // Rendering
  // ============================================================

  /// Builds the widget's content.
  ///
  /// This method should return the main content of the widget,
  /// excluding the container styling which is handled by the
  /// dashboard page.
  Component build();

  /// Builds the complete widget with container styling.
  ///
  /// This wraps [build] with standard widget container styling
  /// including heading, description, and card styling.
  Component render() {
    final content = build();

    return div(classes: 'bg-gray-800 rounded-xl shadow-lg overflow-hidden', [
      if (heading != null || description != null)
        div(classes: 'px-6 pt-5 pb-4 border-b border-gray-700', [
          if (heading != null) h3(classes: 'text-lg font-semibold text-white', [text(heading!)]),
          if (description != null) p(classes: 'mt-1 text-sm text-gray-400', [text(description!)]),
        ]),
      div(classes: 'p-6', [content]),
    ]);
  }
}
