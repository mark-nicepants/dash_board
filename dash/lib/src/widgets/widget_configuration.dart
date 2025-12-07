import 'package:dash_board/src/widgets/widget.dart';

/// Configuration wrapper for a widget with additional properties.
///
/// This class wraps a [Widget] instance with optional properties
/// that can be set at registration time.
///
/// Example:
/// ```dart
/// panel.widgets([
///   WidgetConfiguration(
///     widget: MyStatsWidget(),
///     properties: {'refreshInterval': 30},
///   ),
/// ]);
/// ```
class WidgetConfiguration {
  /// The widget instance.
  final Widget widget;

  /// Additional properties for the widget.
  final Map<String, dynamic> properties;

  const WidgetConfiguration({required this.widget, this.properties = const {}});

  /// Gets the underlying widget class.
  Widget get instance => widget;

  /// Gets a property value by key.
  T? getProperty<T>(String key) => properties[key] as T?;

  /// Gets a property value by key with a default fallback.
  T getPropertyOr<T>(String key, T defaultValue) => properties[key] as T? ?? defaultValue;

  /// The sort order (delegates to widget).
  int get sort => widget.sort;

  /// The column span (delegates to widget).
  int get columnSpan => widget.columnSpan;

  /// Whether the widget can be viewed (delegates to widget).
  bool canView() => widget.canView();

  /// Builds the widget (delegates to widget).
  Widget build() => widget;
}
