import 'package:dash_board/src/components/partials/table/cells/table_cell_factory.dart';
import 'package:dash_board/src/components/partials/table/checkbox_column.dart';
import 'package:dash_board/src/model/model.dart';
import 'package:dash_board/src/table/columns/column.dart';
import 'package:jaspr/jaspr.dart';

/// Table row component that renders a single data row.
///
/// Example:
/// ```dart
/// TableRow<User>(
///   columns: columns,
///   record: user,
///   actions: [
///     Button(label: 'Edit', href: '/users/1/edit'),
///     Button(label: 'Delete', variant: ButtonVariant.danger),
///   ],
/// )
/// ```
class TableRow<T extends Model> extends StatelessComponent {
  /// The columns to render cells for.
  final List<TableColumn> columns;

  /// The record to render.
  final T record;

  /// Optional action components to render in the actions column.
  final List<Component>? actions;

  /// Whether to show the actions column.
  final bool showActions;

  /// Whether to show the checkbox column.
  final bool showCheckbox;

  const TableRow({
    required this.columns,
    required this.record,
    this.actions,
    this.showActions = true,
    this.showCheckbox = false,
    super.key,
  });

  @override
  Component build(BuildContext context) {
    return tr(classes: 'bg-gray-800 border-b border-gray-700 last:border-0 hover:bg-gray-700 transition-colors', [
      if (showCheckbox) _buildCheckboxCell(),
      for (final column in columns) _buildCell(column),
      if (showActions) _buildActionsCell(),
    ]);
  }

  Component _buildCheckboxCell() {
    return CheckboxColumn<T>(record: record, recordId: record.getKey());
  }

  /// Static method to build a cell without needing a full TableRow instance.
  ///
  /// Useful when building custom table layouts (e.g., with checkbox columns).
  static Component buildCell<M extends Model>(TableColumn column, M record) {
    return td(classes: _getCellClasses(column), attributes: _getCellAttributes(column), [
      TableCellFactory.build(column, record),
    ]);
  }

  Component _buildCell(TableColumn column) {
    return td(classes: _getCellClasses(column), attributes: _getCellAttributes(column), [
      TableCellFactory.build(column, record),
    ]);
  }

  Component _buildActionsCell() {
    return td(classes: 'px-6 py-4 text-sm text-right whitespace-nowrap', [
      if (actions != null) div(classes: 'flex items-center justify-end gap-2', actions!),
    ]);
  }

  static String _getCellClasses(TableColumn column) {
    final classes = <String>['px-6 py-4 text-sm text-gray-200', _getAlignmentClass(column)];

    if (column.isToggleable()) {
      classes.add('toggleable-column');
      if (column.isToggledHiddenByDefault()) {
        classes.add('column-hidden');
      }
    }

    return classes.join(' ');
  }

  static Map<String, String> _getCellAttributes(TableColumn column) {
    final attrs = <String, String>{'data-column': column.getName()};
    if (column.isToggleable()) {
      attrs['data-toggleable'] = 'true';
      if (column.isToggledHiddenByDefault()) {
        attrs['data-hidden-default'] = 'true';
      }
    }
    return attrs;
  }

  static String _getAlignmentClass(TableColumn column) {
    return switch (column.getAlignment()) {
      ColumnAlignment.start => 'text-left',
      ColumnAlignment.center => 'text-center',
      ColumnAlignment.end => 'text-right',
    };
  }
}
