import 'package:dash_board/src/actions/action.dart';
import 'package:dash_board/src/model/model.dart';
import 'package:dash_board/src/table/columns/column.dart';

/// Represents a table in the admin panel.
///
/// A [Table] defines how data is displayed in a list view, including columns,
/// sorting, searching, pagination, and filtering capabilities.
///
/// Example:
/// ```dart
/// Table table(Table table) {
///   return table
///     .columns([
///       TextColumn.make('name')
///         .searchable()
///         .sortable(),
///       TextColumn.make('email')
///         .searchable(),
///       BooleanColumn.make('is_active')
///         .sortable(),
///     ])
///     .defaultSort('name');
/// }
/// ```
class Table<T extends Model> {
  /// The columns to display in the table.
  List<TableColumn> _columns = [];

  /// The default sort column.
  String? _defaultSort;

  /// The default sort direction ('asc' or 'desc').
  String _defaultSortDirection = 'asc';

  /// Whether the table is paginated.
  bool _paginated = true;

  /// The number of records per page.
  int _recordsPerPage = 10;

  /// Available page size options.
  List<int> _perPageOptions = [5, 10, 25, 50, 100];

  /// Whether to show striped rows.
  bool _striped = false;

  /// The empty state heading.
  String? _emptyStateHeading;

  /// The empty state description.
  String? _emptyStateDescription;

  /// The empty state icon.
  String? _emptyStateIcon;

  /// Whether to show the search input.
  bool _searchable = true;

  /// Placeholder text for the search input.
  String _searchPlaceholder = 'Search...';

  /// Row actions displayed for each record.
  List<Action<T>> _actions = [];

  /// Bulk actions for selected records.
  List<Action<T>> _bulkActions = [];

  /// Header actions displayed above the table.
  List<Action<T>> _headerActions = [];

  Table();

  /// Sets the columns for the table.
  Table<T> columns(List<TableColumn> columns) {
    _columns = columns;
    _searchable = columns.any((column) => column.isSearchable());
    return this;
  }

  /// Gets the columns for the table.
  List<TableColumn> getColumns() => _columns;

  /// Sets the default sort column and direction.
  Table<T> defaultSort(String column, [String direction = 'asc']) {
    _defaultSort = column;
    _defaultSortDirection = direction;
    return this;
  }

  /// Gets the default sort column.
  String? getDefaultSort() => _defaultSort;

  /// Gets the default sort direction.
  String getDefaultSortDirection() => _defaultSortDirection;

  /// Enables or disables pagination.
  Table<T> paginated([bool paginated = true]) {
    _paginated = paginated;
    return this;
  }

  /// Checks if the table is paginated.
  bool isPaginated() => _paginated;

  /// Sets the number of records per page.
  Table<T> recordsPerPage(int count) {
    _recordsPerPage = count;
    return this;
  }

  /// Gets the number of records per page.
  int getRecordsPerPage() => _recordsPerPage;

  /// Sets the available page size options.
  Table<T> perPageOptions(List<int> options) {
    _perPageOptions = options;
    return this;
  }

  /// Gets the available page size options.
  List<int> getPerPageOptions() => _perPageOptions;

  /// Enables or disables striped rows.
  Table<T> striped([bool striped = true]) {
    _striped = striped;
    return this;
  }

  /// Checks if the table has striped rows.
  bool isStriped() => _striped;

  /// Sets the empty state heading.
  Table<T> emptyStateHeading(String heading) {
    _emptyStateHeading = heading;
    return this;
  }

  /// Gets the empty state heading.
  String? getEmptyStateHeading() => _emptyStateHeading;

  /// Sets the empty state description.
  Table<T> emptyStateDescription(String description) {
    _emptyStateDescription = description;
    return this;
  }

  /// Gets the empty state description.
  String? getEmptyStateDescription() => _emptyStateDescription;

  /// Sets the empty state icon.
  Table<T> emptyStateIcon(String icon) {
    _emptyStateIcon = icon;
    return this;
  }

  /// Gets the empty state icon.
  String? getEmptyStateIcon() => _emptyStateIcon;

  /// Enables or disables the search input.
  Table<T> searchable([bool searchable = true]) {
    _searchable = searchable;
    return this;
  }

  /// Checks if the table is searchable.
  bool isSearchable() => _searchable;

  /// Sets the search placeholder.
  Table<T> searchPlaceholder(String placeholder) {
    _searchPlaceholder = placeholder;
    return this;
  }

  /// Gets the search placeholder.
  String getSearchPlaceholder() => _searchPlaceholder;

  /// Sets the row actions for the table.
  ///
  /// Row actions are displayed for each record in the table.
  ///
  /// ```dart
  /// table.actions([
  ///   EditAction.make(),
  ///   DeleteAction.make(),
  /// ])
  /// ```
  Table<T> actions(List<Action<T>> actions) {
    _actions = actions;
    return this;
  }

  /// Gets the row actions.
  List<Action<T>> getActions() => _actions;

  /// Checks if the table has row actions.
  bool hasActions() => _actions.isNotEmpty;

  /// Sets the bulk actions for the table.
  ///
  /// Bulk actions are displayed when records are selected.
  ///
  /// ```dart
  /// table.bulkActions([
  ///   DeleteBulkAction.make(),
  /// ])
  /// ```
  Table<T> bulkActions(List<Action<T>> actions) {
    _bulkActions = actions;
    return this;
  }

  /// Gets the bulk actions.
  List<Action<T>> getBulkActions() => _bulkActions;

  /// Checks if the table has bulk actions.
  bool hasBulkActions() => _bulkActions.isNotEmpty;

  /// Sets the header actions for the table.
  ///
  /// Header actions are displayed above the table.
  ///
  /// ```dart
  /// table.headerActions([
  ///   Action.make('export').label('Export').icon(HeroIcons.arrowDownTray),
  /// ])
  /// ```
  Table<T> headerActions(List<Action<T>> actions) {
    _headerActions = actions;
    return this;
  }

  /// Gets the header actions.
  List<Action<T>> getHeaderActions() => _headerActions;

  /// Checks if the table has header actions.
  bool hasHeaderActions() => _headerActions.isNotEmpty;

  /// Gets the list of relationship names required by columns.
  /// For columns with dot notation (e.g., 'author.name'), returns the relationship name ('author').
  Set<String> getRequiredRelationships() {
    final relationships = <String>{};
    for (final column in _columns) {
      final name = column.getName();
      if (name.contains('.')) {
        // Extract the first part as the relationship name
        relationships.add(name.split('.').first);
      }
    }
    return relationships;
  }
}
