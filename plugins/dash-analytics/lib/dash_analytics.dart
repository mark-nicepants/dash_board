/// Dash Analytics - Analytics plugin for Dash admin panel framework.
///
/// Provides dashboard widgets for page views, visitors, traffic sources,
/// and more. Easy to integrate and customize.
///
/// ## Getting Started
///
/// ```dart
/// import 'package:dash_board/dash_board.dart';
/// import 'package:dash_analytics/dash_analytics.dart';
///
/// final panel = Panel()
///   ..plugins([
///     AnalyticsPlugin.make()
///       .trackingId('UA-12345678')
///       .enableDashboardWidget(true),
///   ]);
/// ```
library;

// Plugin
export 'src/analytics_plugin.dart';
// Metrics Service & Models
export 'src/metrics_service.dart';
export 'src/models/metric.dart';
export 'src/models/model_stats.dart';
export 'src/models/period.dart';
// Widgets
export 'src/widgets/analytics_stats_widget.dart';
export 'src/widgets/page_views_chart_widget.dart';
export 'src/widgets/traffic_sources_chart_widget.dart';
