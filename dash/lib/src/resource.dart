import 'package:collection/collection.dart';
import 'package:dash_board/src/actions/action.dart';
import 'package:dash_board/src/actions/prebuilt/cancel_action.dart';
import 'package:dash_board/src/actions/prebuilt/create_action.dart';
import 'package:dash_board/src/actions/prebuilt/edit_action.dart';
import 'package:dash_board/src/actions/prebuilt/save_action.dart';
import 'package:dash_board/src/components/interactive/component_registry.dart';
import 'package:dash_board/src/components/pages/resource_form.dart';
import 'package:dash_board/src/components/pages/resource_index.dart';
import 'package:dash_board/src/components/pages/resource_view.dart';
import 'package:dash_board/src/components/partials/heroicon.dart';
import 'package:dash_board/src/database/migrations/schema_definition.dart';
import 'package:dash_board/src/form/fields/has_many_select.dart';
import 'package:dash_board/src/form/fields/relationship_select.dart';
import 'package:dash_board/src/form/form_schema.dart';
import 'package:dash_board/src/model/annotations.dart';
import 'package:dash_board/src/model/model.dart';
import 'package:dash_board/src/model/model_query_builder.dart';
import 'package:dash_board/src/panel/panel_config.dart';
import 'package:dash_board/src/service_locator.dart';
import 'package:dash_board/src/table/table.dart';
import 'package:dash_board/src/utils/sanitization.dart';
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

  T get modelInstance => modelInstanceFromSlug<Model>(slug) as T;

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
  /// Derived from the model name in snake_case.
  String get slug => _toSnakeCase(_modelName);

  /// Converts a string to snake_case.
  String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(RegExp(r'[A-Z]'), (match) => '_${match.group(0)!.toLowerCase()}')
        .replaceFirst(RegExp(r'^_'), '');
  }

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

  /// Defines the header actions for the index page.
  ///
  /// Override this method to customize the actions shown in the page header.
  /// By default, shows a "New {singularLabel}" create button.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// List<Action<User>> indexHeaderActions() => [
  ///   CreateAction.make(singularLabel),
  ///   Action.make<User>('export')
  ///     .label('Export')
  ///     .icon(HeroIcons.arrowDownTray)
  ///     .color(ActionColor.secondary),
  /// ];
  /// ```
  List<Action<T>> indexHeaderActions() {
    return [CreateAction.make<T>(singularLabel)];
  }

  /// Defines the form actions for create/edit pages.
  ///
  /// Override this method to customize the actions shown at the bottom of forms.
  /// By default, shows a save/create button and cancel button.
  ///
  /// The [operation] parameter indicates whether this is a create, edit, or view form.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// List<Action<User>> formActions(FormOperation operation) => [
  ///   SaveAction.make(operation: operation),
  ///   CancelAction.make(),
  ///   if (operation == FormOperation.edit)
  ///     Action.make<User>('preview')
  ///       .label('Preview')
  ///       .color(ActionColor.info),
  /// ];
  /// ```
  List<Action<T>> formActions(FormOperation operation) {
    return [SaveAction.make<T>(operation: operation), CancelAction.make<T>()];
  }

  /// Defines the header actions for the view page.
  ///
  /// Override this method to customize the actions shown in the view page header.
  /// By default, shows an "Edit" button.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// List<Action<User>> viewHeaderActions() => [
  ///   EditAction.make(),
  ///   Action.make<User>('export')
  ///     .label('Export')
  ///     .icon(HeroIcons.arrowDownTray)
  ///     .color(ActionColor.secondary),
  /// ];
  /// ```
  List<Action<T>> viewHeaderActions() {
    return [EditAction.make<T>()];
  }

  /// Defines the form actions for view pages (displayed at bottom of view form).
  ///
  /// Override this method to customize the actions shown at the bottom of view pages.
  /// By default, shows an "Edit" button and a "Back" button.
  ///
  /// The [recordId] parameter is the ID of the record being viewed,
  /// used to construct the edit URL.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// List<Action<User>> viewFormActions(dynamic recordId) => [
  ///   Action.make<User>('edit')
  ///     .label('Edit')
  ///     .color(ActionColor.primary)
  ///     .url((_, basePath) => '$basePath/$recordId/edit'),
  ///   CancelAction.make(),
  /// ];
  /// ```
  List<Action<T>> viewFormActions(dynamic recordId) {
    return [CancelAction.make<T>().label('Back')];
  }

  /// Gets the base path for this resource's routes.
  String _getBasePath() {
    return '${inject<PanelConfig>().path}/resources/$slug';
  }

  /// Creates a factory for the ResourceIndex component.
  /// Used to register the component with the ComponentRegistry.
  InteractiveComponentFactory get indexComponentFactory => ResourceIndex<T>.new;

  /// Creates a new instance of the model.
  /// Uses the DI-registered model factory.
  T newModelInstance() {
    return modelInstance;
  }

  /// Gets the table schema for this resource's model.
  TableSchema get schema => modelInstance.schema;

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

    // Include timestamp columns if timestamps are enabled
    if (instance.timestamps) {
      modelColumns.add(instance.createdAtColumn);
      modelColumns.add(instance.updatedAtColumn);
    }

    // Get relationship names for validation of dot notation columns
    final relationshipNames = instance.getRelationships().map((r) => r.name).toSet();

    final errors = <String>[];

    // Check all table columns
    for (final column in tableConfig.getColumns()) {
      final columnName = column.getName();

      // Handle dot notation (e.g., 'author.name')
      if (columnName.contains('.')) {
        final parts = columnName.split('.');
        final relationName = parts.first;

        // Validate that the relationship exists
        if (!relationshipNames.contains(relationName)) {
          errors.add(
            '  - Relationship "$relationName" (from column "$columnName") does not exist in model ${model.toString()}.\n'
            '    Available relationships: ${relationshipNames.join(", ")}',
          );
        }
        // Note: We can't validate nested property names at this level without loading the related model
        continue;
      }

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
              q = q.where(column, 'LIKE', '%$sanitized%');
            } else {
              q = q.orWhere(column, 'LIKE', '%$sanitized%');
            }
          }
        }
      }
    }

    // Apply sorting
    // Treat empty strings as null to fall back to defaults
    final sortCol = (sortColumn?.isEmpty ?? true) ? tableConfig.getDefaultSort() : sortColumn;
    final sortDir = (sortDirection?.isEmpty ?? true) ? tableConfig.getDefaultSortDirection() : sortDirection;
    if (sortCol != null && isValidColumnName(sortCol)) {
      // Verify the column is sortable
      final isSortable = tableConfig.getColumns().any((col) => col.getName() == sortCol && col.isSortable());
      if (isSortable) {
        q = q.orderBy(sortCol, (sortDir ?? 'asc').toUpperCase());
      }
    }

    // Apply pagination
    if (tableConfig.isPaginated()) {
      final perPage = tableConfig.getRecordsPerPage();
      final offset = (page - 1) * perPage;
      q = q.limit(perPage).offset(offset);
    }

    final records = await q.get();

    // Load required relationships
    await loadRelationships(records, tableConfig);

    return records;
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
              q = q.where(column, 'LIKE', '%$sanitized%');
            } else {
              q = q.orWhere(column, 'LIKE', '%$sanitized%');
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

  /// Loads relationships required by the table configuration.
  /// Uses eager loading to minimize database queries.
  Future<void> loadRelationships(List<T> records, Table<T> tableConfig) async {
    if (records.isEmpty) return;

    final requiredRelations = tableConfig.getRequiredRelationships();
    if (requiredRelations.isEmpty) return;

    final sampleRecord = records.first;
    final relationships = sampleRecord.getRelationships();

    for (final relationName in requiredRelations) {
      final relationMeta = relationships.where((r) => r.name == relationName).firstOrNull;
      if (relationMeta == null) continue;

      if (relationMeta.type == RelationshipType.belongsTo) {
        await _loadBelongsToRelation(records, relationMeta);
      }
    }
  }

  /// Loads a BelongsTo relationship for a list of records.
  /// Uses a single query to fetch all related records efficiently.
  Future<void> _loadBelongsToRelation(List<T> records, RelationshipMeta meta) async {
    // Convert model type name to slug (e.g., "User" -> "user")
    final relatedSlug = _toSnakeCase(meta.relatedModelType);

    // Try to get the related model instance from DI
    final relatedModel = modelInstanceFromSlug<Model>(relatedSlug);

    // Collect all foreign key values
    final foreignKeyValues = <dynamic>{};
    for (final record in records) {
      final fkValue = record.toMap()[meta.foreignKey];
      if (fkValue != null) {
        foreignKeyValues.add(fkValue);
      }
    }

    if (foreignKeyValues.isEmpty) return;

    // Fetch all related records in a single query
    final relatedRecords = await ModelQueryBuilder<Model>(
      Model.connector,
      modelFactory: () => modelInstanceFromSlug<Model>(relatedSlug),
      modelTable: relatedModel.table,
      modelPrimaryKey: relatedModel.primaryKey,
    ).whereIn(meta.relatedKey, foreignKeyValues.toList()).get();

    // Create a lookup map by the related key
    final relatedMap = <dynamic, Model>{};
    for (final related in relatedRecords) {
      final keyValue = related.toMap()[meta.relatedKey];
      if (keyValue != null) {
        relatedMap[keyValue] = related;
      }
    }

    // Assign the related records to each parent record
    for (final record in records) {
      final fkValue = record.toMap()[meta.foreignKey];
      if (fkValue != null && relatedMap.containsKey(fkValue)) {
        record.setRelation(meta.name, relatedMap[fkValue]!);
      }
    }
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
    ).build();
  }

  /// Creates a ResourceForm component for creating a new record.
  ///
  /// This method prepares a [FormSchema] with:
  /// - Operation set to create mode
  /// - Form action and method configured
  Component buildCreatePage({Map<String, List<String>>? errors, Map<String, dynamic>? oldInput}) {
    final formSchema = form(FormSchema<T>());
    _initializeFields(formSchema);

    formSchema.operation(FormOperation.create).action('${_getBasePath()}/store').method(FormSubmitMethod.post);

    // Set form actions from resource
    formSchema.formActions(formActions(FormOperation.create));

    return ResourceForm<T>(resource: this, formSchema: formSchema, errors: errors, oldInput: oldInput);
  }

  /// Creates a ResourceForm component for editing an existing record.
  ///
  /// This method prepares a [FormSchema] with:
  /// - The record data populated into fields
  /// - Relationships loaded for related fields
  /// - Operation set to edit mode
  /// - Form action and method configured
  Future<Component> buildEditPage({
    required T record,
    Map<String, List<String>>? errors,
    Map<String, dynamic>? oldInput,
  }) async {
    // Build and populate the form schema
    final formSchema = form(FormSchema<T>());
    _initializeFields(formSchema);
    final recordId = record.toMap()[record.primaryKey];

    formSchema
        .operation(FormOperation.edit)
        .record(record)
        .action('${_getBasePath()}/$recordId')
        .method(FormSubmitMethod.put);

    // Populate fields from the record (including relationship loading)
    await formSchema.fillAsync();

    // Set form actions from resource
    formSchema.formActions(formActions(FormOperation.edit));

    return ResourceForm<T>(resource: this, record: record, formSchema: formSchema, errors: errors, oldInput: oldInput);
  }

  /// Creates a ResourceView component for viewing an existing record.
  ///
  /// This method prepares a [FormSchema] with:
  /// - The record data populated into fields
  /// - Operation set to view mode
  /// - All fields disabled (read-only)
  Component buildViewPage({required T record}) {
    final formSchema = form(FormSchema<T>());
    _initializeFields(formSchema);
    final recordId = record.toMap()[record.primaryKey];

    formSchema.operation(FormOperation.view).record(record).disabled(true).showCancelButton(false);

    // Populate fields from the record (sync version is fine for view)
    formSchema.fill();

    // Set view-specific form actions
    formSchema.formActions(viewFormActions(recordId));

    return ResourceView<T>(resource: this, record: record, formSchema: formSchema);
  }

  void _initializeFields(FormSchema<T> schema) {
    final relationships = modelInstance.getRelationships();
    for (final field in schema.getFields()) {
      if (field is HasManySelect) {
        final meta = relationships.firstWhereOrNull((r) => r.name == field.getName());
        if (meta != null) {
          field.inferFrom(meta);
        }
      } else if (field is RelationshipSelect) {
        final meta = relationships.firstWhereOrNull((r) => r.name == field.getName());
        if (meta != null) {
          field.inferFrom(meta);
        }
      }
    }
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

    // Extract hasMany relationship data before applying to model
    final hasManyData = _extractHasManyData(data);

    // Apply the form data to the model
    _applyDataToModel(instance, data);

    // Save the model
    await instance.save();

    // Sync hasMany relationships after the main record is saved
    await _syncHasManyRelationships(instance, hasManyData);

    return instance;
  }

  /// Updates an existing record with the given data.
  /// Override this method to customize record updates.
  Future<T> updateRecord(T record, Map<String, dynamic> data) async {
    // Extract hasMany relationship data before applying to model
    final hasManyData = _extractHasManyData(data);

    // Apply the form data to the model
    _applyDataToModel(record, data);

    // Save the model
    await record.save();

    // Sync hasMany relationships after the main record is saved
    await _syncHasManyRelationships(record, hasManyData);

    return record;
  }

  /// Deletes a record.
  /// Override this method to customize record deletion.
  Future<void> deleteRecord(T record) async {
    await record.delete();
  }

  /// Extracts hasMany relationship data from form data.
  /// Returns a map of relationship names to lists of related IDs.
  Map<String, List<dynamic>> _extractHasManyData(Map<String, dynamic> data) {
    final hasManyData = <String, List<dynamic>>{};
    final formSchema = form(FormSchema<T>());
    final instance = newModelInstance();
    final relationships = instance.getRelationships();

    for (final field in formSchema.getFields()) {
      final fieldName = field.getName();
      // Check if this field corresponds to a hasMany relationship
      final relationMeta = relationships
          .where((r) => r.name == fieldName && r.type == RelationshipType.hasMany)
          .firstOrNull;

      if (relationMeta != null && data.containsKey(fieldName)) {
        // Get the value and convert to list
        final value = data[fieldName];

        if (value == null) {
          hasManyData[fieldName] = [];
        } else if (value is List) {
          hasManyData[fieldName] = value.map(_convertToIdType).toList();
        } else if (value is String && value.isEmpty) {
          hasManyData[fieldName] = [];
        } else {
          hasManyData[fieldName] = [_convertToIdType(value)];
        }
      }
    }

    return hasManyData;
  }

  /// Converts a value to an appropriate ID type (int if possible).
  dynamic _convertToIdType(dynamic value) {
    if (value is int) return value;
    if (value is String) {
      final asInt = int.tryParse(value);
      if (asInt != null) return asInt;
    }
    return value;
  }

  /// Syncs hasMany relationships for a record.
  /// Uses the model's syncMany method to update pivot tables.
  Future<void> _syncHasManyRelationships(T record, Map<String, List<dynamic>> hasManyData) async {
    if (hasManyData.isEmpty) return;

    final relationships = record.getRelationships();

    for (final entry in hasManyData.entries) {
      final relationName = entry.key;
      final relatedIds = entry.value;

      final relationMeta = relationships
          .where((r) => r.name == relationName && r.type == RelationshipType.hasMany)
          .firstOrNull;

      if (relationMeta != null && relationMeta.usesPivotTable) {
        // Use the base Model's generic syncMany method
        await record.syncMany(relationName, relatedIds);
      }
    }
  }

  /// Applies form data to a model instance.
  /// Maps form field names to model fields.
  ///
  /// Each field is responsible for converting its value to the appropriate
  /// database type via its `dehydrateValue()` method.
  void _applyDataToModel(T model, Map<String, dynamic> data) {
    // Get the form schema to understand field mappings
    final formSchema = form(FormSchema<T>());
    final fields = formSchema.getFields();

    // Get relationship metadata from the model to map relation names to foreign keys
    final relationships = model.getRelationships();
    final relationForeignKeys = <String, String>{};
    for (final rel in relationships) {
      if (rel.type == RelationshipType.belongsTo) {
        relationForeignKeys[rel.name] = rel.foreignKey;
      }
    }

    // Build a map of converted values
    final convertedData = <String, dynamic>{};

    for (final field in fields) {
      final fieldName = field.getName();
      if (data.containsKey(fieldName)) {
        // Set the record on the field so it can access the schema for type conversion
        field.record = model;

        // Apply dehydration - each field type handles its own type conversion
        final value = field.dehydrateValue(data[fieldName]);

        // Check if this field maps to a belongsTo relationship's foreign key
        if (relationForeignKeys.containsKey(fieldName)) {
          convertedData[relationForeignKeys[fieldName]!] = value;
        } else {
          convertedData[fieldName] = value;
        }
      }
    }

    // Merge with existing model data and apply
    final existingData = model.toMap();
    final mergedData = {...existingData, ...convertedData};
    model.fromMap(mergedData);
  }
}
