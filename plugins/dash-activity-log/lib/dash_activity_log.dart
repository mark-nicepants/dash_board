/// Activity logging plugin for Dash.
///
/// This plugin provides automatic activity logging for model CRUD operations.
/// It uses the Dash Event System to capture all model changes and stores
/// them in a dedicated `activities` table for audit trails.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:dash/dash.dart';
/// import 'package:dash_activity_log/dash_activity_log.dart';
///
/// final panel = Panel()
///   ..plugin(ActivityLogPlugin.make());
/// ```
///
/// ## Configuration
///
/// ```dart
/// panel.plugin(
///   ActivityLogPlugin.make()
///     .excludeTables(['sessions', 'cache'])  // Don't log these tables
///     .retentionDays(90)                     // Auto-cleanup after 90 days
/// );
/// ```
///
/// ## Viewing Activity
///
/// The plugin adds an "Activity Log" section to the admin navigation
/// where you can view all logged activities with filtering and search.
library;

export 'src/activity_log_plugin.dart';
export 'src/models/activity.dart';
export 'src/resources/activity_resource.dart';
