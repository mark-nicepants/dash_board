import 'package:dash/src/validation/validation.dart';
import 'package:jaspr/jaspr.dart';

// Re-export validation rules for convenience
export 'package:dash/src/validation/validation.dart'
    show
        ValidationRule,
        Required,
        Email,
        Url,
        MinLength,
        MaxLength,
        Numeric,
        Integer,
        Min,
        Max,
        InList,
        Pattern,
        Accepted,
        Confirmed;

/// Base class for all form fields.
///
/// A [FormField] defines a single input element in a form with
/// its configuration, validation, and rendering behavior.
///
/// Example:
/// ```dart
/// TextInput.make('email')
///   .label('Email Address')
///   .placeholder('you@example.com')
///   .required()
///   .email()
///   .helperText('We will never share your email.')
/// ```
abstract class FormField {
  /// The name of the field (corresponds to model attribute).
  final String _name;

  /// The field ID (defaults to name if not set).
  String? _id;

  /// The label displayed above the field.
  String? _label;

  /// Placeholder text inside the field.
  String? _placeholder;

  /// Helper text displayed below the field.
  String? _helperText;

  /// Hint displayed alongside the field.
  String? _hint;

  /// The default value for the field.
  dynamic _default;

  /// Whether the field is required.
  bool _required = false;

  /// Whether the field is disabled.
  bool _disabled = false;

  /// Whether the field is readonly.
  bool _readonly = false;

  /// Whether the field is hidden.
  bool _hidden = false;

  /// The number of columns this field spans.
  int _columnSpan = 1;

  /// The number of columns this field spans on different breakpoints.
  final Map<String, int> _columnSpanBreakpoints = {};

  /// Custom CSS classes for the field.
  String? _extraClasses;

  /// Validation rules for this field.
  final List<ValidationRule> _rules = [];

  /// Custom validation messages.
  final Map<String, String> _validationMessages = {};

  /// Whether to autofocus this field.
  bool _autofocus = false;

  /// Autocomplete attribute value.
  String? _autocomplete;

  /// Tab index for keyboard navigation.
  int? _tabindex;

  FormField(this._name);

  /// Gets the field name.
  String getName() => _name;

  /// Sets the field ID.
  T id<T extends FormField>(String id) {
    _id = id;
    return this as T;
  }

  /// Gets the field ID.
  String getId() => _id ?? _name;

  /// Sets the label for the field.
  T label<T extends FormField>(String label) {
    _label = label;
    return this as T;
  }

