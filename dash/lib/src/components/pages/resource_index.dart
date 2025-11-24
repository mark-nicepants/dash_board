import 'dart:convert';

import 'package:jaspr/jaspr.dart';

import '../../model/model.dart';
import '../../resource.dart';
import '../../table/columns/boolean_column.dart';
import '../../table/columns/column.dart';
import '../../table/columns/icon_column.dart';
import '../../table/columns/text_column.dart';
import '../../table/table.dart';
import '../partials/breadcrumbs.dart';
import '../partials/page_header.dart';

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
    return div(classes: 'resource-index-container', [
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
        button(classes: 'btn btn-primary', [text('New ${resource.singularLabel}')]),
      ],
    );
  }

  Component _buildTableCard() {
    final toggleableColumns = tableConfig.getColumns().where((c) => c.isToggleable()).toList();
    return div(classes: 'resource-table-card', [
      div(classes: 'table-header-actions', [
        if (tableConfig.isSearchable()) _buildSearchBar(),
        if (toggleableColumns.isNotEmpty) _buildColumnToggle(toggleableColumns),
      ]),
      _buildTable(),
    ]);
  }

  Component _buildColumnToggle(List<TableColumn> columns) {
    final defaults = {for (final column in columns) column.getName(): !column.isToggledHiddenByDefault()};
    final encodedDefaults = jsonEncode(defaults);
    return div(
      classes: 'column-toggle',
      attributes: {'x-data': "columnVisibility('${resource.slug}', $encodedDefaults)", 'x-cloak': ''},
      [
        button(
          type: ButtonType.button,
          classes: 'btn btn-secondary column-toggle-button',
          attributes: {'x-on:click': 'open = !open', 'x-bind:aria-expanded': 'open', 'aria-haspopup': 'true'},
          [
            span(classes: 'btn-icon', [text('☰')]),
            span([text('Columns')]),
          ],
        ),
        div(
          classes: 'column-toggle-menu',
          attributes: {'x-show': 'open', 'x-transition.opacity': '', '@click.outside': 'open = false'},
          [
            div(classes: 'column-toggle-header', [text('Toggle columns')]),
            ul(classes: 'column-toggle-options', [
              for (final column in columns)
                li([
                  button(
                    type: ButtonType.button,
                    classes: 'column-toggle-option',
                    attributes: {
                      'x-on:click': "toggle('${column.getName()}')",
                      'x-bind:class': "{'active': isVisible('${column.getName()}')}",
                    },
                    [
                      span(
                        classes: 'column-toggle-check',
                        attributes: {'x-show': "isVisible('${column.getName()}')"},
                        [text('✓')],
                      ),
                      span(classes: 'column-toggle-label', [text(column.getLabel())]),
                    ],
                  ),
                ]),
            ]),
            div(classes: 'column-toggle-footer', [
              button(
                type: ButtonType.button,
                classes: 'btn btn-secondary',
                attributes: {'x-on:click': 'showAll()'},
                [text('Show all')],
              ),
              button(
                type: ButtonType.button,
                classes: 'btn btn-secondary',
                attributes: {'x-on:click': 'hideAll()'},
                [text('Hide all')],
              ),
              button(
                type: ButtonType.button,
                classes: 'btn btn-secondary',
                attributes: {'x-on:click': 'reset()'},
                [text('Reset')],
              ),
            ]),
          ],
        ),
      ],
    );
  }

  Component _buildSearchBar() {
    return div(classes: 'resource-search', [
      input(
        type: InputType.text,
        classes: 'search-input',
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
      classes: 'table-container',
      attributes: {'data-table-container': 'true', 'data-resource-slug': resource.slug},
      [
        if (records.isEmpty)
          _buildEmptyState()
        else
          table(classes: 'resource-table ${tableConfig.isStriped() ? 'table-striped' : ''}', [
            _buildTableHead(columns),
            _buildTableBody(columns),
          ]),
      ],
    );
  }

  Component _buildTableHead(List<TableColumn> columns) {
    return thead([
      tr([
        for (final column in columns)
          th(
            classes: _buildColumnCellClasses(column, base: 'table-header-cell'),
            attributes: _buildColumnAttributes(column),
            [
              if (column.isSortable())
                a(
                  href: _buildSortUrl(column.getName()),
                  classes: 'header-link',
                  attributes: {
                    'hx-get': _buildSortUrl(column.getName()),
                    'hx-target': '#resource-table-container',
                    'hx-select': '#resource-table-container',
                    'hx-swap': 'outerHTML',
                    'hx-push-url': 'true',
                  },
                  [
                    div(classes: 'table-header-content', [
                      span(classes: 'header-label', [text(column.getLabel())]),
                      _buildSortIndicator(column),
                    ]),
                  ],
                )
              else
                div(classes: 'table-header-content', [
                  span(classes: 'header-label', [text(column.getLabel())]),
                ]),
            ],
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
    final iconClass = isActive ? (direction == 'asc' ? 'sort-asc' : 'sort-desc') : 'sort-none';
    return span(classes: 'sort-indicator $iconClass', [text(isActive ? (direction == 'asc' ? '↑' : '↓') : '↕')]);
  }

  Component _buildTableBody(List<TableColumn> columns) {
    return tbody([
      for (final record in records)
        tr(classes: 'table-row', [for (final column in columns) _buildTableCell(column, record)]),
    ]);
  }

  Component _buildTableCell(TableColumn column, T record) {
    return td(
      classes: _buildColumnCellClasses(column, base: 'table-cell'),
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
      components.add(span(classes: 'column-icon', [text(column.getIcon()!)]));
    }
    if (column.isBadge()) {
      final color = column.getColor(record) ?? 'default';
      components.add(span(classes: 'badge badge-$color', [text(column.formatState(state))]));
    } else {
      final formatted = column.formatState(state);
      components.add(span(classes: 'column-text', [text(formatted)]));
    }
    if (column.getIconAfter() != null) {
      components.add(span(classes: 'column-icon', [text(column.getIconAfter()!)]));
    }
    final description = column.getDescription(record);
    if (description != null) {
      components.add(span(classes: 'column-description', [text(description)]));
    }
    final url = column.getUrl(record);
    if (url != null) {
      final attrs = column.shouldOpenUrlInNewTab()
          ? {'target': '_blank', 'rel': 'noopener noreferrer'}
          : <String, String>{};
      return a(href: url, classes: 'column-link', attributes: attrs, components);
    }
    return div(classes: 'column-content', components);
  }

  Component _buildIconColumnContent(IconColumn column, T record) {
    final icon = column.getIcon(record);
    final color = column.getColor(record) ?? 'default';
    if (icon == null) return span([]);
    return span(classes: 'column-icon icon-$color', [text(_getIconCharacter(icon))]);
  }

  Component _buildBooleanColumnContent(BooleanColumn column, T record) => _buildIconColumnContent(column, record);

  Component _buildEmptyState() {
    final heading = tableConfig.getEmptyStateHeading() ?? 'No ${resource.label.toLowerCase()} found';
    final description =
        tableConfig.getEmptyStateDescription() ??
        'Get started by creating your first ${resource.singularLabel.toLowerCase()}.';
    return div(classes: 'empty-state', [
      div(classes: 'empty-state-content', [
        div(classes: 'empty-state-icon', [text('📭')]),
        h3(classes: 'empty-state-heading', [text(heading)]),
        p(classes: 'empty-state-description', [text(description)]),
        button(classes: 'btn btn-primary', [text('Create ${resource.singularLabel}')]),
      ]),
    ]);
  }

  Component _buildPagination() {
    if (!tableConfig.isPaginated() || totalRecords == 0) return div([]);
    final perPage = tableConfig.getRecordsPerPage();
    final totalPages = (totalRecords / perPage).ceil();
    if (totalPages <= 1) return div([]);
    return div(classes: 'pagination', [
      div(classes: 'pagination-info', [text('Page $currentPage of $totalPages ($totalRecords total)')]),
      div(classes: 'pagination-controls', [
        if (currentPage > 1)
          a(
            href: _buildPageUrl(currentPage - 1),
            classes: 'btn btn-secondary',
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
          span(classes: 'btn btn-secondary disabled', [text('← Previous')]),
        for (var i = 1; i <= totalPages; i++)
          if (_shouldShowPage(i, currentPage, totalPages))
            i != currentPage
                ? a(
                    href: _buildPageUrl(i),
                    classes: 'btn btn-secondary',
                    attributes: {
                      'hx-get': _buildPageUrl(i),
                      'hx-target': '#resource-table-container',
                      'hx-select': '#resource-table-container',
                      'hx-swap': 'outerHTML',
                      'hx-push-url': 'true',
                    },
                    [text('$i')],
                  )
                : span(classes: 'btn btn-secondary active', [text('$i')])
          else if (i == currentPage - 2 || i == currentPage + 2)
            span(classes: 'pagination-ellipsis', [text('...')]),
        if (currentPage < totalPages)
          a(
            href: _buildPageUrl(currentPage + 1),
            classes: 'btn btn-secondary',
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
          span(classes: 'btn btn-secondary disabled', [text('Next →')]),
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
        return 'align-start';
      case ColumnAlignment.center:
        return 'align-center';
      case ColumnAlignment.end:
        return 'align-end';
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
