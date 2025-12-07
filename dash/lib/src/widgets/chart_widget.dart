import 'dart:convert';

import 'package:dash_board/src/plugin/asset.dart';
import 'package:dash_board/src/widgets/widget.dart';
import 'package:jaspr/jaspr.dart';

/// Chart types supported by Chart.js.
enum ChartType { line, bar, pie, doughnut, polarArea, radar }

/// A dataset for chart widgets.
///
/// Represents a single series of data in a chart with styling options.
///
/// Example:
/// ```dart
/// ChartDataset(
///   label: 'Revenue',
///   data: [100, 200, 150, 300, 250],
///   backgroundColor: 'rgba(6, 182, 212, 0.5)',
///   borderColor: 'rgb(6, 182, 212)',
/// )
/// ```
class ChartDataset {
  final String label;
  final List<num> data;
  final dynamic backgroundColor; // String or List<String> for pie/doughnut
  final dynamic borderColor; // String or List<String> for pie/doughnut
  final int? borderWidth;
  final bool? fill;
  final double? tension;

  const ChartDataset({
    required this.label,
    required this.data,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.fill,
    this.tension,
  });

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'data': data,
      if (backgroundColor != null) 'backgroundColor': backgroundColor,
      if (borderColor != null) 'borderColor': borderColor,
      if (borderWidth != null) 'borderWidth': borderWidth,
      if (fill != null) 'fill': fill,
      if (tension != null) 'tension': tension,
    };
  }
}

/// Data container for chart widgets.
///
/// Contains labels (x-axis) and one or more datasets.
class ChartData {
  final List<String> labels;
  final List<ChartDataset> datasets;

  const ChartData({required this.labels, required this.datasets});

  Map<String, dynamic> toJson() {
    return {'labels': labels, 'datasets': datasets.map((d) => d.toJson()).toList()};
  }
}

/// Base class for chart widgets using Chart.js.
///
/// Extend this class and override [getType] and [getData] to create
/// custom chart widgets.
///
/// Example:
/// ```dart
/// class RevenueChartWidget extends ChartWidget {
///   static RevenueChartWidget make() => RevenueChartWidget();
///
///   @override
///   ChartType getType() => ChartType.line;
///
///   @override
///   String? get heading => 'Monthly Revenue';
///
///   @override
///   ChartData getData() => ChartData(
///     labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
///     datasets: [
///       ChartDataset(
///         label: 'Revenue',
///         data: [1200, 1900, 3000, 5000, 4000, 6000],
///         borderColor: 'rgb(6, 182, 212)',
///         tension: 0.3,
///       ),
///     ],
///   );
/// }
/// ```
abstract class ChartWidget extends Widget {
  /// Chart.js CDN URL
  static const _chartJsCdn = 'https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js';

  /// Maximum height of the chart container.
  String? get maxHeight => null;

  /// Chart.js options for customization.
  ///
  /// Override to provide custom Chart.js configuration.
  Map<String, dynamic>? getOptions() => null;

  /// Returns the chart type.
  ChartType getType();

  /// Returns the chart data with labels and datasets.
  ChartData getData();

  @override
  List<Asset> get requiredAssets => [JsAsset.url('chartjs', _chartJsCdn)];

  @override
  Component build() {
    final chartData = getData();
    final chartType = getType();
    final options = _mergeOptions(getOptions());

    // Generate unique ID for this chart instance
    final chartId = 'chart-${identityHashCode(this).abs()}';

    // Build Chart.js configuration
    final config = {'type': chartType.name, 'data': chartData.toJson(), 'options': options};

    final configJson = jsonEncode(config);

    return div(classes: 'relative', [
      raw('''
        <div class="chart-container" style="position: relative;${maxHeight != null ? ' max-height: $maxHeight;' : ''}">
          <canvas id="$chartId"></canvas>
        </div>
        <script>
          (function() {
            function initChart() {
              const ctx = document.getElementById('$chartId');
              if (ctx && typeof Chart !== 'undefined') {
                new Chart(ctx, $configJson);
              }
            }
            if (typeof Chart !== 'undefined') {
              initChart();
            } else {
              // Wait for Chart.js to load
              window.addEventListener('load', initChart);
            }
          })();
        </script>
      '''),
    ]);
  }

