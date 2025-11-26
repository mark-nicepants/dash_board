/// Table component library for Dash admin panel.
///
/// This library provides reusable table components for displaying
/// tabular data with sorting, searching, and pagination support.
///
/// Example:
/// ```dart
/// import 'package:dash/src/components/partials/table/table.dart';
///
/// DataTable<User>(
///   tableConfig: table,
///   records: users,
///   sortColumn: 'name',
///   sortDirection: 'asc',
///   onSortUrl: (column, direction) => '/users?sort=$column&direction=$direction',
/// )
/// ```
library;

// Cell components
export 'cells/boolean_cell.dart';
export 'cells/icon_cell.dart';
export 'cells/table_cell_factory.dart';
export 'cells/text_cell.dart';
// Main table component
export 'data_table.dart';
// Sub-components
export 'sort_indicator.dart';
export 'table_empty_state.dart';
export 'table_header.dart';
export 'table_row.dart';
