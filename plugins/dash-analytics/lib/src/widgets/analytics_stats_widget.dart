import 'package:dash/dash.dart';
import 'package:dash_analytics/src/metrics_service.dart';

/// Analytics stats widget showing page views, visitors, and more.
///
/// This widget displays real-time statistics from the MetricsService
/// when available, or placeholder stats when no metrics are recorded.
///
/// ## Example
///
/// ```dart
/// panel.widgets([
///   AnalyticsStatsWidget.make(),
/// ]);
/// ```
class AnalyticsStatsWidget extends StatsOverviewWidget {
  /// Cached stats data.
  List<Stat>? _cachedStats;

  /// Factory method to create a new AnalyticsStatsWidget instance.
  static AnalyticsStatsWidget make() => AnalyticsStatsWidget();

  @override
  int get sort => -1; // Show at top

  @override
  String? get heading => 'Analytics Overview';

  @override
  String? get description => 'Real-time visitor statistics';

  @override
  List<Stat> getStats() {
    // Return cached stats if available
    if (_cachedStats != null) return _cachedStats!;

    return _getPlaceholderStats();
  }

  List<Stat> _getPlaceholderStats() {
    return [
      Stat.make(
        'Page Views',
        '-',
      ).icon(HeroIcons.eye).description('No data available').descriptionColor('gray').chartColor('cyan'),
      Stat.make(
        'Unique Visitors',
        '-',
      ).icon(HeroIcons.users).description('No data available').descriptionColor('gray').chartColor('violet'),
      Stat.make(
        'Bounce Rate',
        '-',
      ).icon(HeroIcons.arrowTrendingDown).description('No data available').descriptionColor('gray').chartColor('amber'),
    ];
  }

  @override
  Future<void> preload() async {
    if (!inject.isRegistered<MetricsService>()) {
      return;
    }

    final metrics = inject<MetricsService>();

    try {
      // Fetch page views for last 7 days
      final pageViewsComparison = await metrics.query('page_views').last(7).compare();
      final pageViewsData = await metrics.query('page_views').period(Period.day).last(10).getData();

      final pageViewsTotal = pageViewsComparison['current'] as double;
      final pageViewsChange = pageViewsComparison['change'] as double;
      final pageViewsChartData = pageViewsData.map((p) => p.value.toDouble()).toList();

      // Determine change direction
      final isIncrease = pageViewsChange >= 0;
      final changeText = isIncrease
          ? '+${pageViewsChange.toStringAsFixed(0)}% from last week'
          : '${pageViewsChange.toStringAsFixed(0)}% from last week';

      _cachedStats = [
        Stat.make('Page Views', _formatNumber(pageViewsTotal.toInt()))
            .icon(HeroIcons.eye)
            .description(changeText)
            .descriptionIcon(isIncrease ? HeroIcons.arrowTrendingUp : HeroIcons.arrowTrendingDown)
            .descriptionColor(isIncrease ? 'green' : 'red')
            .chart(pageViewsChartData.isEmpty ? [0.0] : pageViewsChartData)
            .chartColor('cyan'),
        // Add more stats as we track them
        Stat.make(
          'Unique Visitors',
          '-',
        ).icon(HeroIcons.users).description('Coming soon').descriptionColor('gray').chartColor('violet'),
        Stat.make(
          'Bounce Rate',
          '-',
        ).icon(HeroIcons.arrowTrendingDown).description('Coming soon').descriptionColor('gray').chartColor('amber'),
      ];
    } catch (e) {
      // On error, leave cached stats null so placeholder is shown
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
