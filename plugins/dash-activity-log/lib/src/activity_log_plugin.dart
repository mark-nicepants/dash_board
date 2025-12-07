import 'package:dash_board/dash_board.dart';
import 'package:dash_activity_log/src/models/activity.dart';
import 'package:dash_activity_log/src/resources/activity_resource.dart';

/// Activity logging plugin for Dash.
///
/// This plugin automatically logs all model CRUD operations to an
/// `activities` table for audit trail purposes.
///
/// ## Usage
///
/// ```dart
/// final panel = Panel()
///   ..plugin(ActivityLogPlugin.make());
/// ```
///
/// ## Configuration
///
/// ```dart
/// panel.plugin(
///   ActivityLogPlugin.make()
///     .excludeTables(['sessions', 'cache', 'settings'])
///     .retentionDays(90)
///     .logDescription(true)
/// );
/// ```
class ActivityLogPlugin implements Plugin {
  List<String> _excludedTables = ['activities', 'sessions', 'settings', 'dash_metrics'];
  int? _retentionDays;
  bool _logDescription = true;

  ActivityLogPlugin();

  /// Creates a new ActivityLogPlugin instance.
  static ActivityLogPlugin make() => ActivityLogPlugin();

  /// Tables to exclude from activity logging.
  ///
  /// By default, excludes `activities`, `sessions`, and `settings` tables
  /// to prevent recursive logging and noise.
  ActivityLogPlugin excludeTables(List<String> tables) {
    _excludedTables = [..._excludedTables, ...tables];
    return this;
  }

  /// Sets the retention period for activity logs.
  ///
  /// Activities older than this will be automatically deleted.
  /// Set to `null` to keep all activities indefinitely.
  ActivityLogPlugin retentionDays(int? days) {
    _retentionDays = days;
    return this;
  }

  /// Whether to include a human-readable description in logs.
  ActivityLogPlugin logDescription(bool enabled) {
    _logDescription = enabled;
    return this;
  }

  @override
  String getId() => 'dash-activity-log';

  @override
  void register(Panel panel) {
    // Register the Activity model schema for auto-migration
    panel.registerSchemas([Activity.activitySchema]);

    // Register the Activity resource for viewing logs
    panel.registerResources([ActivityResource()]);

    // Register model and resource in the DI container
    inject.registerFactory<Model>(Activity.empty, instanceName: 'model:activities');
    inject.registerSingleton<Resource>(ActivityResource(), instanceName: 'resource:activities');

    // Add navigation item
    panel.navigationItems([
      NavigationItem.make(
        'Activity Log',
      ).url('${panel.path}/resources/activities').icon(HeroIcons.clipboardDocumentList).group('System'),
    ]);
  }

  @override
  Future<void> boot(Panel panel) async {
    final dispatcher = EventDispatcher.instance;

    // Listen to model created events
    dispatcher.listen<ModelCreatedEvent>((event) async {
      if (_shouldLog(event.model.table)) {
        await _logCreated(event);
      }
    });

    // Listen to model updated events
    dispatcher.listen<ModelUpdatedEvent>((event) async {
      if (_shouldLog(event.model.table)) {
        await _logUpdated(event);
      }
    });

    // Listen to model deleted events
    dispatcher.listen<ModelDeletedEvent>((event) async {
      if (_shouldLog(event.table)) {
        await _logDeleted(event);
      }
    });

    // Clean up old activities if retention is set
    if (_retentionDays != null) {
      await _cleanupOldActivities();
    }
  }

  /// Checks if a table should be logged.
  bool _shouldLog(String table) {
    return !_excludedTables.contains(table);
  }

  /// Logs a model creation event.
  Future<void> _logCreated(ModelCreatedEvent event) async {
    final model = event.model;
    final modelType = model.runtimeType.toString();

    await Activity.log(
      event: '${model.table}.created',
      subjectType: modelType,
      subjectId: _getIntId(model.getKey()),
      causerId: event.causerId?.toString(),
      description: _logDescription ? '$modelType created' : null,
      properties: {'new': model.toMap()},
    );
  }

  /// Logs a model update event.
  Future<void> _logUpdated(ModelUpdatedEvent event) async {
    final model = event.model;
    final modelType = model.runtimeType.toString();

    final properties = <String, dynamic>{'after': model.toMap()};

    if (event.beforeState != null) {
      properties['before'] = event.beforeState;
    }

    if (event.changes != null && event.changes!.isNotEmpty) {
      properties['changes'] = event.changes;
    }

    await Activity.log(
      event: '${model.table}.updated',
      subjectType: modelType,
      subjectId: _getIntId(model.getKey()),
      causerId: event.causerId?.toString(),
      description: _logDescription ? '$modelType updated' : null,
      properties: properties,
    );
  }

  /// Logs a model deletion event.
  Future<void> _logDeleted(ModelDeletedEvent event) async {
    await Activity.log(
      event: '${event.table}.deleted',
      subjectType: event.modelType,
      subjectId: _getIntId(event.modelId),
      causerId: event.causerId?.toString(),
      description: _logDescription ? '${event.modelType} deleted' : null,
      properties: {'deleted': event.deletedData},
    );
  }

  /// Converts a dynamic ID to int if possible.
  int? _getIntId(dynamic id) {
    if (id == null) return null;
    if (id is int) return id;
    if (id is String) return int.tryParse(id);
    return null;
  }

  /// Cleans up activities older than the retention period.
  Future<void> _cleanupOldActivities() async {
    if (_retentionDays == null) return;

    final cutoffDate = DateTime.now().subtract(Duration(days: _retentionDays!));
    final cutoffStr = cutoffDate.toIso8601String();

    try {
      await Model.connector.delete('activities', where: 'created_at < ?', whereArgs: [cutoffStr]);
    } catch (e) {
      // Table might not exist yet on first run
      print('[ActivityLogPlugin] Failed to cleanup old activities: $e');
    }
  }
}
