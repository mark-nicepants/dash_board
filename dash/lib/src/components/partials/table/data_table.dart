import 'package:dash_board/src/components/partials/table/bulk_actions_toolbar.dart';
import 'package:dash_board/src/components/partials/table/table_empty_state.dart';
import 'package:dash_board/src/components/partials/table/table_header.dart';
import 'package:dash_board/src/components/partials/table/table_row.dart';
import 'package:dash_board/src/model/model.dart';
import 'package:dash_board/src/table/columns/column.dart';
import 'package:dash_board/src/table/table.dart';
import 'package:jaspr/jaspr.dart';

/// A reusable data table component that renders tabular data with sorting,
/// searching, and pagination support.
///
/// Sorting is handled via DashWire - clicking sortable columns triggers
/// the `sort('columnName')` action on the parent component.
///
/// Example:
/// ```dart
/// DataTable<User>(
///   tableConfig: table,
///   records: users,
///   sortColumn: 'name',
///   sortDirection: 'asc',
///   basePath: '/admin/resources/users',
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

  /// Optional ID for the table container.
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

  /// The base path for action URLs.
  final String? basePath;

  const DataTable({
    required this.tableConfig,
    required this.records,
    this.sortColumn,
    this.sortDirection,
    this.containerId,
    this.resourceSlug,
    this.emptyStateIcon,
    this.emptyStateHeading,
    this.emptyStateDescription,
    this.rowActions,
    this.showActions = true,
    this.basePath,
    super.key,
  });

  @override
  Component build(BuildContext context) {
    final columns = tableConfig.getColumns().where((c) => !c.isHidden()).toList();
    final hasBulkActions = tableConfig.hasBulkActions() && basePath != null;

    // Wrap in Alpine.js selection state if bulk actions are enabled
    if (hasBulkActions && records.isNotEmpty) {
      return _buildWithBulkSelection(columns);
    }

    return _buildTable(columns, showCheckboxes: false);
  }

  Component _buildWithBulkSelection(List<TableColumn> columns) {
    // Get all record IDs for the "select all" functionality
    final allIds = records.map((r) => r.getKey()).toList();
    final allIdsJson = allIds.map((id) => "'$id'").join(', ');

    return div(
      id: containerId,
      attributes: {
        'x-data':
            '''
          {
            selectedIds: [],
            allIds: [$allIdsJson],
            get allSelected() { return this.selectedIds.length === this.allIds.length && this.allIds.length > 0 },
            get someSelected() { return this.selectedIds.length > 0 },
            toggleAll() {
              if (this.allSelected) {
                this.selectedIds = [];
              } else {
                this.selectedIds = [...this.allIds];
              }
            },
            toggleSelection(id) {
              const index = this.selectedIds.indexOf(id);
              if (index > -1) {
                this.selectedIds.splice(index, 1);
              } else {
                this.selectedIds.push(id);
              }
            },
            clearSelection() { this.selectedIds = [] },
            isSelected(id) { return this.selectedIds.includes(id) }
          }
        ''',
        if (resourceSlug != null) 'data-resource-slug': resourceSlug!,
      },
      [
        // Bulk actions toolbar
        BulkActionsToolbar<T>(actions: tableConfig.getBulkActions(), basePath: basePath!),

        // Table
        _buildTable(columns, showCheckboxes: true),
      ],
    );
  }

  Component _buildTable(List<TableColumn> columns, {required bool showCheckboxes}) {
    return div(
      id: containerId,
      classes: 'min-w-full divide-y divide-gray-700',
      attributes: {if (resourceSlug != null) 'data-resource-slug': resourceSlug!},
      [
        table(classes: 'min-w-full divide-y divide-gray-700', [
          TableHeader<T>(
            columns: columns,
            sortColumn: sortColumn,
            sortDirection: sortDirection,
            showActions: showActions,
            showCheckbox: showCheckboxes,
          ),
          tbody(classes: 'bg-gray-800 divide-y divide-gray-700', [
            if (records.isEmpty)
              _buildEmptyState(columns.length + (showActions ? 1 : 0) + (showCheckboxes ? 1 : 0))
            else
              for (final record in records)
                TableRow<T>(
                  record: record,
                  columns: columns,
                  actions: rowActions?.call(record) ?? [],
                  showActions: showActions,
                  showCheckbox: showCheckboxes,
                ),
          ]),
        ]),
      ],
    );
  }

  Component _buildEmptyState(int colSpan) {
    return tr([
      td(
        attributes: {'colspan': '$colSpan'},
        [
          TableEmptyState(
            icon: emptyStateIcon,
            heading: emptyStateHeading ?? 'No records found',
            description: emptyStateDescription ?? 'Try adjusting your search or filters.',
          ),
        ],
      ),
    ]);
  }
}
