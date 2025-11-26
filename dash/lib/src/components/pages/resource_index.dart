import 'package:dash/src/components/partials/breadcrumbs.dart';
import 'package:dash/src/components/partials/button.dart';
import 'package:dash/src/components/partials/column_toggle.dart';
import 'package:dash/src/components/partials/page_header.dart';
import 'package:dash/src/components/partials/table/table_components.dart';
import 'package:dash/src/model/model.dart';
import 'package:dash/src/resource.dart';
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

  String get basePath => '/admin/resources/${resource.slug}';
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
    return div(classes: 'flex flex-col gap-6', [
      _buildBreadcrumbs(),
      _buildHeader(),
      _buildTableCard(),
      _buildPagination(),
    ]);
  }

  Component _buildBreadcrumbs() {
    return BreadCrumbs(
      items: [
        BreadCrumbItem(label: resource.label, url: basePath),
        const BreadCrumbItem(label: 'List'),
      ],
    );
  }

  Component _buildHeader() {
    return PageHeader(
      title: resource.label,
      actions: [
        Button(label: 'New ${resource.singularLabel}', variant: ButtonVariant.primary, href: '$basePath/create'),
      ],
    );
  }

  Component _buildTableCard() {
    final toggleableColumns = tableConfig.getColumns().where((c) => c.isToggleable()).toList();
    return div(classes: 'bg-gray-800 rounded-xl border border-gray-700 overflow-hidden', [
      div(classes: 'flex items-center justify-end gap-3 px-6 py-4 bg-gray-800 border-b border-gray-700', [
        if (tableConfig.isSearchable()) _buildSearchBar(),
        if (toggleableColumns.isNotEmpty) ColumnToggle(columns: toggleableColumns, resourceSlug: resource.slug),
      ]),
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
    ]);
  }

  Component _buildSearchBar() {
    return div(classes: 'flex-1 max-w-xs', [
      input(
        type: InputType.text,
        classes:
            'w-full px-3 py-2 bg-gray-900 border border-gray-700 rounded-lg text-sm text-gray-200 placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-lime-500 focus:border-transparent transition-all',
        value: searchQuery ?? '',
        name: 'search',
        attributes: {
          'placeholder': tableConfig.getSearchPlaceholder(),
          'hx-get': basePath,
          'hx-trigger': 'keyup changed delay:300ms',
          'hx-target': '#resource-table-container',
          'hx-select': '#resource-table-container',
          'hx-swap': 'outerHTML',
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
    final recordId = _getRecordId(record);
    return [
      // Edit button
      a(
        href: '$basePath/$recordId/edit',
        classes:
            'inline-flex items-center px-3 py-1.5 text-xs font-medium text-gray-300 hover:text-white bg-gray-700 hover:bg-gray-600 rounded-md transition-colors',
        [text('Edit')],
      ),
      // Delete button (with confirmation)
      form(action: '$basePath/$recordId/delete', method: FormMethod.post, classes: 'inline', [
        button(
          type: ButtonType.submit,
          classes:
              'inline-flex items-center px-3 py-1.5 text-xs font-medium text-red-400 hover:text-white bg-gray-700 hover:bg-red-600 rounded-md transition-colors',
          attributes: {
            'onclick':
                "return confirm('Are you sure you want to delete this ${resource.singularLabel.toLowerCase()}?')",
          },
          [text('Delete')],
        ),
      ]),
    ];
  }

  /// Gets the record's primary key value.
  dynamic _getRecordId(T record) {
    final fields = record.toMap();
    final primaryKey = record.primaryKey;
    return fields[primaryKey];
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
              'hx-target': '#resource-table-container',
              'hx-select': '#resource-table-container',
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
                      'hx-target': '#resource-table-container',
                      'hx-select': '#resource-table-container',
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
              'hx-target': '#resource-table-container',
              'hx-select': '#resource-table-container',
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
