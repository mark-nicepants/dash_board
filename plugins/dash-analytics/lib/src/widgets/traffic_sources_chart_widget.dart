import 'package:dash/dash.dart';
import 'package:dash_analytics/src/metrics_service.dart';

/// Traffic sources doughnut chart widget.
///
/// Displays a breakdown of where visitors come from using
/// a Chart.js doughnut chart. Shows real data when available,
/// or an empty placeholder chart otherwise.
///
/// Traffic sources are tracked via page view tags with a 'source' key:
/// ```dart
/// metrics.pageView('/dashboard', extras: {'source': 'organic'});
/// ```
///
/// ## Example
///
/// ```dart
/// panel.widgets([
///   TrafficSourcesChartWidget.make(),
/// ]);
/// ```
class TrafficSourcesChartWidget extends DoughnutChartWidget {
  /// Cached chart data.
  ChartData? _cachedData;

  /// Factory method to create a new TrafficSourcesChartWidget instance.
  static TrafficSourcesChartWidget make() => TrafficSourcesChartWidget();

  @override
  int get sort => 20;

  @override
  int get columnSpan => 4;

  @override
  String? get heading => 'Traffic Sources';

  @override
  String? get description => 'Where visitors come from';

  @override
  ChartData getData() {
    if (_cachedData != null) return _cachedData!;
    return _getEmptyData();
  }

  ChartData _getEmptyData() {
    return const ChartData(
      labels: ['No data'],
      datasets: [
        ChartDataset(
          label: 'Traffic Sources',
          data: [1],
          backgroundColor: ['rgb(107, 114, 128)'],
          borderColor: ['rgb(107, 114, 128)'],
          borderWidth: 2,
        ),
      ],
    );
  }

  @override
  Future<void> preload() async {
    if (!inject.isRegistered<MetricsService>()) {
      return;
    }

    // TODO: Source tracking requires querying by tags which needs more complex SQL
  }
}
