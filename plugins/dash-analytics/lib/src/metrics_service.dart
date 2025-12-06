import 'package:dash/dash.dart';
import 'package:dash_analytics/src/models/metric.dart';
import 'package:dash_analytics/src/models/model_stats.dart';
import 'package:dash_analytics/src/models/period.dart';

export 'package:dash_analytics/src/models/metric.dart';
export 'package:dash_analytics/src/models/model_stats.dart';
export 'package:dash_analytics/src/models/period.dart';

/// Configuration for the MetricsService.
class MetricsConfig {
  /// Creates a new metrics configuration.
  const MetricsConfig({this.trackPageViews = true, this.trackModelEvents = true, this.retentionDays = 90});

  /// Whether to track page views automatically.
  final bool trackPageViews;

  /// Whether to track model CRUD events automatically.
  final bool trackModelEvents;

  /// How long to retain metrics (in days). Set to 0 to retain forever.
  final int retentionDays;

  /// Default configuration with all tracking enabled.
  static const defaults = MetricsConfig();

  /// Configuration with all automatic tracking disabled.
  static const manual = MetricsConfig(trackPageViews: false, trackModelEvents: false);
}

/// A service for recording and querying metrics.
///
/// The MetricsService provides a fluent API for recording metrics and
/// querying aggregated data. It stores metrics in the `dash_metrics` table.
///
/// ## Recording Metrics
///
/// ```dart
/// final metrics = inject<MetricsService>();
///
/// // Increment a counter
/// await metrics.increment('page_views', tags: {'path': '/dashboard'});
///
/// // Record a gauge value
/// await metrics.gauge('active_users', 42);
///
/// // Record with custom timestamp
/// await metrics.record(
///   name: 'response_time',
///   value: 150.5,
///   type: MetricType.histogram,
///   tags: {'endpoint': '/api/users'},
/// );
/// ```
///
/// ## Querying Metrics
///
/// ```dart
/// // Get total page views for the last 7 days
/// final total = await metrics.query('page_views').last(7).sum();
///
/// // Get page views grouped by day
/// final daily = await metrics.query('page_views')
///   .period(Period.day)
///   .last(7)
///   .getData();
///
/// // Get page views for a specific path
/// final dashboardViews = await metrics.query('page_views')
///   .tag('path', '/dashboard')
///   .last(30)
///   .sum();
/// ```
class MetricsService {
  /// Creates a new MetricsService instance.
  MetricsService(this._connector, {this.config = MetricsConfig.defaults});
  final DatabaseConnector _connector;
  final MetricsConfig config;

  // ============================================================
  // Recording Methods
  // ============================================================

  /// Records a metric with the given parameters.
  Future<void> record({
    required String name,
    double value = 1,
    MetricType type = MetricType.counter,
    Map<String, dynamic>? tags,
    DateTime? recordedAt,
  }) async {
    final metric = Metric(name: name, type: type, value: value, tags: tags, recordedAt: recordedAt);
    await metric.save();
  }

  /// Increments a counter metric by the given amount.
  Future<void> increment(String name, {double amount = 1, Map<String, dynamic>? tags}) async {
    await record(name: name, value: amount, type: MetricType.counter, tags: tags);
  }

  /// Records a gauge metric with an absolute value.
  Future<void> gauge(String name, double value, {Map<String, dynamic>? tags}) async {
    await record(name: name, value: value, type: MetricType.gauge, tags: tags);
  }

  /// Records a histogram metric (for tracking distributions).
  Future<void> histogram(String name, double value, {Map<String, dynamic>? tags}) async {
    await record(name: name, value: value, type: MetricType.histogram, tags: tags);
  }

  // ============================================================
  // Query Methods
  // ============================================================

  /// Creates a new query for the given metric name.
  MetricQuery query(String name) => MetricQuery(_connector, name);

  // ============================================================
  // Built-in Metric Names
  // ============================================================

  /// Records a page view.
  Future<void> pageView(String path, {Map<String, dynamic>? extras}) async {
    await increment('page_views', tags: {'path': path, ...?extras});
  }

  /// Records a model creation event.
  Future<void> modelCreated(String modelName, {Map<String, dynamic>? extras}) async {
    await increment('model_created', tags: {'model': modelName, ...?extras});
  }

  /// Records a model update event.
  Future<void> modelUpdated(String modelName, {Map<String, dynamic>? extras}) async {
    await increment('model_updated', tags: {'model': modelName, ...?extras});
  }

  /// Records a model deletion event.
  Future<void> modelDeleted(String modelName, {Map<String, dynamic>? extras}) async {
    await increment('model_deleted', tags: {'model': modelName, ...?extras});
  }

  /// Records a login event.
  Future<void> login({String? userId, Map<String, dynamic>? extras}) async {
    await increment('logins', tags: {'user_id': userId, ...?extras});
  }

  // ============================================================
  // Maintenance Methods
  // ============================================================

  /// Cleans up old metrics based on retention settings.
  Future<int> cleanup() async {
    if (config.retentionDays <= 0) return 0;

    final cutoffDate = DateTime.now().subtract(Duration(days: config.retentionDays));
    final result = await _connector.delete(
      'dash_metrics',
      where: 'recorded_at < ?',
      whereArgs: [cutoffDate.toIso8601String()],
    );
    return result;
  }
}

/// A fluent query builder for metrics.
///
/// Uses [Metric.query()] internally for database-agnostic queries.
/// This ensures compatibility with future database connectors
/// (MySQL, PostgreSQL, MSSQL, etc.).
class MetricQuery {
  MetricQuery(this._connector, this._name);
  final DatabaseConnector _connector;
  final String _name;
  Period _period = Period.day;
  int _lastPeriods = 7;
  DateTime? _startDate;
  DateTime? _endDate;
  final Map<String, dynamic> _tagFilters = {};
  MetricType? _type;

