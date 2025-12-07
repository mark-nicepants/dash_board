import 'package:dash_analytics/src/metrics_service.dart';
import 'package:dash_board/dash_board.dart';

/// Page views line chart widget showing weekly traffic trends.
///
/// Displays a comparison of page views between this week and last week
/// using Chart.js line chart. Shows real data when available, or an
/// empty placeholder chart otherwise.
///
/// ## Example
///
/// ```dart
/// panel.widgets([
///   PageViewsChartWidget.make(),
/// ]);
/// ```
class PageViewsChartWidget extends LineChartWidget {
  /// Cached chart data.
  ChartData? _cachedData;

  /// Factory method to create a new PageViewsChartWidget instance.
  static PageViewsChartWidget make() => PageViewsChartWidget();

  @override
  int get sort => 10;

  @override
  int get columnSpan => 8;

  @override
  String? get heading => 'Page Views';

  @override
  String? get description => 'Weekly page view trends';

  @override
  ChartData getData() {
    if (_cachedData != null) return _cachedData!;
    return _getEmptyData();
  }

  ChartData _getEmptyData() {
    return const ChartData(
      labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
      datasets: [
        ChartDataset(
          label: 'This Week',
          data: [0, 0, 0, 0, 0, 0, 0],
          borderColor: 'rgb(6, 182, 212)',
          backgroundColor: 'rgba(6, 182, 212, 0.1)',
          tension: 0.3,
          fill: true,
        ),
        ChartDataset(
          label: 'Last Week',
          data: [0, 0, 0, 0, 0, 0, 0],
          borderColor: 'rgb(156, 163, 175)',
          backgroundColor: 'rgba(156, 163, 175, 0.05)',
          tension: 0.3,
          fill: true,
        ),
      ],
    );
  }

  @override
  Future<void> preload() async {
    if (!inject.isRegistered<MetricsService>()) {
      return;
    }

    final metrics = inject<MetricsService>();

    // Get this week's data
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final thisWeekStart = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

    // Get last week's data
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
    final lastWeekEnd = thisWeekStart;

    // Query this week
    final thisWeekData = await metrics.query('page_views').period(Period.day).between(thisWeekStart, now).getData();

    // Query last week
    final lastWeekData = await metrics
        .query('page_views')
        .period(Period.day)
        .between(lastWeekStart, lastWeekEnd)
        .getData();

    // Build chart data
    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final thisWeekValues = List<num>.filled(7, 0);
    final lastWeekValues = List<num>.filled(7, 0);

    for (final point in thisWeekData) {
      final dayIndex = point.period.weekday - 1;
      if (dayIndex >= 0 && dayIndex < 7) {
        thisWeekValues[dayIndex] = point.value;
      }
    }

    for (final point in lastWeekData) {
      final dayIndex = point.period.weekday - 1;
      if (dayIndex >= 0 && dayIndex < 7) {
        lastWeekValues[dayIndex] = point.value;
      }
    }

    _cachedData = ChartData(
      labels: dayLabels,
      datasets: [
        ChartDataset(
          label: 'This Week',
          data: thisWeekValues,
          borderColor: 'rgb(6, 182, 212)',
          backgroundColor: 'rgba(6, 182, 212, 0.1)',
          tension: 0.3,
          fill: true,
        ),
        ChartDataset(
          label: 'Last Week',
          data: lastWeekValues,
          borderColor: 'rgb(156, 163, 175)',
          backgroundColor: 'rgba(156, 163, 175, 0.05)',
          tension: 0.3,
          fill: true,
        ),
      ],
    );
  }
}
