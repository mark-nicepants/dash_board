import 'dart:async';

import 'package:dash_board/src/actions/action.dart';
import 'package:dash_board/src/actions/handler/action_context.dart';
import 'package:dash_board/src/actions/handler/action_handler_registry.dart';
import 'package:dash_board/src/actions/prebuilt/delete_action.dart';
import 'package:dash_board/src/actions/prebuilt/edit_action.dart';
import 'package:dash_board/src/actions/prebuilt/toggle_boolean_action.dart';
import 'package:dash_board/src/cli/cli_logger.dart';
import 'package:dash_board/src/components/interactive/interactive_component.dart';
import 'package:dash_board/src/components/partials/breadcrumbs.dart';
import 'package:dash_board/src/components/partials/page_scaffold.dart';
import 'package:dash_board/src/components/partials/pagination.dart';
import 'package:dash_board/src/components/partials/table/column_toggle.dart';
import 'package:dash_board/src/components/partials/table/table_components.dart';
import 'package:dash_board/src/components/partials/table/table_search_input.dart';
import 'package:dash_board/src/model/model.dart';
import 'package:dash_board/src/panel/panel_config.dart';
import 'package:dash_board/src/resource.dart';
import 'package:dash_board/src/service_locator.dart';
import 'package:dash_board/src/table/table.dart';
import 'package:jaspr/jaspr.dart';

/// Resource index page for listing records.
/// Server-side renders the full page with search, sort, and pagination support.
class ResourceIndex<T extends Model> extends InteractiveComponent {
  // State properties
  String resourceSlug = '';
  String searchQuery = '';
  String sortColumn = '';
  String sortDirection = '';
  int currentPage = 1;

  // Data properties (not serialized)
  List<T> records = [];
  int totalRecords = 0;

  @override
  String get componentId => 'resource-index-$resourceSlug';

  @override
  String get componentName => 'resource-index-$resourceSlug';

  Resource<T> get resource => resourceFromSlug(resourceSlug) as Resource<T>;
  String get basePath => '${inject<PanelConfig>().path}/resources/${resource.slug}';
  Table<T> get tableConfig => resource.table(Table<T>());

  ResourceIndex({
    Resource<T>? resource,
    this.records = const [],
    this.totalRecords = 0,
    String? searchQuery,
    String? sortColumn,
    String? sortDirection,
    this.currentPage = 1,
  }) {
    if (resource != null) {
      resourceSlug = resource.slug;
    }
    this.searchQuery = searchQuery ?? '';
    this.sortColumn = sortColumn ?? '';
    this.sortDirection = sortDirection ?? '';
  }

  @override
  Map<String, dynamic> getState() => {
    'resourceSlug': resourceSlug,
    'searchQuery': searchQuery,
    'sortColumn': sortColumn,
    'sortDirection': sortDirection,
    'currentPage': currentPage,
  };

  @override
  void setState(Map<String, dynamic> state) {
    resourceSlug = state['resourceSlug'] ?? '';
    searchQuery = state['searchQuery'] ?? '';
    sortColumn = state['sortColumn'] ?? '';
    sortDirection = state['sortDirection'] ?? '';
    currentPage = state['currentPage'] ?? 1;
  }

  @override
  Map<String, Function(List<dynamic>)> getActions() => {
    'setPage': (args) {
      currentPage = args[0] as int;
      dispatch('update-url', {'url': _buildCurrentUrl()});
    },
    'sort': (args) {
      final col = args[0] as String;
      if (sortColumn == col) {
        sortDirection = sortDirection == 'asc' ? 'desc' : 'asc';
      } else {
        sortColumn = col;
        sortDirection = 'asc';
      }
      dispatch('update-url', {'url': _buildCurrentUrl()});
    },
    'executeAction': (args) async {
      final actionName = args[0] as String;
      final recordId = args[1];
      final formData = args.length > 2 ? args[2] as Map<String, dynamic>? : null;
      await _executeAction(actionName, recordId, formData ?? {});
    },
  };

  /// Executes an action handler for a specific record.
  ///
  /// This is called via DashWire when a user confirms an action.
  /// It looks up the handler, executes it, and dispatches result events.
  Future<void> _executeAction(String actionName, dynamic recordId, Map<String, dynamic> formData) async {
    // Look up the handler
    final handler = ActionHandlerRegistry.getForRoute(resourceSlug, actionName);
    if (handler == null) {
      dispatch('action-error', {'message': 'Action handler not found: $actionName'});
      return;
    }

    // Find the record
    final record = await resource.findRecord(recordId is String ? int.tryParse(recordId) ?? recordId : recordId);
    if (record == null) {
      dispatch('action-error', {'message': 'Record not found: $recordId'});
      return;
    }

    // Build the action context
    final context = ActionContext(
      record: record,
      data: formData,
      resourceSlug: resourceSlug,
      actionName: actionName,
      basePath: basePath,
    );

    try {
      // Validate if the handler has validation
      final validationError = await handler.validate(context);
      if (validationError != null) {
        dispatch('action-error', {'message': validationError});
        return;
      }

      // Execute before hook
      await handler.beforeHandle(context);

      // Execute the handler
      final result = await handler.handle(context);

      // Execute after hook
      await handler.afterHandle(context, result);

      // Dispatch result
      if (result.success) {
        dispatch('action-success', {'message': result.message ?? 'Action completed successfully'});
      } else {
        dispatch('action-error', {'message': result.message ?? 'Action failed'});
      }

      // Handle redirect if specified
      if (result.redirectUrl != null) {
        dispatch('redirect', {'url': result.redirectUrl});
      }
    } catch (e) {
      cliLogException(e);
      dispatch('action-error', {'message': 'Action failed: $e'});
    }
  }