  /// Merges user options with default dark theme options.
  Map<String, dynamic> _mergeOptions(Map<String, dynamic>? userOptions) {
    final defaults = _getDefaultOptions();
    if (userOptions == null) return defaults;

    // Deep merge would be ideal, but shallow merge is sufficient for most cases
    return {...defaults, ...userOptions};
  }

  /// Default Chart.js options for dark theme.
  Map<String, dynamic> _getDefaultOptions() {
    return {
      'responsive': true,
      'maintainAspectRatio': true,
      'plugins': {
        'legend': {
          'display': true,
          'position': 'bottom',
          'labels': {'color': 'rgb(156, 163, 175)'},
        },
      },
    };
  }
}

// ============================================================
// Convenience Chart Widget Classes
// ============================================================

/// A line chart widget.
///
/// Example:
/// ```dart
/// class MyLineChart extends LineChartWidget {
///   static MyLineChart make() => MyLineChart();
///
///   @override
///   String? get heading => 'Trend';
///
///   @override
///   ChartData getData() => ChartData(
///     labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
///     datasets: [
///       ChartDataset(label: 'Views', data: [10, 20, 15, 25, 30]),
///     ],
///   );
/// }
/// ```
abstract class LineChartWidget extends ChartWidget {
  @override
  ChartType getType() => ChartType.line;

  @override
  Map<String, dynamic>? getOptions() => {
    'responsive': true,
    'maintainAspectRatio': true,
    'plugins': {
      'legend': {
        'display': true,
        'position': 'bottom',
        'labels': {'color': 'rgb(156, 163, 175)'},
      },
    },
    'scales': {
      'x': {
        'ticks': {'color': 'rgb(156, 163, 175)'},
        'grid': {'color': 'rgba(75, 85, 99, 0.3)'},
      },
      'y': {
        'ticks': {'color': 'rgb(156, 163, 175)'},
        'grid': {'color': 'rgba(75, 85, 99, 0.3)'},
      },
    },
  };
}

/// A bar chart widget.
abstract class BarChartWidget extends ChartWidget {
  @override
  ChartType getType() => ChartType.bar;

  @override
  Map<String, dynamic>? getOptions() => {
    'responsive': true,
    'maintainAspectRatio': true,
    'plugins': {
      'legend': {
        'display': true,
        'position': 'bottom',
        'labels': {'color': 'rgb(156, 163, 175)'},
      },
    },
    'scales': {
      'x': {
        'ticks': {'color': 'rgb(156, 163, 175)'},
        'grid': {'color': 'rgba(75, 85, 99, 0.3)'},
      },
      'y': {
        'ticks': {'color': 'rgb(156, 163, 175)'},
        'grid': {'color': 'rgba(75, 85, 99, 0.3)'},
      },
    },
  };
}

/// A pie chart widget.
abstract class PieChartWidget extends ChartWidget {
  @override
  ChartType getType() => ChartType.pie;

  @override
  Map<String, dynamic>? getOptions() => {
    'responsive': true,
    'maintainAspectRatio': true,
    'plugins': {
      'legend': {
        'display': true,
        'position': 'bottom',
        'labels': {'color': 'rgb(156, 163, 175)'},
      },
    },
  };
}

/// A doughnut chart widget.
abstract class DoughnutChartWidget extends ChartWidget {
  @override
  ChartType getType() => ChartType.doughnut;

  @override
  Map<String, dynamic>? getOptions() => {
    'responsive': true,
    'maintainAspectRatio': true,
    'plugins': {
      'legend': {
        'display': true,
        'position': 'bottom',
        'labels': {'color': 'rgb(156, 163, 175)'},
      },
    },
  };
}
