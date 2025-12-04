import 'package:dash/dash.dart';
import 'package:dash_activity_log/dash_activity_log.dart';
import 'package:dash_analytics/dash_analytics.dart';
import 'package:dash_example/models/models.dart';
import 'package:dash_example/pages/settings_page.dart';

Future<void> main() async {
  print('🚀 Dash Example Admin Panel\n');

  // Register all models (resources are auto-registered)
  registerAllModels();

  // Create and configure the admin panel
  await Panel()
      .applyConfig()
      .authModel<User>()
      .registerPages([SettingsPage.make()])
      .plugin(
        AnalyticsPlugin.make() //
            .enableDashboardWidget(true)
            .trackPageViews(true)
            .trackModelEvents(true)
            .retentionDays(90),
      )
      .plugin(
        ActivityLogPlugin.make() //
            .logDescription(true),
      )
      .serve(host: 'localhost', port: 8080);
}
