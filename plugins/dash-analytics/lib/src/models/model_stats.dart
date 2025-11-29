import 'package:dash/dash.dart';
import 'package:dash_analytics/src/models/period.dart';

/// A data point representing an aggregated metric value for a period.
class MetricDataPoint {
  /// Creates a new metric data point.
  const MetricDataPoint({required this.period, required this.value});

  /// The start of the period this data point represents.
  final DateTime period;

  /// The aggregated value for this period.
  final double value;

  @override
  String toString() => 'MetricDataPoint($period: $value)';
}

/// A fluent API for querying model statistics.
///
/// Provides period-based aggregations for counting model records.
///
/// Example:
/// ```dart
/// // Count new users per day for the last 7 days
/// final stats = await ModelStats<User>()
///   .period(Period.day)
///   .last(7)
///   .count();
///
/// // Count active users per month
/// final activeUsers = await ModelStats<User>()
///   .period(Period.month)
///   .where('is_active', 1)
///   .count();
/// ```
class ModelStats<T extends Model> {
  /// Creates a new ModelStats instance.
  ///
  /// The generic type [T] must be a registered Model with a factory.
  ModelStats() : _connector = Model.connector, _instance = _createModelInstance<T>();

  /// Creates a ModelStats instance with an existing model instance.
  ///
  /// Example:
  /// ```dart
  /// final stats = ModelStats.of(User.empty());
  /// ```
  ModelStats.of(this._instance) : _connector = Model.connector;
  final DatabaseConnector _connector;
  final T _instance;
  Period _period = Period.day;
  int _lastPeriods = 7;
  DateTime? _startDate;
  DateTime? _endDate;
  String _dateColumn = 'created_at';
  final List<String> _wheres = [];
  final List<dynamic> _bindings = [];

  static T _createModelInstance<T extends Model>() {
    // This relies on the model being registered with the service locator
    // The model must have an empty factory constructor
    throw UnimplementedError(
      'ModelStats requires a model factory. '
      'Use ModelStats.of(modelInstance) or register the model factory.',
    );
  }

  /// Sets the aggregation period.
  ModelStats<T> period(Period period) {
    _period = period;
    return this;
  }

  /// Sets the number of past periods to query.
  /// Calculates the date range based on the current date and period.
  ModelStats<T> last(int periods) {
    _lastPeriods = periods;
    _endDate = DateTime.now();
    _startDate = _calculateStartDate(_endDate!, _period, periods);
    return this;
  }

  /// Sets a custom date range.
  ModelStats<T> between(DateTime start, DateTime end) {
    _startDate = start;
    _endDate = end;
    return this;
  }

  /// Sets the column to use for date filtering (defaults to 'created_at').
  ModelStats<T> dateColumn(String column) {
    _dateColumn = column;
    return this;
  }

  /// Adds a WHERE clause to filter records.
  ModelStats<T> where(String column, dynamic value, [String operator = '=']) {
    _wheres.add('$column $operator ?');
    _bindings.add(value);
    return this;
  }

  /// Adds a WHERE NULL clause.
  ModelStats<T> whereNull(String column) {
    _wheres.add('$column IS NULL');
    return this;
  }

  /// Adds a WHERE NOT NULL clause.
  ModelStats<T> whereNotNull(String column) {
    _wheres.add('$column IS NOT NULL');
    return this;
  }

  /// Counts records grouped by period.
  ///
  /// Returns a list of [MetricDataPoint] with counts for each period.
  Future<List<MetricDataPoint>> count() async {
    _ensureDateRange();

    final dateFormat = _connector.dateTrunc(_dateColumn, _period.granularity);
    final table = _instance.table;

    final whereClause = _buildWhereClause();
    final sql =
        '''
      SELECT $dateFormat as period, COUNT(*) as count
      FROM $table
      $whereClause
      GROUP BY period
      ORDER BY period ASC
    ''';

    final results = await _connector.query(sql, _bindings);

    // Convert results to data points
    final dataPoints = <String, double>{};
    for (final row in results) {
      final periodStr = row['period']?.toString() ?? '';
      final count = (row['count'] as num?)?.toDouble() ?? 0;
      dataPoints[periodStr] = count;
    }

    // Fill in missing periods with zero
    return _fillMissingPeriods(dataPoints);
  }

  /// Sums a column grouped by period.
  Future<List<MetricDataPoint>> sum(String column) async {
    _ensureDateRange();

    final dateFormat = _connector.dateTrunc(_dateColumn, _period.granularity);
    final table = _instance.table;

    final whereClause = _buildWhereClause();
    final sql =
        '''
      SELECT $dateFormat as period, SUM($column) as total
      FROM $table
      $whereClause
      GROUP BY period
      ORDER BY period ASC
    ''';

    final results = await _connector.query(sql, _bindings);

    final dataPoints = <String, double>{};
    for (final row in results) {
      final periodStr = row['period']?.toString() ?? '';
      final total = (row['total'] as num?)?.toDouble() ?? 0;
      dataPoints[periodStr] = total;
    }

    return _fillMissingPeriods(dataPoints);
  }

  /// Returns the total count for the date range (not grouped).
  Future<int> total() async {
    _ensureDateRange();

    final table = _instance.table;
    final whereClause = _buildWhereClause();
    final sql = 'SELECT COUNT(*) as count FROM $table $whereClause';

    final results = await _connector.query(sql, _bindings);
    return (results.first['count'] as num?)?.toInt() ?? 0;
  }

  /// Compares the current period's count to the previous period.
  ///
  /// Returns a map with 'current', 'previous', and 'change' (percentage).
  Future<Map<String, dynamic>> compare() async {
    _ensureDateRange();

    final currentTotal = await total();

    // Calculate previous period range
    final periodDuration = _endDate!.difference(_startDate!);
    final previousStart = _startDate!.subtract(periodDuration);
    final previousEnd = _startDate!;

    // Query previous period
    final previousStats = ModelStats<T>.of(_instance)
      ..between(previousStart, previousEnd)
      ..dateColumn(_dateColumn);

    // Copy where clauses
    for (var i = 0; i < _wheres.length; i++) {
      previousStats._wheres.add(_wheres[i]);
      previousStats._bindings.add(_bindings[i]);
    }

    final previousTotal = await previousStats.total();

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

    // Add date range to bindings
    _wheres.insert(0, '$_dateColumn BETWEEN ? AND ?');
    _bindings.insert(0, _startDate!.toIso8601String());
    _bindings.insert(1, _endDate!.toIso8601String());
  }

  String _buildWhereClause() {
    if (_wheres.isEmpty) return '';
    return 'WHERE ${_wheres.join(' AND ')}';
  }

  DateTime _calculateStartDate(DateTime end, Period p, int count) {
    return switch (p) {
      Period.hour => end.subtract(Duration(hours: count)),
      Period.day => end.subtract(Duration(days: count)),
      Period.week => end.subtract(Duration(days: count * 7)),
      Period.month => DateTime(end.year, end.month - count, end.day),
      Period.year => DateTime(end.year - count, end.month, end.day),
    };
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
    return switch (_period) {
      Period.hour => '${date.year}-${_pad(date.month)}-${_pad(date.day)} ${_pad(date.hour)}:00:00',
      Period.day => '${date.year}-${_pad(date.month)}-${_pad(date.day)}',
      Period.week => '${date.year}-${_pad(date.month)}-${_pad(date.day)}',
      Period.month => '${date.year}-${_pad(date.month)}-01',
      Period.year => '${date.year}-01-01',
    };
  }

  String _pad(int value) => value.toString().padLeft(2, '0');
}
