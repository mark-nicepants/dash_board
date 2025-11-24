import 'package:jaspr/jaspr.dart';

import 'components/pages/resource_index.dart';
import 'components/partials/heroicon.dart';
import 'model/model.dart';
import 'model/model_query_builder.dart';
import 'table/table.dart';

/// Base class for all Dash resources.
///
/// A [Resource] represents a model or entity in your application that can be
/// managed through the admin panel. It defines how the data is displayed,
/// created, edited, and deleted.
///
/// Example:
/// ```dart
/// class UserResource extends Resource<User> {
///   @override
///   String get label => 'Users';
///
///   @override
///   String get singularLabel => 'User';
///
///   @override
///   Type get model => User;
/// }
/// ```
abstract class Resource<T extends Model> {
  /// The model class associated with this resource.
  Type get model;

  /// The plural label for this resource (e.g., "Users").
  /// Defaults to the model name with an 's' suffix.
  String get label => '${_modelName}s';

  /// The singular label for this resource (e.g., "User").
  /// Defaults to the model name.
  String get singularLabel => _modelName;

  /// Gets the model name from the Type.
  String get _modelName => model.toString();

  /// The icon component to display for this resource.
  Component get iconComponent => const Heroicon(HeroIcons.documentText);

  /// The navigation group this resource belongs to.
  /// Defaults to 'Main' if not specified.
  String? get navigationGroup => 'Main';

  /// The sort order for this resource in navigation.
  /// Defaults to 0.
  int get navigationSort => 0;

  /// Whether this resource should be shown in navigation.
  bool get shouldRegisterNavigation => true;

  /// The URL slug for this resource (e.g., "users").
  /// Defaults to lowercase plural label with spaces replaced by hyphens.
  String get slug => label.toLowerCase().replaceAll(' ', '-');

  /// Defines the table configuration for this resource.
  ///
  /// Override this method to configure how data is displayed in the list view.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Table table(Table table) {
  ///   return table
  ///     .columns([
  ///       TextColumn.make('name')
  ///         .searchable()
  ///         .sortable(),
  ///       TextColumn.make('email')
  ///         .searchable(),
  ///       BooleanColumn.make('is_active'),
  ///     ])
  ///     .defaultSort('name');
  /// }
  /// ```
  Table<T> table(Table<T> table) {
    return table;
  }

  /// Creates a new instance of the model.
  /// Must be overridden by subclasses to provide a concrete instance.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// User newModelInstance() => User();
  /// ```
  T newModelInstance();

  /// Creates a query builder for the model.
  /// Uses the model instance to configure the query.
  ModelQueryBuilder<T> query() {
    final instance = newModelInstance();
    return ModelQueryBuilder<T>(
      Model.connector,
      modelFactory: () => newModelInstance(),
      modelTable: instance.table,
      modelPrimaryKey: instance.primaryKey,
    );
  }

  /// Validates that all columns referenced in the table configuration exist in the model.
  /// Should be called during application startup to catch configuration errors early.
  ///
  /// Throws [StateError] if any column is invalid.
  void validateTableConfiguration() {
    final tableConfig = table(Table<T>());
    final instance = newModelInstance();
    final modelColumns = instance.getFields().toSet();
    final errors = <String>[];

    // Check all table columns
    for (final column in tableConfig.getColumns()) {
      final columnName = column.getName();
      if (!modelColumns.contains(columnName)) {
        errors.add(
          '  - Column "$columnName" does not exist in model ${model.toString()}.\n'
          '    Available columns: ${modelColumns.join(", ")}',
        );
      }
    }

    // Check default sort column
    final defaultSort = tableConfig.getDefaultSort();
    if (defaultSort != null && !modelColumns.contains(defaultSort)) {
      errors.add(
        '  - Default sort column "$defaultSort" does not exist in model ${model.toString()}.\n'
        '    Available columns: ${modelColumns.join(", ")}',
      );
    }

    if (errors.isNotEmpty) {
      throw StateError(
        '\n❌ Table configuration error in $runtimeType:\n'
        '${errors.join('\n')}\n',
      );
    }
  }

  /// Fetches records for this resource with filtering, sorting, and pagination.
  /// Can be customized by overriding to add additional filters or eager loading.
  Future<List<T>> getRecords({String? searchQuery, String? sortColumn, String? sortDirection, int page = 1}) async {
    var q = query();
    final tableConfig = table(Table<T>());

    // Apply search across searchable columns
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final searchableColumns = tableConfig
          .getColumns()
          .where((col) => col.isSearchable())
          .map((col) => col.getName())
          .toList();

      if (searchableColumns.isNotEmpty) {
        // Build OR conditions for search
        for (var i = 0; i < searchableColumns.length; i++) {
          final column = searchableColumns[i];
          if (i == 0) {
            q = q.where(column, '%$searchQuery%', 'LIKE');
          } else {
            q = q.orWhere(column, '%$searchQuery%', 'LIKE');
          }
        }
      }
    }

    // Apply sorting
    final sortCol = sortColumn ?? tableConfig.getDefaultSort();
    final sortDir = sortDirection ?? tableConfig.getDefaultSortDirection();
    if (sortCol != null) {
      // Verify the column is sortable
      final isSortable = tableConfig.getColumns().any((col) => col.getName() == sortCol && col.isSortable());
      if (isSortable) {
        q = q.orderBy(sortCol, sortDir.toUpperCase());
      }
    }

    // Apply pagination
    if (tableConfig.isPaginated()) {
      final perPage = tableConfig.getRecordsPerPage();
      final offset = (page - 1) * perPage;
      q = q.limit(perPage).offset(offset);
    }

    return await q.get();
  }

  /// Gets the total count of records for pagination.
  /// Applies search filters but not pagination limits.
  Future<int> getRecordsCount({String? searchQuery}) async {
    var q = query();
    final tableConfig = table(Table<T>());

    // Apply search across searchable columns
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final searchableColumns = tableConfig
          .getColumns()
          .where((col) => col.isSearchable())
          .map((col) => col.getName())
          .toList();

      if (searchableColumns.isNotEmpty) {
        for (var i = 0; i < searchableColumns.length; i++) {
          final column = searchableColumns[i];
          if (i == 0) {
            q = q.where(column, '%$searchQuery%', 'LIKE');
          } else {
            q = q.orWhere(column, '%$searchQuery%', 'LIKE');
          }
        }
      }
    }

    return await q.count();
  }

  /// Finds a specific record by ID.
  Future<T?> findRecord(dynamic id) async {
    return await query().find(id);
  }

  /// Creates a ResourceIndex component for this resource with the provided records and query state.
  Component buildIndexPage({
    required List<T> records,
    int totalRecords = 0,
    String? searchQuery,
    String? sortColumn,
    String? sortDirection,
    int currentPage = 1,
  }) {
    return ResourceIndex<T>(
      resource: this,
      records: records,
      totalRecords: totalRecords,
      searchQuery: searchQuery,
      sortColumn: sortColumn,
      sortDirection: sortDirection,
      currentPage: currentPage,
    );
  }
}
