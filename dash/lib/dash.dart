/// DASH - A modern admin panel framework for Dart
///
/// Dash provides a powerful and elegant way to create beautiful admin
/// interfaces for your Dart applications and websites, inspired by FilamentPHP.
library;

// Actions
export 'src/actions/action.dart';
export 'src/actions/action_color.dart';
export 'src/actions/action_size.dart';
export 'src/actions/prebuilt/cancel_action.dart';
export 'src/actions/prebuilt/create_action.dart';
export 'src/actions/prebuilt/delete_action.dart';
export 'src/actions/prebuilt/edit_action.dart';
export 'src/actions/prebuilt/save_action.dart';
export 'src/actions/prebuilt/view_action.dart';
// Auth
export 'src/auth/auth_service.dart' show AuthService, DashUser, Session;
// Components
export 'src/components/layout.dart';
export 'src/components/pages/dashboard_page.dart';
export 'src/components/pages/login_page.dart';
export 'src/components/pages/resource_form.dart';
export 'src/components/pages/resource_index.dart';
export 'src/components/partials/button.dart';
export 'src/components/partials/heroicon.dart';
export 'src/components/partials/table/table_components.dart';
export 'src/database/connectors/sqlite_connector.dart';
export 'src/database/database_config.dart';
// Database
export 'src/database/database_connector.dart';
export 'src/database/migration_config.dart';
export 'src/database/migrations/builders/sqlite_migration_builder.dart';
export 'src/database/migrations/inspectors/sqlite_schema_inspector.dart';
export 'src/database/migrations/migration_builder.dart';
export 'src/database/migrations/migration_runner.dart';
export 'src/database/migrations/schema_definition.dart';
export 'src/database/migrations/schema_inspector.dart';
export 'src/database/query_builder.dart';
export 'src/database/schema_builder.dart';
export 'src/form/fields/checkbox.dart';
export 'src/form/fields/date_picker.dart';
export 'src/form/fields/field.dart';
export 'src/form/fields/form_renderer.dart';
export 'src/form/fields/section.dart';
export 'src/form/fields/select.dart';
export 'src/form/fields/text_input.dart';
export 'src/form/fields/textarea.dart';
export 'src/form/fields/toggle.dart';
// Forms
export 'src/form/form_schema.dart';
// Models
export 'src/model/annotations.dart';
export 'src/model/model.dart';
export 'src/model/model_metadata.dart';
export 'src/model/model_query_builder.dart';
export 'src/model/soft_deletes.dart';
// Panel
export 'src/panel/dev_console.dart';
export 'src/panel/panel.dart';
export 'src/panel/panel_config.dart';
export 'src/panel/panel_router.dart';
export 'src/panel/panel_server.dart';
export 'src/panel/request_handler.dart';
export 'src/resource.dart';
// Service Locator
export 'src/service_locator.dart' show inject, registerResourceFactory;
// Table
export 'src/table/columns/boolean_column.dart';
export 'src/table/columns/column.dart' show TableColumn, ColumnAlignment;
export 'src/table/columns/icon_column.dart';
export 'src/table/columns/text_column.dart';
export 'src/table/table.dart';
// Utils
export 'src/utils/sanitization.dart';
// Validation
export 'src/validation/validation.dart';
