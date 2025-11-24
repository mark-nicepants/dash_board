/// DASH - A modern admin panel framework for Dart
///
/// Dash provides a powerful and elegant way to create beautiful admin
/// interfaces for your Dart applications and websites, inspired by FilamentPHP.
library;

// Auth
export 'src/auth/auth_service.dart';
// Components
export 'src/components/heroicon.dart';
export 'src/components/layout.dart';
export 'src/components/pages/dashboard_page.dart';
export 'src/components/pages/login_page.dart';
export 'src/components/pages/resource_index.dart';
export 'src/components/styles.dart';
export 'src/database/connectors/sqlite_connector.dart';
export 'src/database/database_config.dart';
// Database
export 'src/database/database_connector.dart';
export 'src/database/query_builder.dart';
// Models
export 'src/model/annotations.dart';
export 'src/model/model.dart';
export 'src/model/model_query_builder.dart';
export 'src/model/soft_deletes.dart';
export 'src/page.dart';
export 'src/panel/panel.dart';
export 'src/panel/panel_config.dart';
export 'src/panel/panel_router.dart';
export 'src/panel/panel_server.dart';
export 'src/panel/request_handler.dart';
export 'src/resource.dart';
// Service Locator
export 'src/service_locator.dart' show inject;
// Table
export 'src/table/columns/boolean_column.dart';
export 'src/table/columns/column.dart' show TableColumn, ColumnAlignment;
export 'src/table/columns/icon_column.dart';
export 'src/table/columns/text_column.dart';
export 'src/table/table.dart';
// Validation
export 'src/validation/validation.dart';
