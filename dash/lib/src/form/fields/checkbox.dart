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

  // ============================================================
  // Covariant overrides for fluent API
  // ============================================================

  @override
  Checkbox id(String id) {
    super.id(id);
    return this;
  }

  @override
  Checkbox label(String label) {
    super.label(label);
    return this;
  }

  @override
  Checkbox placeholder(String placeholder) {
    super.placeholder(placeholder);
    return this;
  }

  @override
  Checkbox helperText(String text) {
    super.helperText(text);
    return this;
  }

  @override
  Checkbox hint(String hint) {
    super.hint(hint);
    return this;
  }

  @override
  Checkbox defaultValue(dynamic value) {
    super.defaultValue(value);
    return this;
  }

  @override
  Checkbox required([bool required = true]) {
    super.required(required);
    return this;
  }

  @override
  Checkbox disabled([bool disabled = true]) {
    super.disabled(disabled);
    return this;
  }

  @override
  Checkbox readonly([bool readonly = true]) {
    super.readonly(readonly);
    return this;
  }

  @override
  Checkbox hidden([bool hidden = true]) {
    super.hidden(hidden);
    return this;
  }

  @override
  Checkbox columnSpan(int span) {
    super.columnSpan(span);
    return this;
  }

  @override
  Checkbox columnSpanBreakpoint(String breakpoint, int span) {
    super.columnSpanBreakpoint(breakpoint, span);
    return this;
  }

  @override
  Checkbox columnSpanFull() {
    super.columnSpanFull();
    return this;
  }

  @override
  Checkbox extraClasses(String classes) {
    super.extraClasses(classes);
    return this;
  }

  @override
  Checkbox rule(ValidationRule rule) {
    super.rule(rule);
    return this;
  }

  @override
  Checkbox rules(List<ValidationRule> rules) {
    super.rules(rules);
    return this;
  }

  @override
  Checkbox validationMessage(String rule, String message) {
    super.validationMessage(rule, message);
    return this;
  }

  @override
  Checkbox autofocus([bool autofocus = true]) {
    super.autofocus(autofocus);
    return this;
  }

  @override
  Checkbox autocomplete(String value) {
    super.autocomplete(value);
    return this;
  }

  @override
  Checkbox tabindex(int index) {
    super.tabindex(index);
    return this;
  }

  // ============================================================
  // Checkbox-specific methods
  // ============================================================

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
      attributes: _uncheckedValue != null ? {'x-data': '{checked: $isChecked}'} : null,
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
                attributes: _uncheckedValue != null ? {'x-model': 'checked'} : null,
              ),
            ),

            // Label
            InlineFieldLabel(labelText: getLabel(), forId: inputId, required: isRequired() || _mustBeAccepted),
          ],
        ),

        // Helper text
        if (getHelperText() != null) p(classes: '${FormStyles.helperText} ml-7', [text(getHelperText()!)]),

        // Hidden input for unchecked value (disabled when checkbox is checked)
        if (_uncheckedValue != null)
          input(
            type: InputType.hidden,
            name: getName(),
            value: _uncheckedValue,
            attributes: {'x-bind:disabled': 'checked'},
          ),
      ],
    );
  }
}
