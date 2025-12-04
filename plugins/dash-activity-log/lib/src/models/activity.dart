import 'dart:convert';

import 'package:dash/dash.dart';

/// Represents an activity log entry in the database.
///
/// Activities track model CRUD operations and other significant
/// events in the system for audit trail purposes.
///
/// Each activity includes:
/// - The event name (e.g., 'users.created')
/// - Subject information (model type and ID)
/// - Causer information (who triggered the event)
/// - Properties (before/after state for changes)
class Activity extends Model {
  int? id;
  String event = '';
  String subjectType = '';
  int? subjectId;
  String? causerId;
  String? causerType;
  String? description;
  String? properties;

  Activity({
    this.id,
    this.event = '',
    this.subjectType = '',
    this.subjectId,
    this.causerId,
    this.causerType,
    this.description,
    this.properties,
  });

  factory Activity.empty() => Activity();

  @override
  String get table => 'activities';

  @override
  bool get timestamps => false; // We manage created_at manually

  @override
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (id != null) map['id'] = id;
    map['event'] = event;
    map['subject_type'] = subjectType;
    if (subjectId != null) map['subject_id'] = subjectId;
    if (causerId != null) map['causer_id'] = causerId;
    if (causerType != null) map['causer_type'] = causerType;
    if (description != null) map['description'] = description;
    if (properties != null) map['properties'] = properties;
    if (createdAt != null) map['created_at'] = createdAt!.toIso8601String();
    return map;
  }

  @override
  Activity fromMap(Map<String, dynamic> map) {
    id = map['id'] as int?;
    event = map['event'] as String? ?? '';
    subjectType = map['subject_type'] as String? ?? '';
    subjectId = map['subject_id'] as int?;
    causerId = map['causer_id'] as String?;
    causerType = map['causer_type'] as String?;
    description = map['description'] as String?;
    properties = map['properties'] as String?;
    final createdAtStr = map['created_at'] as String?;
    if (createdAtStr != null) {
      createdAt = DateTime.tryParse(createdAtStr);
    }
    return this;
  }

  @override
  dynamic getKey() => id;

  @override
  void setKey(dynamic key) {
    id = key as int?;
  }

  @override
  List<String> getFields() => [
    'id',
    'event',
    'subject_type',
    'subject_id',
    'causer_id',
    'causer_type',
    'description',
    'properties',
    'created_at',
  ];

  /// Returns the schema definition for the activities table.
  @override
  TableSchema get schema => activitySchema;

  /// Static schema definition for the activities table.
  static TableSchema get activitySchema => const TableSchema(
    name: 'activities',
    columns: [
      ColumnDefinition(name: 'id', type: ColumnType.integer, isPrimaryKey: true, autoIncrement: true),
      ColumnDefinition(name: 'event', type: ColumnType.text, nullable: false),
      ColumnDefinition(name: 'subject_type', type: ColumnType.text, nullable: false),
      ColumnDefinition(name: 'subject_id', type: ColumnType.integer, nullable: true),
      ColumnDefinition(name: 'causer_id', type: ColumnType.text, nullable: true),
      ColumnDefinition(name: 'causer_type', type: ColumnType.text, nullable: true),
      ColumnDefinition(name: 'description', type: ColumnType.text, nullable: true),
      ColumnDefinition(name: 'properties', type: ColumnType.text, nullable: true),
      ColumnDefinition(name: 'created_at', type: ColumnType.text, nullable: true),
    ],
    indexes: [
      IndexDefinition(name: 'idx_activities_event', columns: ['event']),
      IndexDefinition(name: 'idx_activities_subject', columns: ['subject_type', 'subject_id']),
      IndexDefinition(name: 'idx_activities_created', columns: ['created_at']),
    ],
  );

  /// Parses the properties JSON into a Map.
  Map<String, dynamic> getPropertiesMap() {
    if (properties == null || properties!.isEmpty) {
      return {};
    }
    try {
      return jsonDecode(properties!) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  /// Gets a human-readable description of the activity.
  String getDescription() {
    if (description != null && description!.isNotEmpty) {
      return description!;
    }

    final action = event.split('.').lastOrNull ?? event;
    return '$subjectType $action';
  }

  /// Gets the action type from the event name.
  String getActionType() {
    return event.split('.').lastOrNull ?? event;
  }

  /// Creates a query builder for activities.
  static ModelQueryBuilder<Activity> query() {
    return ModelQueryBuilder<Activity>(
      Model.connector,
      modelFactory: () => Activity(),
      modelTable: 'activities',
      modelPrimaryKey: 'id',
    );
  }

  /// Gets activities for a specific subject.
  static Future<List<Activity>> forSubject(String type, int id) async {
    return query().where('subject_type', '=', type).where('subject_id', '=', id).orderBy('created_at', 'DESC').get();
  }

  /// Gets recent activities.
  static Future<List<Activity>> recent({int limit = 50}) async {
    return query().orderBy('created_at', 'DESC').limit(limit).get();
  }

  /// Logs a new activity.
  static Future<Activity> log({
    required String event,
    required String subjectType,
    int? subjectId,
    String? causerId,
    String? causerType,
    String? description,
    Map<String, dynamic>? properties,
  }) async {
    final activity = Activity(
      event: event,
      subjectType: subjectType,
      subjectId: subjectId,
      causerId: causerId,
      causerType: causerType,
      description: description,
      properties: properties != null ? jsonEncode(properties) : null,
    );
    await activity.save();
    return activity;
  }
}
