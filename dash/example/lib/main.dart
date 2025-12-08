import 'dart:io';

import 'package:dash_activity_log/dash_activity_log.dart';
import 'package:dash_analytics/dash_analytics.dart';
import 'package:dash_example/models/models.dart';
import 'package:dash_example/pages/settings_page.dart';
import 'package:dash_panel/dash_panel.dart';

Future<void> main() async {
  print('🚀 Dash Example Admin Panel\n');

  // Register all generated models
  registerAllModels();

  // Create and configure the admin panel
  var panel = Panel().applyConfig();

  if (Platform.environment['DASH_TEST_MODE'] == 'true') {
    print('🧪 Running in TEST MODE with in-memory database');
    panel = panel.database(
      DatabaseConfig.using(SqliteConnector(':memory:'), migrations: MigrationConfig.fromResources(verbose: true)),
    );
  }

  panel = panel.authModel<User>().registerPages([SettingsPage.make()]).plugins([
    // Analytics
    AnalyticsPlugin.make().enableDashboardWidget(true).trackPageViews(true).trackModelEvents(true).retentionDays(90),

    // Audit trails
    ActivityLogPlugin.make().logDescription(true),
  ]);

  if (Platform.environment['DASH_TEST_MODE'] == 'true') {
    await panel.boot();
    print('🌱 Seeding test user...');
    final user = User(name: 'Admin User', email: 'admin@example.com', password: '', role: 'admin', isActive: true);

    user.setPassword('password');
    await user.save();
    print('✅ Test user seeded');
  }

  await panel.serve(host: 'localhost', port: 8080);
}
