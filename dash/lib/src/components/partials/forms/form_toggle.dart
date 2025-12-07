import 'package:dash_board/src/components/partials/forms/form_styles.dart';
import 'package:jaspr/jaspr.dart';

/// A styled toggle/switch component.
///
/// This component provides a visual toggle switch with optional
/// on/off labels and configurable colors.
///
/// Example:
/// ```dart
/// FormToggle(
///   id: 'active',
///   name: 'active',
///   checked: true,
///   onColor: 'lime',
///   size: FormToggleSize.md,
/// )
/// ```
class FormToggle extends StatelessComponent {
  /// The toggle ID attribute.
  final String? id;

  /// The toggle name attribute.
  final String? name;

  /// The value sent when toggled on.
  final String onValue;

  /// The value sent when toggled off.
  final String offValue;

  /// Whether the toggle is checked/on.
  final bool checked;

  /// The color when on (Tailwind color name).
  final String onColor;

  /// Whether the field is required.
  final bool required;

  /// Whether the field is disabled.
  final bool disabled;

  /// The size of the toggle.
  final FormToggleSize size;

  /// Additional attributes.
  final Map<String, String>? attributes;

  const FormToggle({
    this.id,
    this.name,
    this.onValue = '1',
    this.offValue = '0',
    this.checked = false,
    this.onColor = 'lime',
    this.required = false,
    this.disabled = false,
    this.size = FormToggleSize.md,
    this.attributes,
    super.key,
  });

  @override
  Component build(BuildContext context) {
    final (toggleWidth, toggleHeight, knobSize, translateX) = switch (size) {
      FormToggleSize.sm => FormStyles.toggleSizeSm,
      FormToggleSize.md => FormStyles.toggleSizeMd,
      FormToggleSize.lg => FormStyles.toggleSizeLg,
    };

    final attrs = <String, String>{
      if (required) 'required': 'true',
      if (disabled) 'disabled': 'true',
      'x-model': 'checked',
      'x-bind:checked': 'checked',
      ...?attributes,
    };

    return label(
      classes: FormStyles.toggleContainer,
      attributes: {'x-data': '{checked: ${checked ? 'true' : 'false'}}'},
      [
        // Hidden input for off value (disabled when checkbox is checked)
        input(type: InputType.hidden, name: name, value: offValue, attributes: {'x-bind:disabled': 'checked'}),
        // Hidden checkbox input
        input(
          type: InputType.checkbox,
          id: id,
          name: name,
          value: onValue,
          classes: 'sr-only peer',
          attributes: attrs.isEmpty ? null : attrs,
        ),
        // Toggle background
        div(
          classes:
              '$toggleWidth $toggleHeight ${FormStyles.toggleBackground} peer-checked:bg-$onColor-500 peer-focus:ring-2 peer-focus:ring-$onColor-500/50',
          [],
        ),
        // Toggle knob
        div(classes: '${FormStyles.toggleKnob} $knobSize peer-checked:$translateX', []),
      ],
    );
  }
}

/// Size options for toggle switches.
enum FormToggleSize { sm, md, lg }

/// A complete toggle field with label and helper text.
///
/// Example:
/// ```dart
/// FormToggleField(
///   id: 'notifications',
///   name: 'notifications',
///   labelText: 'Enable notifications',
///   helperText: 'Receive email notifications for updates',
///   onLabel: 'On',
///   offLabel: 'Off',
/// )
/// ```
class FormToggleField extends StatelessComponent {
  /// The toggle ID attribute.
  final String? id;

  /// The toggle name attribute.
  final String? name;

  /// The main label text.
  final String labelText;

  /// Helper text displayed below.
  final String? helperText;

  /// Label shown when toggle is on.
  final String? onLabel;

  /// Label shown when toggle is off.
  final String? offLabel;

  /// The value sent when toggled on.
  final String onValue;

  /// The value sent when toggled off.
  final String offValue;

  /// Whether the toggle is checked/on.
  final bool checked;

  /// The color when on (Tailwind color name).
  final String onColor;

  /// Whether the field is required.
  final bool required;

  /// Whether the field is disabled.
  final bool disabled;

  /// The size of the toggle.
  final FormToggleSize size;

  /// Extra CSS classes for the wrapper.
  final String? extraClasses;

  const FormToggleField({
    required this.labelText,
    this.id,
    this.name,
    this.helperText,
    this.onLabel,
    this.offLabel,
    this.onValue = '1',
    this.offValue = '0',
    this.checked = false,
    this.onColor = 'lime',
    this.required = false,
    this.disabled = false,
    this.size = FormToggleSize.md,
    this.extraClasses,
    super.key,
  });

  @override
  Component build(BuildContext context) {
    return div(classes: FormStyles.wrapperClasses(extraClasses), [
      div(classes: 'flex items-center justify-between', [
        // Label
        if (labelText.isNotEmpty)
          label(attributes: id != null ? {'for': id!} : null, classes: FormStyles.toggleLabel, [
            text(labelText),
            if (required) span(classes: FormStyles.requiredIndicator, [text('*')]),
          ]),

        // Toggle container
        div(classes: 'flex items-center gap-3', [
          // Off label
          if (offLabel != null) span(classes: FormStyles.toggleStateLabel, [text(offLabel!)]),

          // Toggle switch (includes hidden input for off value)
          FormToggle(
            id: id,
            name: name,
            onValue: onValue,
            offValue: offValue,
            checked: checked,
            onColor: onColor,
            required: required,
            disabled: disabled,
            size: size,
          ),

          // On label
          if (onLabel != null) span(classes: FormStyles.toggleStateLabel, [text(onLabel!)]),
        ]),
      ]),

      // Helper text
      if (helperText != null) p(classes: FormStyles.helperText, [text(helperText!)]),
    ]);
  }
}