  @override
  Future<void> updated(String property) async {
    if (property == 'searchQuery') {
      currentPage = 1;
      dispatch('update-url', {'url': _buildCurrentUrl()});
    }
  }

  @override
  Future<void> prepare() async {
    // Register action handlers for this resource
    // This must happen before action dispatch
    _registerActionHandlers();
  }

  @override
  Future<void> beforeRender() async {
    // Fetch fresh data right before rendering
    records = await resource.getRecords(
      searchQuery: searchQuery,
      sortColumn: sortColumn,
      sortDirection: sortDirection,
      page: currentPage,
    );
    totalRecords = await resource.getRecordsCount(searchQuery: searchQuery);
  }

  /// Registers all action handlers from the table config.
  void _registerActionHandlers() {
    final actions = tableConfig.hasActions()
        ? tableConfig.getActions()
        : <Action<T>>[EditAction.make<T>(), DeleteAction.make<T>(resource.singularLabel.toLowerCase())];

    for (final action in actions) {
      if (action.hasHandler()) {
        action.registerHandler(resourceSlug);
      }
    }

    // Register the toggle-boolean handler for clickable columns
    ActionHandlerRegistry.register(
      resourceSlug: resourceSlug,
      actionName: 'toggle-boolean',
      handler: ToggleBooleanHandler<T>(),
    );
  }

  String _buildCurrentUrl() {
    final params = <String>[
      if (sortColumn.isNotEmpty) 'sort=$sortColumn',
      if (sortDirection.isNotEmpty) 'direction=$sortDirection',
      if (searchQuery.isNotEmpty) 'search=$searchQuery',
      if (currentPage != 1) 'page=$currentPage',
    ];
    return params.isEmpty ? basePath : '$basePath?${params.join('&')}';
  }

  @override
  Component render() {
    return ResourcePageScaffold(
      title: resource.label,
      breadcrumbs: [
        BreadCrumbItem(label: resource.label, url: basePath),
        const BreadCrumbItem(label: 'List'),
      ],
      actions: resource.indexHeaderActions().map((action) => action.renderAsHeaderAction(basePath: basePath)).toList(),
      children: [_buildTableWithPagination()],
    );
  }

  /// Builds the table and pagination wrapped in a single container.
  Component _buildTableWithPagination() {
    return div(id: 'resource-table-wrapper', classes: 'flex flex-col gap-6', [_buildTableCard(), _buildPagination()]);
  }

  Component _buildTableCard() {
    final toggleableColumns = tableConfig.getColumns().where((c) => c.isToggleable()).toList();
    return div(classes: 'bg-gray-800 rounded-xl border border-gray-700', [
      div(classes: 'flex items-center justify-end gap-3 px-6 py-4 bg-gray-800 border-b border-gray-700 rounded-t-xl', [
        if (tableConfig.isSearchable()) _buildSearchBar(),
        if (toggleableColumns.isNotEmpty) ColumnToggle(columns: toggleableColumns, resourceSlug: resource.slug),
      ]),

      div(classes: 'overflow-hidden rounded-b-xl', [
        DataTable<T>(
          tableConfig: tableConfig,
          records: records,
          sortColumn: sortColumn,
          sortDirection: sortDirection,
          containerId: 'resource-table-container',
          resourceSlug: resource.slug,
          basePath: basePath,
          emptyStateIcon: resource.iconComponent,
          emptyStateHeading: 'No ${resource.label.toLowerCase()} found',
          emptyStateDescription: 'Get started by creating your first ${resource.singularLabel.toLowerCase()}.',
          rowActions: _buildRowActions,
        ),
      ]),
    ]);
  }

  Component _buildSearchBar() {
    return TableSearchInput(
      value: searchQuery,
      placeholder: tableConfig.getSearchPlaceholder(),
      modelProperty: 'searchQuery',
    );
  }

  List<Component> _buildRowActions(T record) {
    // Use actions from table config, or default to Edit + Delete
    final actions = tableConfig.hasActions()
        ? tableConfig.getActions()
        : <Action<T>>[EditAction.make<T>(), DeleteAction.make<T>(resource.singularLabel.toLowerCase())];

    return actions
        .where((action) => action.isVisible(record))
        .map((action) => action.render(record, basePath: basePath, resourceSlug: resourceSlug))
        .toList();
  }

  Component _buildPagination() {
    if (!tableConfig.isPaginated()) return div([]);

    return Pagination.make(
      currentPage: currentPage,
      totalRecords: totalRecords,
      perPage: tableConfig.getRecordsPerPage(),
      onPageClick: (page) => 'setPage($page)',
    );
  }
}
