/// Table component library for Dash admin panel.
///
/// This library provides reusable table components for displaying
/// tabular data with sorting, searching, and pagination support.
///
/// Sorting is handled via DashWire - clicking sortable columns triggers
/// the `sort('columnName')` action on the parent component.
///
/// Example:
/// ```dart
/// import 'package:dash_board/src/components/partials/table/table.dart';
///
/// DataTable<User>(
///   tableConfig: table,
///   records: users,
///   sortColumn: 'name',
///   sortDirection: 'asc',
///   basePath: '/admin/resources/users',
/// )
/// ```
library;

// Bulk actions
export 'bulk_actions_toolbar.dart';
// Cell components
export 'cells/boolean_cell.dart';
export 'cells/icon_cell.dart';
export 'cells/table_cell_factory.dart';
export 'cells/text_cell.dart';
// Checkbox column for bulk selection
export 'checkbox_column.dart';
// Main table component
export 'data_table.dart';
// Sub-components
export 'sort_indicator.dart';
export 'table_empty_state.dart';
export 'table_header.dart';
export 'table_row.dart';