  /// Gets the label.
  /// Defaults to a humanized version of the name if not set.
  String getLabel() {
    if (_label != null) return _label!;

    // Convert snake_case or camelCase to Title Case
    final words = _name
        .replaceAllMapped(RegExp(r'[A-Z]'), (match) => ' ${match.group(0)}')
        .replaceAll('_', ' ')
        .split(' ')
        .where((w) => w.isNotEmpty);

    return words.map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase()).join(' ');
  }

  /// Sets the placeholder text.
  T placeholder<T extends FormField>(String placeholder) {
    _placeholder = placeholder;
    return this as T;
  }

  /// Gets the placeholder.
  String? getPlaceholder() => _placeholder;

  /// Sets the helper text.
  T helperText<T extends FormField>(String text) {
    _helperText = text;
    return this as T;
  }

  /// Gets the helper text.
  String? getHelperText() => _helperText;

  /// Sets the hint.
  T hint<T extends FormField>(String hint) {
    _hint = hint;
    return this as T;
  }

  /// Gets the hint.
  String? getHint() => _hint;

  /// Sets the default value.
  T defaultValue<T extends FormField>(dynamic value) {
    _default = value;
    return this as T;
  }

  /// Gets the default value.
  dynamic getDefaultValue() => _default;

  /// Marks the field as required.
  T required<T extends FormField>([bool required = true]) {
    _required = required;
    if (required && !_rules.any((r) => r is Required)) {
      _rules.add(Required());
    }
    return this as T;
  }

  /// Checks if the field is required.
  bool isRequired() => _required;

  /// Disables the field.
  T disabled<T extends FormField>([bool disabled = true]) {
    _disabled = disabled;
    return this as T;
  }

  /// Checks if the field is disabled.
  bool isDisabled() => _disabled;

  /// Makes the field readonly.
  T readonly<T extends FormField>([bool readonly = true]) {
    _readonly = readonly;
    return this as T;
  }

  /// Checks if the field is readonly.
  bool isReadonly() => _readonly;

  /// Hides the field.
  T hidden<T extends FormField>([bool hidden = true]) {
    _hidden = hidden;
    return this as T;
  }

  /// Checks if the field is hidden.
  bool isHidden() => _hidden;

  /// Sets the column span.
  T columnSpan<T extends FormField>(int span) {
    _columnSpan = span;
    return this as T;
  }

  /// Gets the column span.
  int getColumnSpan() => _columnSpan;

  /// Sets column span for a specific breakpoint.
  T columnSpanBreakpoint<T extends FormField>(String breakpoint, int span) {
    _columnSpanBreakpoints[breakpoint] = span;
    return this as T;
  }

  /// Gets the column span breakpoints.
  Map<String, int> getColumnSpanBreakpoints() => _columnSpanBreakpoints;

  /// Makes this field span all columns.
  T columnSpanFull<T extends FormField>() {
    _columnSpan = -1; // -1 indicates full width
    return this as T;
  }

  /// Checks if the field spans full width.
  bool isColumnSpanFull() => _columnSpan == -1;

  /// Sets extra CSS classes.
  T extraClasses<T extends FormField>(String classes) {
    _extraClasses = classes;
    return this as T;
  }

  /// Gets extra CSS classes.
  String? getExtraClasses() => _extraClasses;

  /// Adds a validation rule.
  T rule<T extends FormField>(ValidationRule rule) {
    _rules.add(rule);
    return this as T;
  }

  /// Adds multiple validation rules.
  T rules<T extends FormField>(List<ValidationRule> rules) {
    _rules.addAll(rules);
    return this as T;
  }

  /// Sets a custom validation message.
  T validationMessage<T extends FormField>(String rule, String message) {
    _validationMessages[rule] = message;
    return this as T;
  }

  /// Sets the autofocus.
  T autofocus<T extends FormField>([bool autofocus = true]) {
    _autofocus = autofocus;
    return this as T;
  }

  /// Checks if the field should autofocus.
  bool shouldAutofocus() => _autofocus;

  /// Sets the autocomplete attribute.
  T autocomplete<T extends FormField>(String value) {
    _autocomplete = value;
    return this as T;
  }

  /// Gets the autocomplete attribute.
  String? getAutocomplete() => _autocomplete;

  /// Sets the tabindex.
  T tabindex<T extends FormField>(int index) {
    _tabindex = index;
    return this as T;
  }

  /// Gets the tabindex.
  int? getTabindex() => _tabindex;

  /// Gets the validation rules as strings for display.
  List<String> getValidationRules() {
    return _rules.map((r) => r.name).toList();
  }

  /// Validates the given value.
  /// Returns a list of error messages (empty if valid).
  List<String> validate(dynamic value) {
    final errors = <String>[];

    for (final rule in _rules) {
      final error = rule.validate(getName(), value);
      if (error != null) {
        // Use custom message if available
        final customMessage = _validationMessages[rule.name];
        errors.add(customMessage ?? error);
      }
    }

    return errors;
  }

  /// Builds the component for this field.
  Component build(BuildContext context);

  /// Builds common HTML attributes for the input element.
  Map<String, String> buildInputAttributes() {
    final attrs = <String, String>{};

    if (_placeholder != null) attrs['placeholder'] = _placeholder!;
    if (_disabled) attrs['disabled'] = 'true';
    if (_readonly) attrs['readonly'] = 'true';
    if (_autofocus) attrs['autofocus'] = 'true';
    if (_autocomplete != null) attrs['autocomplete'] = _autocomplete!;
    if (_tabindex != null) attrs['tabindex'] = _tabindex.toString();
    if (_required) attrs['required'] = 'true';

    return attrs;
  }

  /// Gets the Tailwind classes for column span.
  String getColumnSpanClasses(int totalColumns) {
    if (isColumnSpanFull() || _columnSpan >= totalColumns) {
      return 'col-span-full';
    }
    return 'col-span-$_columnSpan';
  }
}
