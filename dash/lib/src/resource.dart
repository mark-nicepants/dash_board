import 'package:dash/src/components/pages/resource_create.dart';
import 'package:dash/src/components/pages/resource_edit.dart';
import 'package:dash/src/components/pages/resource_index.dart';
import 'package:dash/src/components/partials/heroicon.dart';
import 'package:dash/src/database/migrations/schema_definition.dart';
import 'package:dash/src/form/form_schema.dart';
import 'package:dash/src/model/model.dart';
import 'package:dash/src/model/model_metadata.dart';
import 'package:dash/src/model/model_query_builder.dart';
import 'package:dash/src/table/table.dart';
import 'package:dash/src/utils/sanitization.dart';
import 'package:jaspr/jaspr.dart';

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
  /// The model class associated with this resource. Defaults to [T].
  Type get model => T;

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

  /// Defines the form configuration for creating and editing this resource.
  ///
  /// Override this method to configure the form fields.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// FormSchema form(FormSchema form) {
  ///   return form
  ///     .columns(2)
  ///     .fields([
  ///       TextInput.make('name')
  ///         .required()
  ///         .columnSpanFull(),
  ///       TextInput.make('email')
  ///         .email()
  ///         .required(),
  ///       Select.make('role')
  ///         .options([
  ///           SelectOption('user', 'User'),
  ///           SelectOption('admin', 'Admin'),
  ///         ]),
  ///     ]);
  /// }
  /// ```
  FormSchema<T> form(FormSchema<T> form) {
    return form;
  }

  /// Creates a new instance of the model.
  /// Uses generated metadata when available, otherwise subclasses must override.
  T newModelInstance() {
    final metadata = getModelMetadata<T>();
    if (metadata != null) {
      return metadata.modelFactory();
    }

    throw StateError(
      'No model factory registered for ${T.toString()}. '
      'Override newModelInstance() in ${runtimeType.toString()} to provide one.',
    );
  }

  /// Gets the table schema for this resource's model.
  /// Defaults to the generated schema when available.
  TableSchema? schema() {
    final metadata = getModelMetadata<T>();
    return metadata?.schema;
  }

  /// Creates a query builder for the model.
  /// Uses the model instance to configure the query.
  ModelQueryBuilder<T> query() {
    final instance = newModelInstance();
    return ModelQueryBuilder<T>(
      Model.connector,
      modelFactory: newModelInstance,
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
      // Sanitize the search query to prevent SQL injection via wildcards
      final sanitized = sanitizeSearchQuery(searchQuery);

      if (sanitized.isNotEmpty) {
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
              q = q.where(column, '%$sanitized%', 'LIKE');
            } else {
              q = q.orWhere(column, '%$sanitized%', 'LIKE');
            }
          }
        }
      }
    }

    // Apply sorting
    final sortCol = sortColumn ?? tableConfig.getDefaultSort();
    final sortDir = sortDirection ?? tableConfig.getDefaultSortDirection();
    if (sortCol != null && isValidColumnName(sortCol)) {
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
      // Sanitize the search query to prevent SQL injection via wildcards
      final sanitized = sanitizeSearchQuery(searchQuery);

      if (sanitized.isNotEmpty) {
        final searchableColumns = tableConfig
            .getColumns()
            .where((col) => col.isSearchable())
            .map((col) => col.getName())
            .toList();

        if (searchableColumns.isNotEmpty) {
          for (var i = 0; i < searchableColumns.length; i++) {
            final column = searchableColumns[i];
            if (i == 0) {
              q = q.where(column, '%$sanitized%', 'LIKE');
            } else {
              q = q.orWhere(column, '%$sanitized%', 'LIKE');
            }
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

  /// Creates a ResourceCreate component for this resource.
  Component buildCreatePage({Map<String, List<String>>? errors, Map<String, dynamic>? oldInput}) {
    return ResourceCreate<T>(resource: this, errors: errors, oldInput: oldInput);
  }

  /// Creates a ResourceEdit component for this resource with the provided record.
  Component buildEditPage({required T record, Map<String, List<String>>? errors, Map<String, dynamic>? oldInput}) {
    return ResourceEdit<T>(resource: this, record: record, errors: errors, oldInput: oldInput);
  }

  /// Creates a new FormSchema instance for this resource.
  /// Used internally by the router for form validation.
  FormSchema<T> newFormSchema() {
    return FormSchema<T>();
  }

  /// Creates a new record with the given data.
  /// Override this method to customize record creation.
  Future<T> createRecord(Map<String, dynamic> data) async {
    final instance = newModelInstance();

    // Apply the form data to the model
    _applyDataToModel(instance, data);

    // Save the model
    await instance.save();

    return instance;
  }

  /// Updates an existing record with the given data.
  /// Override this method to customize record updates.
  Future<T> updateRecord(T record, Map<String, dynamic> data) async {
    // Apply the form data to the model
    _applyDataToModel(record, data);

    // Save the model
    await record.save();

    return record;
  }

  /// Deletes a record.
  /// Override this method to customize record deletion.
  Future<void> deleteRecord(T record) async {
    await record.delete();
  }

  /// Applies form data to a model instance.
  /// Maps form field names to model fields.
  void _applyDataToModel(T model, Map<String, dynamic> data) {
    // Get the form schema to understand field mappings
    final formSchema = form(FormSchema<T>());
    final fields = formSchema.getFields();

    // Build a map of converted values
    final convertedData = <String, dynamic>{};

    for (final field in fields) {
      final fieldName = field.getName();
      if (data.containsKey(fieldName)) {
        final value = data[fieldName];
        convertedData[fieldName] = _convertFieldValue(field, value);
      }
    }

    // Merge with existing model data and apply
    final existingData = model.toMap();
    final mergedData = {...existingData, ...convertedData};
    model.fromMap(mergedData);
  }

  /// Converts a form field value to the appropriate type.
  dynamic _convertFieldValue(dynamic field, dynamic value) {
    if (value == null || (value is String && value.isEmpty)) {
      return null;
    }

    // Handle different field types
    final fieldType = field.runtimeType.toString();

    if (fieldType.contains('Checkbox') || fieldType.contains('Toggle')) {
      // Boolean fields
      if (value is bool) return value;
      if (value is String) {
        return value == 'true' || value == '1' || value == 'on';
      }
      return false;
    }

    if (fieldType.contains('DatePicker')) {
      // DateTime fields
      if (value is DateTime) return value;
      if (value is String) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    if (fieldType.contains('Select') && field.isMultiple()) {
      // Multiple select - return list
      if (value is List) return value;
      if (value is String) return [value];
      return [];
    }

    // Default - return as-is (usually String)
    return value;
  }
}
