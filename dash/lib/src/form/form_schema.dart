import 'package:collection/collection.dart';
import 'package:dash_board/src/actions/action.dart';
import 'package:dash_board/src/form/fields/field.dart';
import 'package:dash_board/src/form/fields/grid.dart';
import 'package:dash_board/src/form/fields/section.dart';
import 'package:dash_board/src/model/annotations.dart';
import 'package:dash_board/src/model/model.dart';

/// A component that can be placed in a form schema.
/// This can be either a [FormField] or a [Section].
typedef FormComponent = Object;

/// A form schema that holds a collection of fields and sections.
///
/// The [FormSchema] is the container for form fields and manages
/// form state, validation, and rendering configuration.
///
/// Example:
/// ```dart
/// FormSchema form(FormSchema form) {
///   return form
///     .columns(2)
///     .fields([
///       TextInput.make('name')
///         .label('Full Name')
///         .required()
///         .columnSpan(2),
///       TextInput.make('email')
///         .email()
///         .required(),
///       PasswordInput.make('password')
///         .required()
///         .minLength(8),
///     ]);
/// }
/// ```
class FormSchema<T extends Model> {
  /// The components in this form (fields and sections).
  List<FormComponent> _components = [];

  /// The number of columns in the form grid.
  int _columns = 1;

  /// The gap between form elements.
  String _gap = '4';

  /// The state path prefix for all fields.
  String _statePath = 'data';

  /// The operation being performed (create, edit, view).
  FormOperation _operation = FormOperation.create;

  /// The model instance being edited (null for create).
  T? _record;

  /// Whether the form is disabled (read-only).
  bool _disabled = false;

  /// Custom submit button label.
  String? _submitLabel;

  /// Custom cancel button label.
  String? _cancelLabel;

  /// Whether to show the cancel button.
  bool _showCancelButton = true;

  /// The form action URL.
  String? _action;

  /// The form method (POST, PUT, PATCH).
  FormSubmitMethod _method = FormSubmitMethod.post;

  /// Custom form actions (submit, cancel, etc.).
  List<Action<T>>? _formActions;

  FormSchema();

  /// Sets the components (fields and sections) for this form.
  FormSchema<T> fields(List<FormComponent> components) {
    _components = components;
    return this;
  }

  /// Gets the components in this form.
  List<FormComponent> getComponents() => _components;

  /// Gets all fields from components (flattening sections and grids).
  List<FormField> getFields() {
    final fields = <FormField>[];
    for (final component in _components) {
      if (component is FormField) {
        fields.add(component);
      } else if (component is Section) {
        fields.addAll(component.getFields());
      } else if (component is Grid) {
        fields.addAll(component.getFields());
      }
    }
    return fields;
  }

  /// Adds a component to this form.
  FormSchema<T> field(FormComponent component) {
    _components.add(component);
    return this;
  }

  /// Sets the number of columns in the form grid.
  FormSchema<T> columns(int columns) {
    _columns = columns;
    return this;
  }

  /// Gets the number of columns.
  int getColumns() => _columns;

  /// Sets the gap between form elements (Tailwind spacing scale).
  FormSchema<T> gap(String gap) {
    _gap = gap;
    return this;
  }

  /// Gets the gap value.
  String getGap() => _gap;

  /// Sets the state path prefix.
  FormSchema<T> statePath(String path) {
    _statePath = path;
    return this;
  }

  /// Gets the state path.
  String getStatePath() => _statePath;

  /// Sets the operation type.
  FormSchema<T> operation(FormOperation operation) {
    _operation = operation;
    return this;
  }

  /// Gets the operation type.
  FormOperation getOperation() => _operation;

  /// Sets the model record being edited.
  FormSchema<T> record(T? record) {
    _record = record;
    return this;
  }

  /// Gets the model record.
  T? getRecord() => _record;

  /// Disables all form fields.
  FormSchema<T> disabled([bool disabled = true]) {
    _disabled = disabled;
    return this;
  }

  /// Checks if the form is disabled.
  bool isDisabled() => _disabled;

  /// Sets the submit button label.
  FormSchema<T> submitLabel(String label) {
    _submitLabel = label;
    return this;
  }

  /// Gets the submit button label.
  String getSubmitLabel() {
    if (_submitLabel != null) return _submitLabel!;
    return switch (_operation) {
      FormOperation.create => 'Create',
      FormOperation.edit => 'Save changes',
      FormOperation.view => 'Close',
    };
  }

  /// Sets the cancel button label.
  FormSchema<T> cancelLabel(String label) {
    _cancelLabel = label;
    return this;
  }

  /// Gets the cancel button label.
  String getCancelLabel() => _cancelLabel ?? 'Cancel';

  /// Shows or hides the cancel button.
  FormSchema<T> showCancelButton([bool show = true]) {
    _showCancelButton = show;
    return this;
  }

