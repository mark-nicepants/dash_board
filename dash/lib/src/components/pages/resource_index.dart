import 'package:dash/src/components/partials/breadcrumbs.dart';
import 'package:dash/src/components/partials/button.dart';
import 'package:dash/src/components/partials/column_toggle.dart';
import 'package:dash/src/components/partials/page_header.dart';
import 'package:dash/src/model/model.dart';
import 'package:dash/src/resource.dart';
import 'package:dash/src/table/columns/boolean_column.dart';
import 'package:dash/src/table/columns/column.dart';
import 'package:dash/src/table/columns/icon_column.dart';
import 'package:dash/src/table/columns/text_column.dart';
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
      _buildTable(),
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

  Component _buildTable() {
    final columns = tableConfig.getColumns().where((c) => !c.isHidden()).toList();
    return div(
      id: 'resource-table-container',
      classes: 'overflow-x-auto border-t border-gray-700',
      attributes: {'data-table-container': 'true', 'data-resource-slug': resource.slug},
      [
        if (records.isEmpty)
          _buildEmptyState()
        else
          table(classes: 'w-full border-collapse ${tableConfig.isStriped() ? 'table-striped' : ''}', [
            _buildTableHead(columns),
            _buildTableBody(columns),
          ]),
      ],
    );
  }

  Component _buildTableHead(List<TableColumn> columns) {
    return thead(classes: 'bg-gray-800 border-b border-gray-700', [
      tr([
        for (final column in columns)
          th(
            classes: _buildColumnCellClasses(
              column,
              base: 'px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider whitespace-nowrap',
            ),
            attributes: _buildColumnAttributes(column),
            [
              if (column.isSortable())
                a(
                  href: _buildSortUrl(column.getName()),
                  classes: 'block text-gray-400 no-underline',
                  attributes: {
                    'hx-get': _buildSortUrl(column.getName()),
                    'hx-target': '#resource-table-container',
                    'hx-select': '#resource-table-container',
                    'hx-swap': 'outerHTML',
                    'hx-push-url': 'true',
                  },
                  [
                    div(classes: 'flex items-center gap-2', [
                      span(classes: 'font-medium', [text(column.getLabel())]),
                      _buildSortIndicator(column),
                    ]),
                  ],
                )
              else
                div(classes: 'flex items-center gap-2', [
                  span(classes: 'font-medium', [text(column.getLabel())]),
                ]),
            ],
          ),
        // Actions column header
        th(
          classes: 'px-6 py-3 text-right text-xs font-medium text-gray-400 uppercase tracking-wider whitespace-nowrap',
          [text('Actions')],
        ),
      ]),
    ]);
  }

  String _buildSortUrl(String column) {
    final newDirection = sortColumn == column && sortDirection == 'asc' ? 'desc' : 'asc';
    final params = <String>[
      'sort=$column',
      'direction=$newDirection',
      if (searchQuery != null && searchQuery!.isNotEmpty) 'search=$searchQuery',
      if (currentPage != 1) 'page=$currentPage',
    ];
    return '$basePath?${params.join('&')}';
  }

  Component _buildSortIndicator(TableColumn column) {
    final isActive = sortColumn == column.getName();
    final direction = isActive ? (sortDirection ?? 'asc') : 'asc';
    final textColor = isActive ? 'text-gray-200' : 'text-gray-600';
    return span(classes: 'text-xs $textColor cursor-pointer', [
      text(isActive ? (direction == 'asc' ? '↑' : '↓') : '↕'),
    ]);
  }

  Component _buildTableBody(List<TableColumn> columns) {
    return tbody([
      for (final record in records)
        tr(classes: 'bg-gray-800 border-b border-gray-700 hover:bg-gray-700 transition-colors', [
          for (final column in columns) _buildTableCell(column, record),
          _buildRowActions(record),
        ]),
    ]);
  }

  Component _buildRowActions(T record) {
    final recordId = _getRecordId(record);
    return td(classes: 'px-6 py-4 text-sm text-right whitespace-nowrap', [
      div(classes: 'flex items-center justify-end gap-2', [
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
      ]),
    ]);
  }

  /// Gets the record's primary key value.
  dynamic _getRecordId(T record) {
    final fields = record.toMap();
    final primaryKey = record.primaryKey;
    return fields[primaryKey];
  }

  Component _buildTableCell(TableColumn column, T record) {
    return td(
      classes: _buildColumnCellClasses(column, base: 'px-6 py-4 text-sm text-gray-200'),
      attributes: _buildColumnAttributes(column),
      [_buildCellContent(column, record)],
    );
  }

  Component _buildCellContent(TableColumn column, T record) {
    final state = column.getState(record);
    if (column is TextColumn) {
      return _buildTextColumnContent(column, record, state);
    } else if (column is IconColumn) {
      return _buildIconColumnContent(column, record);
    } else if (column is BooleanColumn) {
      return _buildBooleanColumnContent(column, record);
    }
    return span([text(column.formatState(state))]);
  }

  Component _buildTextColumnContent(TextColumn column, T record, dynamic state) {
    final components = <Component>[];
    if (column.getIcon() != null) {
      components.add(span(classes: 'inline-flex items-center justify-center w-5 h-5 mr-2', [text(column.getIcon()!)]));
    }
    if (column.isBadge()) {
      final color = column.getColor(record) ?? 'default';
      final badgeClasses = switch (color) {
        'primary' =>
          'inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-blue-900 text-blue-300',
        'success' =>
          'inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-green-900 text-green-300',
        'danger' =>
          'inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-red-900 text-red-300',
        'warning' =>
          'inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-yellow-900 text-yellow-300',
        'info' =>
          'inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-blue-900 text-blue-300',
        _ =>
          'inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-gray-700 text-gray-300',
      };
      components.add(span(classes: badgeClasses, [text(column.formatState(state))]));
    } else {
      final formatted = column.formatState(state);
      components.add(span(classes: 'text-sm text-gray-200', [text(formatted)]));
    }
    if (column.getIconAfter() != null) {
      components.add(
        span(classes: 'inline-flex items-center justify-center w-5 h-5 ml-2', [text(column.getIconAfter()!)]),
      );
    }
    final description = column.getDescription(record);
    if (description != null) {
      components.add(span(classes: 'text-xs text-gray-400', [text(description)]));
    }
    final url = column.getUrl(record);
    if (url != null) {
      final attrs = column.shouldOpenUrlInNewTab()
          ? {'target': '_blank', 'rel': 'noopener noreferrer'}
          : <String, String>{};
      return a(href: url, classes: 'text-blue-400 hover:underline', attributes: attrs, components);
    }
    return div(classes: 'flex flex-col gap-1', components);
  }

  Component _buildIconColumnContent(IconColumn column, T record) {
    final icon = column.getIcon(record);
    final color = column.getColor(record) ?? 'default';
    if (icon == null) return span([]);
    final colorClass = switch (color) {
      'success' => 'text-green-500',
      'danger' => 'text-red-500',
      'warning' => 'text-yellow-500',
      'info' => 'text-blue-500',
      _ => 'text-gray-500',
    };
    return span(classes: 'inline-flex items-center justify-center w-5 h-5 $colorClass', [
      text(_getIconCharacter(icon)),
    ]);
  }

  Component _buildBooleanColumnContent(BooleanColumn column, T record) => _buildIconColumnContent(column, record);

  Component _buildEmptyState() {
    final heading = tableConfig.getEmptyStateHeading() ?? 'No ${resource.label.toLowerCase()} found';
    final description =
        tableConfig.getEmptyStateDescription() ??
        'Get started by creating your first ${resource.singularLabel.toLowerCase()}.';
    return div(classes: 'py-16 px-6 text-center', [
      div(classes: 'max-w-md mx-auto', [
        div(classes: 'text-5xl mb-4', [resource.iconComponent]),
        h3(classes: 'text-lg font-semibold text-gray-100 mb-2', [text(heading)]),
        p(classes: 'text-sm text-gray-400 mb-6', [text(description)]),
        Button(label: 'Create ${resource.singularLabel}', variant: ButtonVariant.primary),
      ]),
    ]);
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

  String _getAlignmentClass(TableColumn column) {
    switch (column.getAlignment()) {
      case ColumnAlignment.start:
        return 'text-left';
      case ColumnAlignment.center:
        return 'text-center';
      case ColumnAlignment.end:
        return 'text-right';
    }
  }

  String _buildColumnCellClasses(TableColumn column, {required String base}) {
    final classes = <String>[base, _getAlignmentClass(column)];
    if (column.isToggleable()) {
      classes.add('toggleable-column');
      if (column.isToggledHiddenByDefault()) {
        classes.add('column-hidden');
      }
    }
    return classes.join(' ');
  }

  Map<String, String> _buildColumnAttributes(TableColumn column) {
    final attrs = <String, String>{'data-column': column.getName()};
    if (column.isToggleable()) {
      attrs['data-toggleable'] = 'true';
      if (column.isToggledHiddenByDefault()) {
        attrs['data-hidden-default'] = 'true';
      }
    }
    return attrs;
  }

  String _getIconCharacter(String iconName) {
    final iconMap = {
      'check': '✓',
      'check-circle': '✓',
      'x': '✗',
      'x-circle': '✗',
      'shield-check': '🛡️',
      'shield-exclamation': '⚠️',
      'document-text': '📄',
      'user': '👤',
      'user-group': '👥',
    };
    return iconMap[iconName] ?? '●';
  }
}
