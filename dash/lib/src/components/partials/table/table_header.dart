import 'package:dash/src/components/partials/table/checkbox_column.dart';
import 'package:dash/src/components/partials/table/sort_indicator.dart';
import 'package:dash/src/table/columns/column.dart';
import 'package:jaspr/jaspr.dart';

/// Table header component that renders column headers with sorting support.
///
/// Example:
/// ```dart
/// TableHeader<User>(
///   columns: columns,
///   sortColumn: 'name',
///   sortDirection: 'asc',
///   onSortUrl: (column, direction) => '/users?sort=$column&direction=$direction',
/// )
/// ```
class TableHeader<T> extends StatelessComponent {
  /// The columns to render in the header.
  final List<TableColumn> columns;

  /// The currently sorted column name.
  final String? sortColumn;

  /// The current sort direction ('asc' or 'desc').
  final String? sortDirection;

  /// Function to generate sort URL for a column.
  final String Function(String column, String direction)? onSortUrl;

  /// Whether to show the actions column header.
  final bool showActions;

  /// Label for the actions column.
  final String actionsLabel;

  /// Whether to show the checkbox column for bulk selection.
  final bool showCheckbox;

  const TableHeader({
    required this.columns,
    this.sortColumn,
    this.sortDirection,
    this.onSortUrl,
    this.showActions = false,
    this.actionsLabel = 'Actions',
    this.showCheckbox = false,
    super.key,
  });

  @override
  Component build(BuildContext context) {
    return thead(classes: 'bg-gray-800 border-b border-gray-700', [
      tr([
        if (showCheckbox) _buildCheckboxHeader(),
        for (final column in columns) _buildHeaderCell(column),
        if (showActions) _buildActionsHeader(),
      ]),
    ]);
  }

  Component _buildCheckboxHeader() {
    return const CheckboxColumnHeader();
  }

  Component _buildHeaderCell(TableColumn column) {
    final isActive = sortColumn == column.getName();

    return th(classes: _buildCellClasses(column), attributes: _buildCellAttributes(column), [
      if (column.isSortable() && onSortUrl != null)
        _buildSortableHeader(column, isActive)
      else
        div(classes: 'flex items-center gap-2', [
          span(classes: 'font-medium', [text(column.getLabel())]),
        ]),
    ]);
  }

  Component _buildSortableHeader(TableColumn column, bool isActive) {
    final currentDirection = isActive ? (sortDirection ?? 'asc') : 'asc';
    final newDirection = isActive && currentDirection == 'asc' ? 'desc' : 'asc';
    final url = onSortUrl!(column.getName(), newDirection);

    return a(
      href: url,
      classes: 'block text-gray-400 no-underline',
      attributes: {
        'hx-get': url,
        'hx-target': '#resource-table-wrapper',
        'hx-select': '#resource-table-wrapper',
        'hx-swap': 'outerHTML',
        'hx-push-url': 'true',
      },
      [
        div(classes: 'flex items-center gap-2', [
          span(classes: 'font-medium', [text(column.getLabel())]),
          SortIndicator(isActive: isActive, direction: currentDirection),
        ]),
      ],
    );
  }

  Component _buildActionsHeader() {
    return th(
      classes: 'px-6 py-3 text-right text-xs font-medium text-gray-400 uppercase tracking-wider whitespace-nowrap',
      [text(actionsLabel)],
    );
  }

  String _buildCellClasses(TableColumn column) {
    final classes = <String>[
      'px-6 py-3 text-xs font-medium text-gray-400 uppercase tracking-wider whitespace-nowrap',
      _getAlignmentClass(column),
    ];

    if (column.isToggleable()) {
      classes.add('toggleable-column');
      if (column.isToggledHiddenByDefault()) {
        classes.add('column-hidden');
      }
    }

    return classes.join(' ');
  }

  Map<String, String> _buildCellAttributes(TableColumn column) {
    final attrs = <String, String>{'data-column': column.getName()};
    if (column.isToggleable()) {
      attrs['data-toggleable'] = 'true';
      if (column.isToggledHiddenByDefault()) {
        attrs['data-hidden-default'] = 'true';
      }
    }
    return attrs;
  }

  String _getAlignmentClass(TableColumn column) {
    return switch (column.getAlignment()) {
      ColumnAlignment.start => 'text-left',
      ColumnAlignment.center => 'text-center',
      ColumnAlignment.end => 'text-right',
    };
  }
}
