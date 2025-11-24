import 'package:get_it/get_it.dart';

import 'database/database_connector.dart';
import 'panel/panel_config.dart';

/// Global service locator instance.
final inject = GetIt.instance;

/// Sets up dependency injection for the Dash framework.
///
/// This registers core services like:
/// - PanelConfig: The panel configuration
/// - DatabaseConnector: The database connection
///
/// Call this during Panel.boot() before starting the server.
void setupServiceLocator({required PanelConfig config, required DatabaseConnector connector}) {
  // Register panel config as singleton
  if (!inject.isRegistered<PanelConfig>()) {
    inject.registerSingleton<PanelConfig>(config);
  }

  // Register database connector as singleton
  if (!inject.isRegistered<DatabaseConnector>()) {
    inject.registerSingleton<DatabaseConnector>(connector);
  }
}

/// Resets the service locator (useful for testing).
Future<void> resetServiceLocator() async {
  await inject.reset();
}
