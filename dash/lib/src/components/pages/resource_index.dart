import 'package:dash/src/actions/action.dart';
import 'package:dash/src/actions/prebuilt/delete_action.dart';
import 'package:dash/src/actions/prebuilt/edit_action.dart';
import 'package:dash/src/components/partials/breadcrumbs.dart';
import 'package:dash/src/components/partials/page_header.dart';
import 'package:dash/src/components/partials/pagination.dart';
import 'package:dash/src/components/partials/table/column_toggle.dart';
import 'package:dash/src/components/partials/table/table_components.dart';
import 'package:dash/src/components/partials/table/table_search_input.dart';
import 'package:dash/src/model/model.dart';
import 'package:dash/src/panel/panel_config.dart';
import 'package:dash/src/resource.dart';
import 'package:dash/src/service_locator.dart';
import 'package:dash/src/table/table.dart';
import 'package:jaspr/jaspr.dart';

/// Resource index page for listing records.
/// Server-side renders the full page with search, sort, and pagination support.
class ResourceIndex<T extends Model> extends StatelessComponent {
  final Resource<T> resource;
  final List<T> records;
  final int totalRecords;
  final String? searchQuery;
  final String? sortColumn;
  final String? sortDirection;
  final int currentPage;

  String get basePath => '${inject<PanelConfig>().path}/resources/${resource.slug}';
  Table<T> get tableConfig => resource.table(Table<T>());

  const ResourceIndex({
    required this.resource,
    required this.records,
    this.totalRecords = 0,
    this.searchQuery,
    this.sortColumn,
    this.sortDirection,
    this.currentPage = 1,
    super.key,
  });

  @override
  Component build(BuildContext context) {
    return div(classes: 'flex flex-col gap-6', [_buildHeader(), _buildTableWithPagination()]);
  }

  /// Builds the table and pagination wrapped in a single container.
  Component _buildTableWithPagination() {
    return div(id: 'resource-table-wrapper', classes: 'flex flex-col gap-6', [_buildTableCard(), _buildPagination()]);
  }

  Component _buildHeader() {
    final headerActions = resource.indexHeaderActions();
    return PageHeader(
      title: resource.label,
      breadcrumbs: BreadCrumbs(
        items: [
          BreadCrumbItem(label: resource.label, url: basePath),
          const BreadCrumbItem(label: 'List'),
        ],
      ),
      actions: headerActions.map((action) => action.renderAsHeaderAction(basePath: basePath)).toList(),
    );
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
          onSortUrl: _buildSortUrl,
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
    return TableSearchInput(value: searchQuery, placeholder: tableConfig.getSearchPlaceholder());
  }

  String _buildSortUrl(String column, String direction) {
    final params = <String>[
      'sort=$column',
      'direction=$direction',
      if (searchQuery != null && searchQuery!.isNotEmpty) 'search=$searchQuery',
      if (currentPage != 1) 'page=$currentPage',
    ];
    return '$basePath?${params.join('&')}';
  }

  List<Component> _buildRowActions(T record) {
    // Use actions from table config, or default to Edit + Delete
    final actions = tableConfig.hasActions()
        ? tableConfig.getActions()
        : <Action<T>>[EditAction.make<T>(), DeleteAction.make<T>(resource.singularLabel.toLowerCase())];

    return actions
        .where((action) => action.isVisible(record))
        .map((action) => action.render(record, basePath: basePath))
        .toList();
  }

  Component _buildPagination() {
    if (!tableConfig.isPaginated()) return div([]);

    return Pagination(
      currentPage: currentPage,
      totalRecords: totalRecords,
      perPage: tableConfig.getRecordsPerPage(),
      buildPageUrl: _buildPageUrl,
    );
  }

  String _buildPageUrl(int newPage) {
    final params = <String>[
      if (sortColumn != null) 'sort=$sortColumn',
      if (sortColumn != null) 'direction=${sortDirection ?? 'asc'}',
      if (searchQuery != null && searchQuery!.isNotEmpty) 'search=$searchQuery',
      if (newPage != 1) 'page=$newPage',
    ];
    return params.isEmpty ? basePath : '$basePath?${params.join('&')}';
  }
}
