import 'package:dash/src/components/partials/table/table_empty_state.dart';
import 'package:dash/src/components/partials/table/table_header.dart';
import 'package:dash/src/components/partials/table/table_row.dart';
import 'package:dash/src/model/model.dart';
import 'package:dash/src/table/columns/column.dart';
import 'package:dash/src/table/table.dart';
import 'package:jaspr/jaspr.dart';

/// A reusable data table component that renders tabular data with sorting,
/// searching, and pagination support.
///
/// Example:
/// ```dart
/// DataTable<User>(
///   tableConfig: table,
///   records: users,
///   sortColumn: 'name',
///   sortDirection: 'asc',
///   onSortUrl: (column) => '/admin/users?sort=$column',
///   emptyStateIcon: const Heroicon(HeroIcons.users),
///   emptyStateHeading: 'No users found',
///   emptyStateDescription: 'Create your first user to get started.',
/// )
/// ```
class DataTable<T extends Model> extends StatelessComponent {
  /// The table configuration with columns and settings.
  final Table<T> tableConfig;

  /// The records to display in the table.
  final List<T> records;

  /// The currently sorted column name.
  final String? sortColumn;

  /// The current sort direction ('asc' or 'desc').
  final String? sortDirection;

  /// Function to generate sort URL for a column.
  final String Function(String column, String direction)? onSortUrl;

  /// Optional ID for the table container (useful for HTMX targeting).
  final String? containerId;

  /// The resource slug for column toggle functionality.
  final String? resourceSlug;

  /// Custom empty state icon.
  final Component? emptyStateIcon;

  /// Custom empty state heading.
  final String? emptyStateHeading;

  /// Custom empty state description.
  final String? emptyStateDescription;

  /// Optional action buttons for each row.
  final List<Component> Function(T record)? rowActions;

  /// Whether to show the actions column.
  final bool showActions;

  const DataTable({
    required this.tableConfig,
    required this.records,
    this.sortColumn,
    this.sortDirection,
    this.onSortUrl,
    this.containerId,
    this.resourceSlug,
    this.emptyStateIcon,
    this.emptyStateHeading,
    this.emptyStateDescription,
    this.rowActions,
    this.showActions = true,
    super.key,
  });

  @override
  Component build(BuildContext context) {
    final columns = tableConfig.getColumns().where((c) => !c.isHidden()).toList();

    return div(
      id: containerId,
      classes: 'overflow-x-auto border-t border-gray-700',
      attributes: {'data-table-container': 'true', if (resourceSlug != null) 'data-resource-slug': resourceSlug!},
      [
        if (records.isEmpty)
          TableEmptyState(
            icon: emptyStateIcon,
            heading: emptyStateHeading ?? tableConfig.getEmptyStateHeading() ?? 'No records found',
            description: emptyStateDescription ?? tableConfig.getEmptyStateDescription() ?? 'No data available.',
          )
        else
          table(classes: 'w-full border-collapse ${tableConfig.isStriped() ? 'table-striped' : ''}', [
            TableHeader<T>(
              columns: columns,
              sortColumn: sortColumn,
              sortDirection: sortDirection,
              onSortUrl: onSortUrl,
              showActions: showActions && rowActions != null,
            ),
            _buildTableBody(columns),
          ]),
      ],
    );
  }

  Component _buildTableBody(List<TableColumn> columns) {
    return tbody([
      for (final record in records)
        TableRow<T>(columns: columns, record: record, actions: rowActions != null ? rowActions!(record) : null),
    ]);
  }
}
