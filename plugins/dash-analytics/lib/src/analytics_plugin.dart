import 'package:dash_analytics/src/metrics_service.dart';
import 'package:dash_analytics/src/widgets/analytics_stats_widget.dart';
import 'package:dash_analytics/src/widgets/page_views_chart_widget.dart';
import 'package:dash_analytics/src/widgets/traffic_sources_chart_widget.dart';
import 'package:dash_board/dash_board.dart';

export 'package:dash_analytics/src/metrics_service.dart';

/// Analytics plugin for Dash admin panel.
///
/// This plugin provides:
/// - Metrics storage and querying API
/// - Dashboard widgets for page views, visitors, and bounce rate stats
/// - Line chart for weekly page view trends
/// - Doughnut chart for traffic source breakdown
/// - Custom navigation item in sidebar
/// - Optional automatic page view and model event tracking
///
/// ## Basic Usage
///
/// ```dart
/// final panel = Panel()
///   ..plugins([
///     AnalyticsPlugin.make()
///       .enableDashboardWidget(true)
///       .trackPageViews(true)
///       .trackModelEvents(true),
///   ]);
/// ```
///
/// ## Manual Metrics Recording
///
/// ```dart
/// final metrics = inject<MetricsService>();
///
/// // Record a custom metric
/// await metrics.increment('button_clicks', tags: {'button': 'signup'});
///
/// // Query metrics
/// final clicks = await metrics.query('button_clicks').last(7).sum();
/// ```
class AnalyticsPlugin implements Plugin {
  bool _dashboardWidgetEnabled = false;

  bool _trackPageViews = true;
  bool _trackModelEvents = true;
  int _retentionDays = 90;

  MetricsService? _metricsService;

  /// Factory method to create a new AnalyticsPlugin instance.
  static AnalyticsPlugin make() => AnalyticsPlugin();

  // ============================================================
  // Configuration Methods (Fluent API)
  // ============================================================

  /// Enables or disables the dashboard widgets.
  AnalyticsPlugin enableDashboardWidget([bool enabled = true]) {
    _dashboardWidgetEnabled = enabled;
    return this;
  }

  /// Enables or disables automatic page view tracking.
  ///
  /// When enabled, page views are automatically recorded for each request.
  AnalyticsPlugin trackPageViews([bool enabled = true]) {
    _trackPageViews = enabled;
    return this;
  }

  /// Enables or disables automatic model event tracking.
  ///
  /// When enabled, model create/update/delete events are automatically recorded.
  AnalyticsPlugin trackModelEvents([bool enabled = true]) {
    _trackModelEvents = enabled;
    return this;
  }

  /// Sets the number of days to retain metrics.
  ///
  /// Set to 0 to retain metrics forever.
  AnalyticsPlugin retentionDays(int days) {
    _retentionDays = days;
    return this;
  }

  // ============================================================
  // Configuration Getters
  // ============================================================

  /// Whether the dashboard widget is enabled.
  bool get hasDashboardWidget => _dashboardWidgetEnabled;

  /// Whether page view tracking is enabled.
  bool get hasPageViewTracking => _trackPageViews;

  /// Whether model event tracking is enabled.
  bool get hasModelEventTracking => _trackModelEvents;

  /// The configured metrics service instance.
  MetricsService? get metricsService => _metricsService;

  // ============================================================
  // Plugin Implementation
  // ============================================================

  @override
  String getId() => 'analytics';

  @override
  void register(Panel panel) {
    // Register the metrics table schema for auto-migration
    panel.registerSchemas([Metric.empty().schema]);

    // Register dashboard widgets if enabled
    if (_dashboardWidgetEnabled) {
      panel.widgets([AnalyticsStatsWidget.make(), PageViewsChartWidget.make(), TrafficSourcesChartWidget.make()]);
    }
  }

  @override
  Future<void> boot(Panel panel) async {
    // Get the database connector
    final connector = inject<DatabaseConnector>();

    // Create the metrics service with configuration
    final config = MetricsConfig(
      trackPageViews: _trackPageViews,
      trackModelEvents: _trackModelEvents,
      retentionDays: _retentionDays,
    );

    _metricsService = MetricsService(connector, config: config);

    // Note: Table creation is handled by auto-migrations via Metric.schema
    // registered in register() above.

    // Register the metrics service in the service locator
    if (!inject.isRegistered<MetricsService>()) {
      inject.registerSingleton<MetricsService>(_metricsService!);
    }

    // Register request hook for page view tracking
    if (_trackPageViews) {
      panel.onRequest((request) async {
        // Only track GET requests to HTML pages
        final path = request.requestedUri.path;
        if (request.method == 'GET' && !_isAssetPath(path)) {
          final userAgent = request.headers['user-agent'] ?? '';
          final deviceType = _parseDeviceType(userAgent);
          final browser = _parseBrowser(userAgent);

          await _metricsService!.pageView(
            path,
            extras: {'method': request.method, 'device_type': deviceType, 'browser': browser},
          );
        }
      });
    }

    // Register model event hooks for tracking
    if (_trackModelEvents) {
      // Use EventDispatcher directly so we can filter out the metrics table
      // to prevent infinite recursion
      final dispatcher = EventDispatcher.instance;

      dispatcher.listen<ModelCreatedEvent>((event) async {
        if (event.model.table != 'dash_metrics') {
          await _metricsService!.modelCreated(event.model.runtimeType.toString());
        }
      });

      dispatcher.listen<ModelUpdatedEvent>((event) async {
        if (event.model.table != 'dash_metrics') {
          await _metricsService!.modelUpdated(event.model.runtimeType.toString());
        }
      });

      dispatcher.listen<ModelDeletedEvent>((event) async {
        if (event.table != 'dash_metrics') {
          await _metricsService!.modelDeleted(event.table);
        }
      });
    }

    // ignore: avoid_print
  }

  /// Checks if the path is a static asset path.
  bool _isAssetPath(String path) {
    return path.endsWith('.css') ||
        path.endsWith('.js') ||
        path.endsWith('.ico') ||
        path.endsWith('.png') ||
        path.endsWith('.jpg') ||
        path.endsWith('.svg') ||
        path.endsWith('.woff') ||
        path.endsWith('.woff2') ||
        path.contains('/storage/');
  }

  /// Parses the device type from a user agent string.
  String _parseDeviceType(String userAgent) {
    final ua = userAgent.toLowerCase();
    if (ua.contains('mobile') || ua.contains('android') && !ua.contains('tablet')) {
      return 'mobile';
    } else if (ua.contains('tablet') || ua.contains('ipad')) {
      return 'tablet';
    }
    return 'desktop';
  }

  /// Parses the browser name from a user agent string.
  String _parseBrowser(String userAgent) {
    final ua = userAgent.toLowerCase();
    if (ua.contains('edg/') || ua.contains('edge/')) {
      return 'Edge';
    } else if (ua.contains('chrome/') && !ua.contains('chromium/')) {
      return 'Chrome';
    } else if (ua.contains('safari/') && !ua.contains('chrome/')) {
      return 'Safari';
    } else if (ua.contains('firefox/')) {
      return 'Firefox';
    } else if (ua.contains('opera/') || ua.contains('opr/')) {
      return 'Opera';
    }
    return 'Other';
  }
}
