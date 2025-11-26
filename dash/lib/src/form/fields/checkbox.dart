import 'package:dash/src/form/fields/field.dart';
import 'package:jaspr/jaspr.dart';

/// A checkbox field for boolean values.
///
/// This field displays a checkbox with a label for toggling
/// a true/false value.
///
/// Example:
/// ```dart
/// Checkbox.make('terms')
///   .label('I agree to the terms and conditions')
///   .required()
///   .accepted(),
///
/// Checkbox.make('newsletter')
///   .label('Subscribe to newsletter')
///   .defaultValue(true)
///   .inline(),
/// ```
class Checkbox extends FormField {
  /// Whether to display inline (checkbox before label).
  bool _inline = true;

  /// Whether this checkbox must be accepted (checked).
  bool _mustBeAccepted = false;

  /// The value when checked.
  String _checkedValue = '1';

  /// The value when unchecked (for forms that need explicit false).
  String? _uncheckedValue;

  Checkbox(super.name);

  /// Creates a new checkbox field.
  static Checkbox make(String name) {
    return Checkbox(name);
  }

  /// Displays the checkbox inline with the label.
  Checkbox inline([bool inline = true]) {
    _inline = inline;
    return this;
  }

  /// Checks if inline display is enabled.
  bool isInline() => _inline;

  /// Requires the checkbox to be accepted/checked.
  Checkbox accepted() {
    _mustBeAccepted = true;
    rule(AcceptedRule());
    return this;
  }

  /// Checks if acceptance is required.
  bool mustBeAccepted() => _mustBeAccepted;

  /// Sets the value when checked.
  Checkbox checkedValue(String value) {
    _checkedValue = value;
    return this;
  }

  /// Gets the checked value.
  String getCheckedValue() => _checkedValue;

  /// Sets the value when unchecked (for explicit false).
  Checkbox uncheckedValue(String value) {
    _uncheckedValue = value;
    return this;
  }

  /// Gets the unchecked value.
  String? getUncheckedValue() => _uncheckedValue;

  @override
  Component build(BuildContext context) {
    final inputId = getId();
    final attrs = buildInputAttributes();
    attrs['value'] = _checkedValue;

    final defaultVal = getDefaultValue();
    final isChecked = defaultVal == true || defaultVal == 1 || defaultVal == '1' || defaultVal == _checkedValue;
    if (isChecked) attrs['checked'] = '';

    return div(classes: 'space-y-2 ${getExtraClasses() ?? ''}'.trim(), [
      div(classes: 'flex items-start gap-3', [
        // Checkbox
        div(classes: 'flex items-center h-5', [
          input(
            type: InputType.checkbox,
            id: inputId,
            name: getName(),
            classes:
                'w-4 h-4 bg-gray-700 border-gray-600 rounded text-lime-500 focus:ring-2 focus:ring-lime-500 focus:ring-offset-0 cursor-pointer disabled:opacity-50 disabled:cursor-not-allowed',
            attributes: attrs.isEmpty ? null : attrs,
          ),
        ]),

        // Label
        label(
          attributes: {'for': inputId},
          classes: 'text-sm text-gray-300 cursor-pointer select-none',
          [
            text(getLabel()),
            if (isRequired() || _mustBeAccepted) span(classes: 'text-red-500 ml-1', [text('*')]),
          ],
        ),
      ]),

      // Helper text
      if (getHelperText() != null) p(classes: 'text-sm text-gray-400 ml-7', [text(getHelperText()!)]),

      // Hidden input for unchecked value
      if (_uncheckedValue != null) input(type: InputType.hidden, name: getName(), value: _uncheckedValue),
    ]);
  }
}

/// Rule that requires a checkbox to be accepted.
class AcceptedRule extends FieldValidationRule {
  @override
  String get ruleString => 'accepted';

  @override
  String? validate(String field, dynamic value) {
    if (value == true || value == 1 || value == '1' || value == 'on' || value == 'yes') {
      return null;
    }
    return 'The $field must be accepted.';
  }
}
