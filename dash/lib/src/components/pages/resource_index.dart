import 'package:dash/src/actions/action.dart';
import 'package:dash/src/actions/prebuilt/delete_action.dart';
import 'package:dash/src/actions/prebuilt/edit_action.dart';
import 'package:dash/src/components/partials/breadcrumbs.dart';
import 'package:dash/src/components/partials/page_header.dart';
import 'package:dash/src/components/partials/table/column_toggle.dart';
import 'package:dash/src/components/partials/table/table_components.dart';
import 'package:dash/src/model/model.dart';
import 'package:dash/src/panel/panel_config.dart';
import 'package:dash/src/resource.dart';
import 'package:dash/src/service_locator.dart';
import 'package:dash/src/table/table.dart';
import 'package:jaspr/jaspr.dart';

/// Resource index page with HTMX-powered interactivity.
/// Server-side renders the full page, HTMX handles partial updates for search, sort, pagination.
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

  /// Builds the table and pagination wrapped in a single container for HTMX updates.
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
          emptyStateIcon: resource.iconComponent,
          emptyStateHeading: 'No ${resource.label.toLowerCase()} found',
          emptyStateDescription: 'Get started by creating your first ${resource.singularLabel.toLowerCase()}.',
          rowActions: _buildRowActions,
        ),
      ]),
    ]);
  }

  Component _buildSearchBar() {
    final primary = panelColors.primary;
    return div(classes: 'flex-1 max-w-xs', [
      input(
        id: 'resource-search-input',
        type: InputType.text,
        classes:
            'w-full px-3 py-2 bg-gray-900 border border-gray-700 rounded-lg text-sm text-gray-200 placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-$primary-500 focus:border-transparent transition-all',
        value: searchQuery ?? '',
        name: 'search',
        attributes: {
          'placeholder': tableConfig.getSearchPlaceholder(),
          'hx-get': basePath,
          'hx-trigger': 'keyup changed delay:300ms',
          'hx-target': '#resource-table-wrapper',
          'hx-select': '#resource-table-wrapper',
          'hx-swap': 'outerHTML',
          'hx-on::after-swap':
              'document.getElementById("resource-search-input")?.focus(); '
              'document.getElementById("resource-search-input")?.setSelectionRange(-1, -1)',
        },
      ),
    ]);
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
    if (!tableConfig.isPaginated() || totalRecords == 0) return div([]);
    final perPage = tableConfig.getRecordsPerPage();
    final totalPages = (totalRecords / perPage).ceil();
    if (totalPages <= 1) return div([]);
    return div(classes: 'flex justify-between items-center px-6 py-4 border-t border-gray-700', [
      div(classes: 'text-sm text-gray-400', [text('Page $currentPage of $totalPages ($totalRecords total)')]),
      div(classes: 'flex gap-2', [
        if (currentPage > 1)
          a(
            href: _buildPageUrl(currentPage - 1),
            classes:
                'inline-flex items-center justify-center gap-2 px-3 py-1.5 text-sm font-medium bg-gray-700 text-gray-300 hover:bg-gray-600 hover:text-gray-100 rounded-lg transition-all',
            attributes: {
              'hx-get': _buildPageUrl(currentPage - 1),
              'hx-target': '#resource-table-wrapper',
              'hx-select': '#resource-table-wrapper',
              'hx-swap': 'outerHTML',
              'hx-push-url': 'true',
            },
            [text('← Previous')],
          )
        else
          span(
            classes:
                'inline-flex items-center justify-center gap-2 px-3 py-1.5 text-sm font-medium bg-gray-700 text-gray-300 opacity-50 cursor-not-allowed rounded-lg',
            [text('← Previous')],
          ),
        for (var i = 1; i <= totalPages; i++)
          if (_shouldShowPage(i, currentPage, totalPages))
            i != currentPage
                ? a(
                    href: _buildPageUrl(i),
                    classes:
                        'inline-flex items-center justify-center gap-2 px-3 py-1.5 text-sm font-medium bg-gray-700 text-gray-300 hover:bg-gray-600 hover:text-gray-100 rounded-lg transition-all',
                    attributes: {
                      'hx-get': _buildPageUrl(i),
                      'hx-target': '#resource-table-wrapper',
                      'hx-select': '#resource-table-wrapper',
                      'hx-swap': 'outerHTML',
                      'hx-push-url': 'true',
                    },
                    [text('$i')],
                  )
                : span(
                    classes:
                        'inline-flex items-center justify-center gap-2 px-3 py-1.5 text-sm font-semibold bg-gray-900 text-gray-100 rounded-lg border border-gray-700',
                    [text('$i')],
                  )
          else if (i == currentPage - 2 || i == currentPage + 2)
            span(classes: 'flex items-center px-2 text-gray-600', [text('...')]),
        if (currentPage < totalPages)
          a(
            href: _buildPageUrl(currentPage + 1),
            classes:
                'inline-flex items-center justify-center gap-2 px-3 py-1.5 text-sm font-medium bg-gray-700 text-gray-300 hover:bg-gray-600 hover:text-gray-100 rounded-lg transition-all',
            attributes: {
              'hx-get': _buildPageUrl(currentPage + 1),
              'hx-target': '#resource-table-wrapper',
              'hx-select': '#resource-table-wrapper',
              'hx-swap': 'outerHTML',
              'hx-push-url': 'true',
            },
            [text('Next →')],
          )
        else
          span(
            classes:
                'inline-flex items-center justify-center gap-2 px-3 py-1.5 text-sm font-medium bg-gray-700 text-gray-300 opacity-50 cursor-not-allowed rounded-lg',
            [text('Next →')],
          ),
      ]),
    ]);
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

  bool _shouldShowPage(int p, int current, int total) {
    if (p == 1 || p == total) return true;
    if (p >= current - 1 && p <= current + 1) return true;
    return false;
  }
}
