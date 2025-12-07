import 'dart:convert';

import 'package:dash/dash.dart';
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
        Confirmed,
        DateAfter,
        DateBefore,
        DateBetween;

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

  /// Whether this field should emit change events for interactivity.
  bool _live = true;

  /// Optional visibility condition that controls client-side display.
  VisibilityCondition? _visibilityCondition;

  /// Other fields this field listens to for reactive behaviors.
  final List<String> _listensTo = [];

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

  /// Whether the field allows null/empty values.
  bool _nullable = false;

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

  /// Model instance associated with this field.
  Model? record;

  /// Callback to transform value before saving to the database.
  /// Used to process field values (e.g., hashing passwords, formatting dates).
  dynamic Function(dynamic value)? _dehydrateCallback;

  /// Callback to transform value when loading from the database.
  /// Used to process field values for display (e.g., formatting).
  dynamic Function(dynamic value)? _hydrateCallback;

  FormField(this._name);

  /// Gets the field name.
  String getName() => _name;

  /// Sets the field ID.
  FormField id(String id) {
    _id = id;
    return this;
  }

  /// Gets the field ID.
  String getId() => _id ?? _name;

  /// Sets the label for the field.
  FormField label(String label) {
    _label = label;
    return this;
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

  /// Enables live change broadcasting for this field.
  FormField live([bool live = true]) {
    _live = live;
    return this;
  }

  /// Whether this field should broadcast change events.
  bool isLive() => _live;

  /// Sets the placeholder text.
  FormField placeholder(String placeholder) {
    _placeholder = placeholder;
    return this;
  }

  /// Gets the placeholder.
  String? getPlaceholder() => _placeholder;

  /// Sets the helper text.
  FormField helperText(String text) {
    _helperText = text;
    return this;
  }

  /// Gets the helper text.
  String? getHelperText() => _helperText;

  /// Sets the hint.
  FormField hint(String hint) {
    _hint = hint;
    return this;
  }

  /// Gets the hint.
  String? getHint() => _hint;

  /// Sets the default value.
  FormField defaultValue(dynamic value) {
    _default = value;
    return this;
  }

  /// Gets the default value.
  dynamic getDefaultValue() => _default;

  /// Marks the field as required.
  FormField required([bool required = true]) {
    _required = required;
    if (required && !_rules.any((r) => r is Required)) {
      _rules.add(Required());
    }
    return this;
  }

  /// Checks if the field is required.
  bool isRequired() => _required;

  /// Disables the field.
  FormField disabled([bool disabled = true]) {
    _disabled = disabled;
    return this;
  }

  /// Checks if the field is disabled.
  bool isDisabled() => _disabled;

  /// Makes the field readonly.
  FormField readonly([bool readonly = true]) {
    _readonly = readonly;
    return this;
  }

  /// Checks if the field is readonly.
  bool isReadonly() => _readonly;

  /// Hides the field.
  FormField hidden([bool hidden = true]) {
    _hidden = hidden;
    return this;
  }

  /// Checks if the field is hidden.
  bool isHidden() => _hidden;

  /// Sets a visibility condition that depends on another field's value.
  FormField visibleWhen(
    String field, {
    dynamic equals = true,
    VisibilityComparator comparator = VisibilityComparator.equals,
  }) {
    _visibilityCondition = VisibilityCondition(field: field, comparator: comparator, value: equals);
    if (!_listensTo.contains(field)) {
      _listensTo.add(field);
    }
    return this;
  }

  /// Gets the visibility condition, if any.
  VisibilityCondition? getVisibilityCondition() => _visibilityCondition;

  /// Registers dependencies on other fields for reactive behaviors.
  FormField listensTo(List<String> fields) {
    for (final field in fields) {
      if (!_listensTo.contains(field)) {
        _listensTo.add(field);
      }
    }
    return this;
  }

  /// Gets the list of reactive dependencies.
  List<String> getListensTo() => List.unmodifiable(_listensTo);

  /// Marks the field as nullable (allows empty values).
  /// Nullable fields will not show validation errors for empty values
  /// unless they are also marked as required.
  FormField nullable([bool nullable = true]) {
    _nullable = nullable;
    return this;
  }

  /// Checks if the field is nullable.
  bool isNullable() => _nullable;

  /// Sets the column span.
  FormField columnSpan(int span) {
    _columnSpan = span;
    return this;
  }

  /// Gets the column span.
  int getColumnSpan() => _columnSpan;

  /// Sets column span for a specific breakpoint.
  FormField columnSpanBreakpoint(String breakpoint, int span) {
    _columnSpanBreakpoints[breakpoint] = span;
    return this;
  }

  /// Gets the column span breakpoints.
  Map<String, int> getColumnSpanBreakpoints() => _columnSpanBreakpoints;

  /// Makes this field span all columns.
  FormField columnSpanFull() {
    _columnSpan = -1; // -1 indicates full width
    return this;
  }

  /// Checks if the field spans full width.
  bool isColumnSpanFull() => _columnSpan == -1;

  /// Sets extra CSS classes.
  FormField extraClasses(String classes) {
    _extraClasses = classes;
    return this;
  }

  /// Gets extra CSS classes.
  String? getExtraClasses() => _extraClasses;

  /// Adds a validation rule.
  FormField rule(ValidationRule rule) {
    _rules.add(rule);
    return this;
  }

  /// Adds multiple validation rules.
  FormField rules(List<ValidationRule> rules) {
    _rules.addAll(rules);
    return this;
  }

  /// Sets a custom validation message.
  FormField validationMessage(String rule, String message) {
    _validationMessages[rule] = message;
    return this;
  }

  /// Sets the autofocus.
  FormField autofocus([bool autofocus = true]) {
    _autofocus = autofocus;
    return this;
  }

  /// Checks if the field should autofocus.
  bool shouldAutofocus() => _autofocus;

  /// Sets the autocomplete attribute.
  FormField autocomplete(String value) {
    _autocomplete = value;
    return this;
  }

  /// Gets the autocomplete attribute.
  String? getAutocomplete() => _autocomplete;

  /// Sets the tabindex.
  FormField tabindex(int index) {
    _tabindex = index;
    return this;
  }

  /// Gets the tabindex.
  int? getTabindex() => _tabindex;

  /// Sets a callback to transform the value before saving.
  ///
  /// The dehydrate callback is called when form data is being saved to the
  /// database. Use this to transform or process values before storage.
  ///
  /// Example:
  /// ```dart
  /// TextInput.make('slug')
  ///   .dehydrate((value) => value?.toString().toLowerCase().replaceAll(' ', '-'))
  /// ```
  FormField dehydrate(dynamic Function(dynamic value) callback) {
    _dehydrateCallback = callback;
    return this;
  }

  /// Gets the dehydrate callback.
  dynamic Function(dynamic value)? getDehydrateCallback() => _dehydrateCallback;

  /// Applies the dehydrate transformation to a value.
  /// Returns the original value if no callback is set.
  dynamic dehydrateValue(dynamic value) {
    if (_dehydrateCallback != null) {
      return _dehydrateCallback!(value);
    }
    return value;
  }

  /// Sets a callback to transform the value when loading from the database.
  ///
  /// The hydrate callback is called when loading form data for display.
  /// Use this to format or process values for the UI.
  ///
  /// Example:
  /// ```dart
  /// TextInput.make('price')
  ///   .hydrate((value) => '\$${value?.toStringAsFixed(2)}')
  /// ```
  FormField hydrate(dynamic Function(dynamic value) callback) {
    _hydrateCallback = callback;
    return this;
  }

  /// Gets the hydrate callback.
  dynamic Function(dynamic value)? getHydrateCallback() => _hydrateCallback;

  /// Applies the hydrate transformation to a value.
  /// Returns the original value if no callback is set.
  dynamic hydrateValue(dynamic value) {
    if (_hydrateCallback != null) {
      return _hydrateCallback!(value);
    }
    return value;
  }

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

  /// Evaluates whether this field should be shown based on current form state.
  bool shouldShow(Map<String, dynamic> state) {
    if (_hidden) return false;
    if (_visibilityCondition == null) return true;
    return _visibilityCondition!.evaluate(state);
  }

  /// Builds data attributes for client-side interactivity.
  Map<String, String> buildWrapperAttributes({required bool isVisible}) {
    final attrs = <String, String>{'data-field-name': getName(), 'data-field-live': _live ? 'true' : 'false'};

    if (!isVisible) {
      attrs['data-field-hidden'] = 'true';
    }

    if (_visibilityCondition != null) {
      attrs['data-visible-when'] = jsonEncode(_visibilityCondition!.toJson());
    }

    if (_listensTo.isNotEmpty) {
      attrs['data-field-listens'] = _listensTo.join(',');
    }

    return attrs;
  }
}

