import 'package:dash/src/components/partials/forms/form_components.dart';
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
    rule(Accepted());
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

    final defaultVal = getDefaultValue();
    final isChecked = defaultVal == true || defaultVal == 1 || defaultVal == '1' || defaultVal == _checkedValue;

    return FormFieldWrapper(
      extraClasses: getExtraClasses(),
      children: [
        FormFieldWrapperInline(
          children: [
            // Checkbox
            CheckboxInputContainer(
              child: FormCheckbox(
                id: inputId,
                name: getName(),
                value: _checkedValue,
                checked: isChecked,
                required: isRequired(),
                disabled: isDisabled(),
                tabindex: getTabindex(),
              ),
            ),

            // Label
            InlineFieldLabel(labelText: getLabel(), forId: inputId, required: isRequired() || _mustBeAccepted),
          ],
        ),

        // Helper text
        if (getHelperText() != null) p(classes: '${FormStyles.helperText} ml-7', [text(getHelperText()!)]),

        // Hidden input for unchecked value
        if (_uncheckedValue != null) input(type: InputType.hidden, name: getName(), value: _uncheckedValue),
      ],
    );
  }
}