  /// Checks if the cancel button should be shown.
  bool shouldShowCancelButton() => _showCancelButton;

  /// Sets the form action URL.
  FormSchema<T> action(String url) {
    _action = url;
    return this;
  }

  /// Gets the form action URL.
  String? getAction() => _action;

  /// Sets the form method.
  FormSchema<T> method(FormSubmitMethod method) {
    _method = method;
    return this;
  }

  /// Gets the form method.
  FormSubmitMethod getMethod() => _method;

  /// Sets custom form actions (submit, cancel, etc.).
  ///
  /// When set, these actions replace the default submit/cancel buttons.
  /// ```dart
  /// form.formActions([
  ///   SaveAction.make(),
  ///   CancelAction.make(),
  ///   Action.make<User>('preview').label('Preview').color(ActionColor.info),
  /// ]);
  /// ```
  FormSchema<T> formActions(List<Action<T>> actions) {
    _formActions = actions;
    return this;
  }

  /// Gets the custom form actions, if set.
  List<Action<T>>? getFormActions() => _formActions;

  /// Checks if custom form actions are set.
  bool hasFormActions() => _formActions != null && _formActions!.isNotEmpty;

  /// Fills the form with data from the record.
  /// Note: This does not handle relationship loading. Use [fillAsync] for that.
  void fill() {
    if (_record == null) return;

    final data = _record!.toMap();
    for (final field in getFields()) {
      final name = field.getName();
      if (data.containsKey(name)) {
        field.defaultValue(data[name]);
      }
    }
  }

  /// Fills the form with data from the record, including relationship loading.
  ///
  /// This method properly handles:
  /// - Simple field values from the record
  /// - BelongsTo relationship fields (loads related model via foreign key)
  /// - HasMany relationship fields (loads related IDs from pivot table)
  /// - Applies hydration callbacks if defined on fields
  ///
  /// Example:
  /// ```dart
  /// final schema = resource.form(FormSchema<User>())
  ///   ..record(user)
  ///   ..operation(FormOperation.edit);
  /// await schema.fillAsync();
  /// ```
  Future<void> fillAsync() async {
    if (_record == null) return;

    final recordData = _record!.toMap();
    final relationships = _record!.getRelationships();

    for (final field in getFields()) {
      field.record = _record;

      final name = field.getName();
      final relationship = relationships.where((rel) => rel.name == name).firstOrNull;

      dynamic value;
      if (relationship != null) {
        if (relationship.type == RelationshipType.belongsTo && recordData.containsKey(relationship.foreignKey)) {
          // BelongsTo: use the foreign key value
          value = recordData[relationship.foreignKey];
          // Load the related model for display purposes
          await _record!.loadRelationship(name, value);
        } else if (relationship.type == RelationshipType.hasMany && relationship.usesPivotTable) {
          // HasMany: load related IDs from pivot table
          value = await _loadHasManyIds(relationship);
        }
      } else if (recordData.containsKey(name)) {
        value = recordData[name];
      }

      if (value != null) {
        // Apply hydration if defined
        value = field.hydrateValue(value);
        field.defaultValue(value);
      }
    }
  }

  /// Loads the IDs of related records for a hasMany relationship.
  Future<List<dynamic>> _loadHasManyIds(RelationshipMeta meta) async {
    if (_record == null || _record!.getKey() == null) return [];

    try {
      // Use the base Model's loadHasManyIds method
      return await _record!.loadHasManyIds(meta.name);
    } catch (e) {
      // Pivot table might not exist yet
      return [];
    }
  }

  /// Collects validation rules from all fields.
  Map<String, List<String>> getValidationRules() {
    final rules = <String, List<String>>{};
    for (final field in getFields()) {
      final fieldRules = field.getValidationRules();
      if (fieldRules.isNotEmpty) {
        rules[field.getName()] = fieldRules;
      }
    }
    return rules;
  }

  /// Validates the given data against all field rules.
  /// Returns a map of field names to error messages.
  Map<String, List<String>> validate(Map<String, dynamic> data) {
    final errors = <String, List<String>>{};

    for (final field in getFields()) {
      final value = data[field.getName()];
      final fieldErrors = field.validate(value);
      if (fieldErrors.isNotEmpty) {
        errors[field.getName()] = fieldErrors;
      }
    }

    return errors;
  }

  /// Gets the initial data for the form.
  Map<String, dynamic> getInitialData() {
    final data = <String, dynamic>{};

    if (_record != null) {
      data.addAll(_record!.toMap());
    }

    // Override with field defaults where applicable
    for (final field in getFields()) {
      final defaultVal = field.getDefaultValue();
      if (defaultVal != null && !data.containsKey(field.getName())) {
        data[field.getName()] = defaultVal;
      }
    }

    return data;
  }
}

/// The type of form operation.
enum FormOperation { create, edit, view }

/// The HTTP method for form submission.
enum FormSubmitMethod { post, put, patch }