/// Supported comparators for client-side visibility conditions.
enum VisibilityComparator { equals, notEquals, inList, notInList, truthy, falsy }

/// A serializable visibility condition for a field.
class VisibilityCondition {
  final String field;
  final VisibilityComparator comparator;
  final dynamic value;
  final List<dynamic>? values;

  VisibilityCondition({required this.field, required this.comparator, this.value, this.values});

  /// Evaluates the condition using the provided state map.
  bool evaluate(Map<String, dynamic> state) {
    final current = _normalize(state[field]);

    switch (comparator) {
      case VisibilityComparator.equals:
        return current == _normalize(value);
      case VisibilityComparator.notEquals:
        return current != _normalize(value);
      case VisibilityComparator.inList:
        return values?.map(_normalize).contains(current) ?? false;
      case VisibilityComparator.notInList:
        return !(values?.map(_normalize).contains(current) ?? false);
      case VisibilityComparator.truthy:
        return _isTruthy(current);
      case VisibilityComparator.falsy:
        return !_isTruthy(current);
    }
  }

  /// Converts this condition to a JSON-friendly map for the frontend.
  Map<String, dynamic> toJson() => {
    'field': field,
    'comparator': comparator.name,
    if (value != null) 'value': value,
    if (values != null) 'values': values,
  };

  static dynamic _normalize(dynamic input) {
    if (input == null) return null;
    // Keep booleans and numbers intact but normalize strings for comparison.
    if (input is String) {
      final lower = input.toLowerCase();
      if (lower == 'true') return true;
      if (lower == 'false') return false;
    }
    return input;
  }

  static bool _isTruthy(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      if (value.isEmpty) return false;
      final lower = value.toLowerCase();
      if (lower == 'false') return false;
      if (lower == '0') return false;
    }
    return true;
  }
}
