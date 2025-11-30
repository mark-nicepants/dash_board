import 'package:dash/src/components/partials/table/bulk_actions_toolbar.dart';
import 'package:dash/src/components/partials/table/checkbox_column.dart';
import 'package:dash/src/components/partials/table/table_empty_state.dart';
import 'package:dash/src/components/partials/table/table_header.dart';
import 'package:dash/src/components/partials/table/table_row.dart';
import 'package:dash/src/model/model.dart';
import 'package:dash/src/service_locator.dart';
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

  /// The base path for action URLs.
  final String? basePath;

  /// Function to get the primary key value from a record.
  final dynamic Function(T record)? getRecordId;

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
    this.basePath,
    this.getRecordId,
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
    final allIds = records.map((r) => getRecordId?.call(r) ?? r.getKey()).toList();
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
      id: showCheckboxes ? null : containerId,
      classes: 'overflow-x-auto border-t border-gray-700',
      attributes: {
        'data-table-container': 'true',
        if (!showCheckboxes && resourceSlug != null) 'data-resource-slug': resourceSlug!,
      },
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
              showCheckbox: showCheckboxes,
            ),
            _buildTableBody(columns, showCheckboxes: showCheckboxes),
          ]),
      ],
    );
  }

  Component _buildTableBody(List<TableColumn> columns, {required bool showCheckboxes}) {
    return tbody([for (final record in records) _buildTableRow(record, columns, showCheckboxes: showCheckboxes)]);
  }

  Component _buildTableRow(T record, List<TableColumn> columns, {required bool showCheckboxes}) {
    final recordId = getRecordId?.call(record) ?? record.getKey();
    final primary = panelColors.primary;

    // Base row classes
    const baseClasses = 'bg-gray-800 border-b border-gray-700 last:border-0 hover:bg-gray-700 transition-colors';

    // Selected state classes: left border indicator + subtle background
    final selectedClasses = 'border-l-2 border-l-$primary-500 bg-$primary-500/5';

    return tr(
      classes: '$baseClasses ${showCheckboxes ? 'border-l-2 border-l-transparent' : ''}',
      attributes: showCheckboxes ? {':class': "{ '$selectedClasses': isSelected('$recordId') }"} : null,
      [
        // Checkbox column
        if (showCheckboxes) CheckboxColumn<T>(record: record, recordId: recordId),

        // Data columns
        for (final column in columns) TableRow.buildCell(column, record),

        // Actions column
        if (rowActions != null)
          td(classes: 'px-6 py-4 text-sm text-right whitespace-nowrap', [
            div(classes: 'flex items-center justify-end gap-2', rowActions!(record)),
          ]),
      ],
    );
  }
}
