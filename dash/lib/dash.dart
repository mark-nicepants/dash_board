/// DASH - A modern admin panel framework for Dart
///
/// Dash provides a powerful and elegant way to create beautiful admin
/// interfaces for your Dart applications and websites, inspired by FilamentPHP.
library;

// Actions
export 'src/actions/action.dart';
export 'src/actions/action_color.dart';
export 'src/actions/action_group.dart';
export 'src/actions/action_size.dart';
export 'src/actions/handler/action_context.dart';
export 'src/actions/handler/action_handler.dart';
export 'src/actions/handler/action_handler_registry.dart';
export 'src/actions/prebuilt/cancel_action.dart';
export 'src/actions/prebuilt/create_action.dart';
export 'src/actions/prebuilt/delete_action.dart';
export 'src/actions/prebuilt/edit_action.dart';
export 'src/actions/prebuilt/save_action.dart';
export 'src/actions/prebuilt/toggle_boolean_action.dart';
export 'src/actions/prebuilt/view_action.dart';
// Auth
export 'src/auth/auth_service.dart' show AuthService, Session;
export 'src/auth/authenticatable.dart';
export 'src/auth/session_helper.dart';
export 'src/auth/session_store.dart' show SessionStore, FileSessionStore, InMemorySessionStore, SessionData;
// Components
export 'src/components/interactive/interactive.dart';
export 'src/components/layout.dart';
export 'src/components/pages/dashboard_page.dart';
export 'src/components/pages/login_page.dart';
export 'src/components/pages/resource_form.dart';
export 'src/components/pages/resource_index.dart';
export 'src/components/pages/resource_view.dart';
export 'src/components/partials/breadcrumbs.dart';
export 'src/components/partials/button.dart';
export 'src/components/partials/card.dart';
export 'src/components/partials/heroicon.dart';
// Modals
export 'src/components/partials/modal/modal.dart';
export 'src/components/partials/modal/modal_size.dart';
export 'src/components/partials/page_header.dart';
export 'src/components/partials/page_scaffold.dart';
export 'src/components/partials/table/table_components.dart';
export 'src/components/partials/user_menu.dart';
// Context (Request-scoped state via Zones)
export 'src/context/request_context.dart';
// Database
export 'src/database/connectors/sqlite/sqlite_connector.dart';
export 'src/database/database_config.dart';
// Database
export 'src/database/database_connector.dart';
export 'src/database/database_connector_cli.dart';
export 'src/database/migrations/migration_builder.dart';
export 'src/database/migrations/migration_config.dart';
export 'src/database/migrations/migration_runner.dart';
export 'src/database/migrations/schema_definition.dart';
export 'src/database/migrations/schema_inspector.dart';
export 'src/database/query_builder.dart';
export 'src/database/schema_builder.dart';
// Events
export 'src/events/events.dart';
export 'src/form/fields/checkbox.dart';
export 'src/form/fields/date_picker.dart';
export 'src/form/fields/field.dart';
export 'src/form/fields/file_upload.dart';
export 'src/form/fields/form_renderer.dart';
export 'src/form/fields/grid.dart';
export 'src/form/fields/has_many_select.dart';
export 'src/form/fields/relationship_select.dart';
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
// Pages (Custom Pages)
export 'src/page/page.dart';
// Panel
export 'src/panel/panel.dart' show Panel, RequestCallback, CustomRouteHandler, ModelCallback;
export 'src/panel/panel_colors.dart';
export 'src/panel/panel_config.dart';
export 'src/panel/panel_config_loader.dart';
export 'src/panel/panel_router.dart';
export 'src/panel/panel_server.dart';
export 'src/panel/request_handler.dart';
// Plugins
export 'src/plugin/asset.dart';
export 'src/plugin/navigation_item.dart';
export 'src/plugin/plugin.dart';
export 'src/plugin/render_hook.dart';
export 'src/resource.dart';
// Service Locator
export 'src/service_locator.dart' show inject, modelInstanceFromSlug, trackModelSlug, buildRegisteredResources;
// Settings
export 'src/settings/settings_service.dart';
// Storage
export 'src/storage/storage.dart';
// Table
export 'src/table/columns/boolean_column.dart';
export 'src/table/columns/column.dart' show TableColumn, ColumnAlignment;
export 'src/table/columns/icon_column.dart';
export 'src/table/columns/image_column.dart';
export 'src/table/columns/text_column.dart';
export 'src/table/table.dart';
// Utils
export 'src/utils/sanitization.dart';
// Validation
export 'src/validation/validation.dart';
// Widgets
export 'src/widgets/chart_widget.dart';
export 'src/widgets/stat.dart';
export 'src/widgets/stats_overview_widget.dart';
export 'src/widgets/widget.dart';
export 'src/widgets/widget_configuration.dart';
