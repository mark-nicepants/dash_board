import 'package:dash_board/src/components/partials/heroicon.dart';
import 'package:jaspr/jaspr.dart';

/// A single statistic card for use in [StatsOverviewWidget].
///
/// Displays a labeled value with optional:
/// - Icon
/// - Description with trend indicator
/// - Sparkline chart
/// - Color theming
///
/// Example:
/// ```dart
/// Stat.make('Total Users', '1,234')
///   .icon(HeroIcons.users)
///   .description('+12% from last month')
///   .descriptionIcon(HeroIcons.arrowUp)
///   .color('green');
/// ```
class Stat {
  final String _label;
  final String _value;
  HeroIcons? _icon;
  String? _description;
  HeroIcons? _descriptionIcon;
  String _color = 'cyan';
  String? _descriptionColor;
  List<double>? _chartData;
  String? _chartColor;
  String? _url;

  Stat._(this._label, this._value);

  /// Creates a new Stat with a label and value.
  ///
  /// Example:
  /// ```dart
  /// Stat.make('Revenue', '\$12,345')
  /// ```
  static Stat make(String label, String value) => Stat._(label, value);

  // ============================================================
  // Configuration Methods (Fluent API)
  // ============================================================

  /// Sets the icon for this stat.
  Stat icon(HeroIcons icon) {
    _icon = icon;
    return this;
  }

  /// Sets the description text shown below the value.
  Stat description(String description) {
    _description = description;
    return this;
  }

  /// Sets an icon to display with the description (e.g., trend arrow).
  Stat descriptionIcon(HeroIcons icon) {
    _descriptionIcon = icon;
    return this;
  }

  /// Sets the primary color for this stat.
  ///
  /// Use Tailwind color names: 'cyan', 'green', 'red', 'amber', etc.
  Stat color(String color) {
    _color = color;
    return this;
  }

  /// Sets the color for the description text.
  ///
  /// Useful for showing positive (green) or negative (red) trends.
  Stat descriptionColor(String color) {
    _descriptionColor = color;
    return this;
  }

  /// Sets sparkline chart data for this stat.
  ///
  /// Example:
  /// ```dart
  /// Stat.make('Visitors', '1,234')
  ///   .chart([10, 15, 8, 22, 18, 25, 30])
  ///   .chartColor('cyan');
  /// ```
  Stat chart(List<double> data) {
    _chartData = data;
    return this;
  }

  /// Sets the color for the sparkline chart.
  Stat chartColor(String color) {
    _chartColor = color;
    return this;
  }

  /// Makes the stat clickable, linking to the given URL.
  Stat url(String url) {
    _url = url;
    return this;
  }

  // ============================================================
  // Getters
  // ============================================================

  String get label => _label;
  String get value => _value;
  HeroIcons? get getIcon => _icon;
  String? get getDescription => _description;
  HeroIcons? get getDescriptionIcon => _descriptionIcon;
  String get getColor => _color;
  String? get getDescriptionColor => _descriptionColor;
  List<double>? get getChartData => _chartData;
  String? get getChartColor => _chartColor;
  String? get getUrl => _url;

  // ============================================================
  // Rendering
  // ============================================================

  /// Builds the stat card component.
  Component build() {
    final descColor = _descriptionColor ?? 'gray';
    final sparklineColor = _chartColor ?? _color;

    final content = div(classes: 'flex items-start justify-between', [
      // Left side: icon, label, value, description
      div(classes: 'flex-1', [
        // Icon and label
        div(classes: 'flex items-center gap-2 mb-2', [
          if (_icon != null)
            div(classes: 'p-2 rounded-lg bg-$_color-500/10', [Heroicon(_icon!, size: 20, color: 'text-$_color-400')]),
          span(classes: 'text-sm font-medium text-gray-400', [text(_label)]),
        ]),
        // Value
        div(classes: 'text-3xl font-bold text-white mb-1', [text(_value)]),
        // Description
        if (_description != null)
          div(classes: 'flex items-center gap-1 text-sm text-$descColor-400', [
            if (_descriptionIcon != null) Heroicon(_descriptionIcon!, size: 14),
            span([text(_description!)]),
          ]),
      ]),
      // Right side: sparkline chart
      if (_chartData != null && _chartData!.isNotEmpty) _buildSparkline(sparklineColor),
    ]);

    // Wrap in link if URL is provided
    if (_url != null) {
      return a(href: _url!, classes: 'block p-4 bg-gray-700/50 rounded-lg hover:bg-gray-700 transition-colors', [
        content,
      ]);
    }

    return div(classes: 'p-4 bg-gray-700/50 rounded-lg', [content]);
  }

  /// Builds a simple SVG sparkline chart.
  Component _buildSparkline(String color) {
    final data = _chartData!;
    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final minValue = data.reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;

    // SVG dimensions
    const width = 80;
    const height = 40;
    const padding = 2;

    // Calculate points
    final points = <String>[];
    for (var i = 0; i < data.length; i++) {
      final x = padding + (i / (data.length - 1)) * (width - padding * 2);
      final normalizedY = range > 0 ? (data[i] - minValue) / range : 0.5;
      final y = height - padding - (normalizedY * (height - padding * 2));
      points.add('${x.toStringAsFixed(1)},${y.toStringAsFixed(1)}');
    }

    final polylinePoints = points.join(' ');

    // Use raw SVG since DomComponent doesn't have unnamed constructor
    return raw('''
      <svg width="$width" height="$height" viewBox="0 0 $width $height" class="text-$color-400">
        <polyline 
          points="$polylinePoints" 
          fill="none" 
          stroke="currentColor" 
          stroke-width="2" 
          stroke-linecap="round" 
          stroke-linejoin="round"
        />
      </svg>
    ''');
  }
}
