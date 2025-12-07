import 'package:dash_activity_log/dash_activity_log.dart';
import 'package:dash_analytics/dash_analytics.dart';
import 'package:dash_board/dash_board.dart';
import 'package:dash_example/models/models.dart';
import 'package:dash_example/pages/settings_page.dart';

Future<void> main() async {
  print('🚀 Dash Example Admin Panel\n');

  // Register all generated models
  registerAllModels();

  // Create and configure the admin panel
  await Panel()
      .applyConfig()
      .authModel<User>()
      .registerPages([SettingsPage.make()])
      .plugins([
        // Analytics
        AnalyticsPlugin.make()
            .enableDashboardWidget(true)
            .trackPageViews(true)
            .trackModelEvents(true)
            .retentionDays(90),

        // Audit trails
        ActivityLogPlugin.make().logDescription(true),
      ])
      .serve(host: 'localhost', port: 8080);
}
