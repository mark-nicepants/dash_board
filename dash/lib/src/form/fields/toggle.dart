import 'package:dash_board/src/components/partials/forms/form_components.dart';
import 'package:dash_board/src/form/fields/field.dart';
import 'package:jaspr/jaspr.dart';

/// A toggle/switch field for boolean values.
///
/// This field displays a stylized switch toggle that provides
/// a more visual boolean input than a standard checkbox.
///
/// Example:
/// ```dart
/// Toggle.make('active')
///   .label('Active')
///   .onLabel('On')
///   .offLabel('Off'),
///
/// Toggle.make('public')
///   .label('Make public')
///   .helperText('When enabled, this will be visible to everyone')
///   .defaultValue(true),
/// ```
class Toggle extends FormField {
  /// Label shown when toggle is on.
  String? _onLabel;

  /// Label shown when toggle is off.
  String? _offLabel;

  /// Color when on (Tailwind color class).
  String _onColor = 'lime';

  /// Color when off (Tailwind color class).
  String _offColor = 'gray';

  /// Size of the toggle.
  ToggleSize _size = ToggleSize.md;

  /// The value when on.
  String _onValue = '1';

  /// The value when off.
  String _offValue = '0';

  Toggle(super.name);

  /// Creates a new toggle field.
  static Toggle make(String name) {
    return Toggle(name);
  }

  // ============================================================
  // Covariant overrides for fluent API
  // ============================================================

  @override
  Toggle id(String id) {
    super.id(id);
    return this;
  }

  @override
  Toggle label(String label) {
    super.label(label);
    return this;
  }

  @override
  Toggle placeholder(String placeholder) {
    super.placeholder(placeholder);
    return this;
  }

  @override
  Toggle helperText(String text) {
    super.helperText(text);
    return this;
  }

  @override
  Toggle hint(String hint) {
    super.hint(hint);
    return this;
  }

  @override
  Toggle defaultValue(dynamic value) {
    super.defaultValue(value);
    return this;
  }

  @override
  Toggle required([bool required = true]) {
    super.required(required);
    return this;
  }

  @override
  Toggle disabled([bool disabled = true]) {
    super.disabled(disabled);
    return this;
  }

  @override
  Toggle readonly([bool readonly = true]) {
    super.readonly(readonly);
    return this;
  }

  @override
  Toggle hidden([bool hidden = true]) {
    super.hidden(hidden);
    return this;
  }

  @override
  Toggle columnSpan(int span) {
    super.columnSpan(span);
    return this;
  }

  @override
  Toggle columnSpanBreakpoint(String breakpoint, int span) {
    super.columnSpanBreakpoint(breakpoint, span);
    return this;
  }

  @override
  Toggle columnSpanFull() {
    super.columnSpanFull();
    return this;
  }

  @override
  Toggle extraClasses(String classes) {
    super.extraClasses(classes);
    return this;
  }

  @override
  Toggle rule(ValidationRule rule) {
    super.rule(rule);
    return this;
  }

  @override
  Toggle rules(List<ValidationRule> rules) {
    super.rules(rules);
    return this;
  }

  @override
  Toggle validationMessage(String rule, String message) {
    super.validationMessage(rule, message);
    return this;
  }

  @override
  Toggle autofocus([bool autofocus = true]) {
    super.autofocus(autofocus);
    return this;
  }

  @override
  Toggle autocomplete(String value) {
    super.autocomplete(value);
    return this;
  }

  @override
  Toggle tabindex(int index) {
    super.tabindex(index);
    return this;
  }

  // ============================================================
  // Toggle-specific methods
  // ============================================================

  /// Sets the label shown when on.
  Toggle onLabel(String label) {
    _onLabel = label;
    return this;
  }

  /// Gets the on label.
  String? getOnLabel() => _onLabel;

  /// Sets the label shown when off.
  Toggle offLabel(String label) {
    _offLabel = label;
    return this;
  }

  /// Gets the off label.
  String? getOffLabel() => _offLabel;

  /// Sets the color when on.
  Toggle onColor(String color) {
    _onColor = color;
    return this;
  }

  /// Gets the on color.
  String getOnColor() => _onColor;

  /// Sets the color when off.
  Toggle offColor(String color) {
    _offColor = color;
    return this;
  }

  /// Gets the off color.
  String getOffColor() => _offColor;

  /// Sets the size.
  Toggle size(ToggleSize size) {
    _size = size;
    return this;
  }

  /// Gets the size.
  ToggleSize getSize() => _size;

  /// Sets the on value.
  Toggle onValue(String value) {
    _onValue = value;
    return this;
  }

  /// Gets the on value.
  String getOnValue() => _onValue;

  /// Sets the off value.
  Toggle offValue(String value) {
    _offValue = value;
    return this;
  }

  /// Gets the off value.
  String getOffValue() => _offValue;

  /// Converts form input to boolean value for database storage.
  @override
  dynamic dehydrateValue(dynamic value) {
    // First apply any custom dehydration callback
    final result = super.dehydrateValue(value);

    // Then convert to boolean
    if (result == null) return false;
    if (result is bool) return result;
    if (result is String) {
      return result == 'true' || result == '1' || result == 'on' || result == _onValue;
    }
    if (result is int) return result == 1;
    return false;
  }

  @override
  Component build(BuildContext context) {
    final inputId = getId();

    final defaultVal = getDefaultValue();
    final isChecked = defaultVal == true || defaultVal == 1 || defaultVal == '1' || defaultVal == _onValue;

    // Map internal size to FormToggleSize
    final toggleSize = switch (_size) {
      ToggleSize.sm => FormToggleSize.sm,
      ToggleSize.md => FormToggleSize.md,
      ToggleSize.lg => FormToggleSize.lg,
    };

    return FormToggleField(
      id: inputId,
      name: getName(),
      labelText: getLabel(),
      helperText: getHelperText(),
      onLabel: _onLabel,
      offLabel: _offLabel,
      onValue: _onValue,
      offValue: _offValue,
      checked: isChecked,
      onColor: _onColor,
      required: isRequired(),
      disabled: isDisabled(),
      size: toggleSize,
      extraClasses: getExtraClasses(),
    );
  }
}

/// Toggle size options.
enum ToggleSize { sm, md, lg }
