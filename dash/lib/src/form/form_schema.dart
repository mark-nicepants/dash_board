import 'package:dash/src/form/fields/field.dart';
import 'package:dash/src/model/model.dart';

/// A form schema that holds a collection of fields.
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
  /// The fields in this form.
  List<FormField> _fields = [];

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

  FormSchema();

  /// Sets the fields for this form.
  FormSchema<T> fields(List<FormField> fields) {
    _fields = fields;
    return this;
  }

  /// Gets the fields in this form.
  List<FormField> getFields() => _fields;

  /// Adds a field to this form.
  FormSchema<T> field(FormField field) {
    _fields.add(field);
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

  /// Fills the form with data from the record.
  void fill() {
    if (_record == null) return;

    final data = _record!.toMap();
    for (final field in _fields) {
      final name = field.getName();
      if (data.containsKey(name)) {
        field.defaultValue(data[name]);
      }
    }
  }

  /// Collects validation rules from all fields.
  Map<String, List<String>> getValidationRules() {
    final rules = <String, List<String>>{};
    for (final field in _fields) {
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

    for (final field in _fields) {
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
    for (final field in _fields) {
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