  /// Sets the aggregation period.
  MetricQuery period(Period period) {
    _period = period;
    return this;
  }

  /// Sets the number of past periods to query.
  MetricQuery last(int periods) {
    _lastPeriods = periods;
    _endDate = DateTime.now();
    _startDate = _calculateStartDate(_endDate!, _period, periods);
    return this;
  }

  /// Sets a custom date range.
  MetricQuery between(DateTime start, DateTime end) {
    _startDate = start;
    _endDate = end;
    return this;
  }

  /// Filters by a specific tag value.
  MetricQuery tag(String key, dynamic value) {
    _tagFilters[key] = value;
    return this;
  }

  /// Filters by metric type.
  MetricQuery type(MetricType type) {
    _type = type;
    return this;
  }

  /// Builds the base query with common filters applied.
  ModelQueryBuilder<Metric> _buildBaseQuery() {
    _ensureDateRange();

    var query = Metric.query()
        .where('name', '=', _name)
        .whereBetween('recorded_at', _startDate!.toIso8601String(), _endDate!.toIso8601String());

    if (_type != null) {
      query = query.where('type', '=', _type!.name);
    }

    // Apply tag filters using JSON path extraction
    for (final entry in _tagFilters.entries) {
      query = query.whereJsonPath('tags', entry.key, entry.value);
    }

    return query;
  }

  /// Returns the sum of metric values.
  Future<double> sum() async {
    final query = _buildBaseQuery();
    return (await query.sum('value')).toDouble();
  }

  /// Returns the count of metric records.
  Future<int> count() async {
    final query = _buildBaseQuery();
    return await query.count();
  }

  /// Returns the count of records matching a specific tag value.
  ///
  /// This is useful for counting metrics by category, e.g., device type or browser.
  Future<int> countByTag(String tagKey, String tagValue) async {
    final query = _buildBaseQuery().whereJsonPath('tags', tagKey, tagValue);
    return await query.count();
  }

  /// Returns metric data grouped by period.
  Future<List<MetricDataPoint>> getData() async {
    _ensureDateRange();

    final dateFormat = _connector.dateTrunc('recorded_at', _period.granularity);

    final query = _buildBaseQuery()
        .selectRaw('$dateFormat as period')
        .selectRaw('SUM(value) as total')
        .groupByRaw('period')
        .orderBy('period', 'ASC');

    final results = await query.getMap();

    final dataPoints = <String, double>{};
    for (final row in results) {
      final periodStr = row['period']?.toString() ?? '';
      final total = (row['total'] as num?)?.toDouble() ?? 0;
      dataPoints[periodStr] = total;
    }

    return _fillMissingPeriods(dataPoints);
  }

  /// Compares the current period to the previous period.
  ///
  /// Returns a map with 'current', 'previous', and 'change' (percentage).
  Future<Map<String, dynamic>> compare() async {
    _ensureDateRange();

    final currentTotal = await sum();

    // Calculate previous period range
    final periodDuration = _endDate!.difference(_startDate!);
    final previousStart = _startDate!.subtract(periodDuration);
    final previousEnd = _startDate!;

    // Query previous period
    final previousQuery = MetricQuery(_connector, _name)..between(previousStart, previousEnd);

    for (final entry in _tagFilters.entries) {
      previousQuery.tag(entry.key, entry.value);
    }

    if (_type != null) {
      previousQuery.type(_type!);
    }

    final previousTotal = await previousQuery.sum();

    // Calculate percentage change
    double change = 0;
    if (previousTotal > 0) {
      change = ((currentTotal - previousTotal) / previousTotal) * 100;
    } else if (currentTotal > 0) {
      change = 100;
    }

    return {'current': currentTotal, 'previous': previousTotal, 'change': change};
  }

  void _ensureDateRange() {
    if (_startDate == null || _endDate == null) {
      _endDate = DateTime.now();
      _startDate = _calculateStartDate(_endDate!, _period, _lastPeriods);
    }
  }

  DateTime _calculateStartDate(DateTime end, Period period, int count) {
    switch (period) {
      case Period.hour:
        return end.subtract(Duration(hours: count));
      case Period.day:
        return end.subtract(Duration(days: count));
      case Period.week:
        return end.subtract(Duration(days: count * 7));
      case Period.month:
        return DateTime(end.year, end.month - count, end.day);
      case Period.year:
        return DateTime(end.year - count, end.month, end.day);
    }
  }

  List<MetricDataPoint> _fillMissingPeriods(Map<String, double> dataPoints) {
    final result = <MetricDataPoint>[];
    final periods = _period.generateRange(_startDate!, _endDate!);

    for (final periodDate in periods) {
      final key = _formatPeriodKey(periodDate);
      final value = dataPoints[key] ?? 0;
      result.add(MetricDataPoint(period: periodDate, value: value));
    }

    return result;
  }

  String _formatPeriodKey(DateTime date) {
    switch (_period) {
      case Period.hour:
        return '${date.year}-${_pad(date.month)}-${_pad(date.day)} ${_pad(date.hour)}:00:00';
      case Period.day:
        return '${date.year}-${_pad(date.month)}-${_pad(date.day)}';
      case Period.week:
        return '${date.year}-${_pad(date.month)}-${_pad(date.day)}';
      case Period.month:
        return '${date.year}-${_pad(date.month)}-01';
      case Period.year:
        return '${date.year}-01-01';
    }
  }

  String _pad(int value) => value.toString().padLeft(2, '0');
}
