import 'dart:convert';

import 'package:dash_board/dash_board.dart';

/// Type of metric being recorded.
enum MetricType {
  /// A counter that only increases (e.g., page views, total events).
  counter,

  /// A gauge that can increase or decrease (e.g., active users, memory usage).
  gauge,

  /// A histogram for distribution data (e.g., response times).
  histogram,
}

/// A model for storing time-series metric data.
///
/// Metrics are used to track statistics over time, supporting counters,
/// gauges, and histograms with optional tags for filtering.
///
/// Example:
/// ```dart
/// // Record a page view
/// final metric = Metric(
///   name: 'page_views',
///   type: MetricType.counter,
///   value: 1,
///   tags: {'path': '/dashboard', 'user_agent': 'Chrome'},
/// );
/// await metric.save();
///
/// // Query metrics
/// final pageViews = await Metric.query()
///   .where('name', 'page_views')
///   .whereBetween('recorded_at', startDate, endDate)
///   .get();
/// ```
class Metric extends Model {
  Metric({this.id, required this.name, this.type = MetricType.counter, this.value = 1, this.tags, DateTime? recordedAt})
    : recordedAt = recordedAt ?? DateTime.now();

  /// Factory constructor for creating empty instances.
  /// Used internally by query builder.
  factory Metric.empty() => Metric(name: '');
  @override
  String get table => 'dash_metrics';

  @override
  String get primaryKey => 'id';

  @override
  bool get timestamps => false;

  int? id;
  String name;
  MetricType type;
  double value;
  Map<String, dynamic>? tags;
  DateTime recordedAt;

  /// Creates a new query builder for Metric.
  static ModelQueryBuilder<Metric> query() {
    return ModelQueryBuilder<Metric>(
      Model.connector,
      modelFactory: Metric.empty,
      modelTable: 'dash_metrics',
      modelPrimaryKey: 'id',
    );
  }

  /// Finds a metric by its primary key.
  static Future<Metric?> find(int id) async {
    return query().find(id);
  }

  @override
  dynamic getKey() => id;

  @override
  void setKey(dynamic value) {
    id = value as int?;
  }

  @override
  List<String> getFields() {
    return ['id', 'name', 'type', 'value', 'tags', 'recorded_at'];
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'value': value,
      'tags': tags != null ? jsonEncode(tags) : null,
      'recorded_at': recordedAt.toIso8601String(),
    };
  }

  @override
  void fromMap(Map<String, dynamic> map) {
    id = getFromMap<int>(map, 'id');
    name = getFromMap<String>(map, 'name') ?? '';
    type = MetricType.values.firstWhere((t) => t.name == map['type'], orElse: () => MetricType.counter);
    value = (map['value'] as num?)?.toDouble() ?? 0;
    final tagsValue = map['tags'];
    if (tagsValue != null && tagsValue is String && tagsValue.isNotEmpty) {
      tags = jsonDecode(tagsValue) as Map<String, dynamic>?;
    } else {
      tags = null;
    }
    recordedAt = parseDateTime(map['recorded_at']) ?? DateTime.now();
  }

  Metric copyWith({
    int? id,
    String? name,
    MetricType? type,
    double? value,
    Map<String, dynamic>? tags,
    DateTime? recordedAt,
  }) {
    return Metric(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      value: value ?? this.value,
      tags: tags ?? this.tags,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }

  @override
  String toString() => 'Metric($name: $value at $recordedAt)';

  /// Gets the table schema for automatic migrations.
  ///
  /// This allows the metrics table to be created automatically
  /// using Dash's migration system instead of hardcoded SQL.
  @override
  TableSchema get schema {
    return const TableSchema(
      name: 'dash_metrics',
      columns: [
        ColumnDefinition(name: 'id', type: ColumnType.integer, isPrimaryKey: true, autoIncrement: true, nullable: true),
        ColumnDefinition(name: 'name', type: ColumnType.text, nullable: false),
        ColumnDefinition(name: 'type', type: ColumnType.text, nullable: false, defaultValue: 'counter'),
        ColumnDefinition(name: 'value', type: ColumnType.real, nullable: false, defaultValue: 1),
        ColumnDefinition(name: 'tags', type: ColumnType.text, nullable: true),
        ColumnDefinition(name: 'recorded_at', type: ColumnType.text, nullable: false),
      ],
      indexes: [
        IndexDefinition(name: 'idx_metrics_name', columns: ['name']),
        IndexDefinition(name: 'idx_metrics_recorded_at', columns: ['recorded_at']),
        IndexDefinition(name: 'idx_metrics_name_recorded', columns: ['name', 'recorded_at']),
      ],
    );
  }
}
