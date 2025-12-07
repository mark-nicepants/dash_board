import 'package:dash_board/src/components/partials/forms/form_styles.dart';
import 'package:jaspr/jaspr.dart';

/// A styled text input component.
///
/// Example:
/// ```dart
/// FormInput(
///   type: InputType.email,
///   id: 'email',
///   name: 'email',
///   placeholder: 'you@example.com',
///   required: true,
/// )
/// ```
class FormInput extends StatelessComponent {
  /// The input type.
  final InputType type;

  /// The input ID attribute.
  final String? id;

  /// The input name attribute.
  final String? name;

  /// The current value.
  final String? value;

  /// Placeholder text.
  final String? placeholder;

  /// Whether the field is required.
  final bool required;

  /// Whether the field is disabled.
  final bool disabled;

  /// Whether the field is readonly.
  final bool readonly;

  /// Whether to autofocus.
  final bool autofocus;

  /// Autocomplete attribute value.
  final String? autocomplete;

  /// Tab index for keyboard navigation.
  final int? tabindex;

  /// Maximum length.
  final int? maxLength;

  /// Minimum length.
  final int? minLength;

  /// Validation pattern.
  final String? pattern;

  /// Datalist ID for autocomplete suggestions.
  final String? listId;

  /// Additional attributes.
  final Map<String, String>? attributes;

  /// Whether this input is inside an adornment wrapper.
  final bool hasAdornments;

  /// Custom CSS classes to add.
  final String? customClasses;

  /// Whether the input has an error state.
  final bool hasError;

  const FormInput({
    this.type = InputType.text,
    this.id,
    this.name,
    this.value,
    this.placeholder,
    this.required = false,
    this.disabled = false,
    this.readonly = false,
    this.autofocus = false,
    this.autocomplete,
    this.tabindex,
    this.maxLength,
    this.minLength,
    this.pattern,
    this.listId,
    this.attributes,
    this.hasAdornments = false,
    this.customClasses,
    this.hasError = false,
    super.key,
  });

  @override
  Component build(BuildContext context) {
    final baseClasses = hasAdornments ? FormStyles.inputBaseNoBorder : FormStyles.inputBase;
    final errorClasses = hasError ? ' ${FormStyles.inputError}' : '';
    final extraClasses = customClasses != null ? ' $customClasses' : '';
    final classes = '$baseClasses$errorClasses$extraClasses';

    final attrs = <String, String>{
      if (placeholder != null) 'placeholder': placeholder!,
      if (required) 'required': 'true',
      if (disabled) 'disabled': 'true',
      if (readonly) 'readonly': 'true',
      if (autofocus) 'autofocus': 'true',
      if (autocomplete != null) 'autocomplete': autocomplete!,
      if (tabindex != null) 'tabindex': tabindex.toString(),
      if (maxLength != null) 'maxlength': maxLength.toString(),
      if (minLength != null) 'minlength': minLength.toString(),
      if (pattern != null) 'pattern': pattern!,
      if (listId != null) 'list': listId!,
      ...?attributes,
    };

    return input(
      type: type,
      id: id,
      name: name,
      value: value,
      classes: classes,
      attributes: attrs.isEmpty ? null : attrs,
    );
  }
}

/// A styled textarea component.
///
/// Example:
/// ```dart
/// FormTextarea(
///   id: 'description',
///   name: 'description',
///   rows: 5,
///   placeholder: 'Enter a description...',
/// )
/// ```
class FormTextarea extends StatelessComponent {
  /// The textarea ID attribute.
  final String? id;

  /// The textarea name attribute.
  final String? name;

  /// The initial value/content.
  final String? value;

  /// Placeholder text.
  final String? placeholder;

  /// Number of visible rows.
  final int rows;

  /// Whether the field is required.
  final bool required;

  /// Whether the field is disabled.
  final bool disabled;

  /// Whether the field is readonly.
  final bool readonly;

  /// Whether to autofocus.
  final bool autofocus;

  /// Tab index for keyboard navigation.
  final int? tabindex;

  /// Maximum length.
  final int? maxLength;

  /// Minimum length.
  final int? minLength;

  /// Resize behavior.
  final TextareaResize resize;

  /// Additional attributes.
  final Map<String, String>? attributes;

  /// Custom CSS classes to add.
  final String? customClasses;

  /// Whether the textarea has an error state.
  final bool hasError;

  const FormTextarea({
    this.id,
    this.name,
    this.value,
    this.placeholder,
    this.rows = 4,
    this.required = false,
    this.disabled = false,
    this.readonly = false,
    this.autofocus = false,
    this.tabindex,
    this.maxLength,
    this.minLength,
    this.resize = TextareaResize.vertical,
    this.attributes,
    this.customClasses,
    this.hasError = false,
    super.key,
  });

  @override
  Component build(BuildContext context) {
    final resizeClass = switch (resize) {
      TextareaResize.none => FormStyles.resizeNone,
      TextareaResize.vertical => FormStyles.resizeVertical,
      TextareaResize.horizontal => FormStyles.resizeHorizontal,
      TextareaResize.both => FormStyles.resizeBoth,
    };

    final errorClasses = hasError ? ' ${FormStyles.inputError}' : '';
    final extraClasses = customClasses != null ? ' $customClasses' : '';
    final classes = '${FormStyles.textarea} $resizeClass$errorClasses$extraClasses';

    final attrs = <String, String>{
      'rows': rows.toString(),
      if (placeholder != null) 'placeholder': placeholder!,
      if (required) 'required': 'true',
      if (disabled) 'disabled': 'true',
      if (readonly) 'readonly': 'true',
      if (autofocus) 'autofocus': 'true',
      if (tabindex != null) 'tabindex': tabindex.toString(),
      if (maxLength != null) 'maxlength': maxLength.toString(),
      if (minLength != null) 'minlength': minLength.toString(),
      ...?attributes,
    };

    return textarea(id: id, name: name, classes: classes, attributes: attrs.isEmpty ? null : attrs, [
      if (value != null) text(value!),
    ]);
  }
}

/// Resize behavior for textareas.
enum TextareaResize { none, vertical, horizontal, both }

/// A styled select/dropdown component.
///
/// Example:
/// ```dart
/// FormSelect(
///   id: 'country',
///   name: 'country',
///   options: [
///     FormSelectOption(value: 'us', label: 'United States'),
///     FormSelectOption(value: 'uk', label: 'United Kingdom'),
///   ],
///   placeholder: 'Select a country',
/// )
/// ```
class FormSelect extends StatelessComponent {
  /// The select ID attribute.
  final String? id;

  /// The select name attribute.
  final String? name;

  /// The options to display.
  final List<FormSelectOption> options;

  /// Grouped options (alternative to flat options).
  final List<FormSelectOptionGroup>? groups;

  /// The currently selected value.
  final String? selectedValue;

  /// Placeholder text for the empty option.
  final String? placeholder;

  /// Whether multiple selection is allowed.
  final bool multiple;

  /// Number of visible options.
  final int? size;

  /// Whether the field is required.
  final bool required;

  /// Whether the field is disabled.
  final bool disabled;

  /// Whether to autofocus.
  final bool autofocus;

  /// Tab index for keyboard navigation.
  final int? tabindex;

  /// Additional attributes.
  final Map<String, String>? attributes;

  /// Custom CSS classes to add.
  final String? customClasses;

  /// Whether the select has an error state.
  final bool hasError;

  const FormSelect({
    this.id,
    this.name,
    this.options = const [],
    this.groups,
    this.selectedValue,
    this.placeholder,
    this.multiple = false,
    this.size,
    this.required = false,
    this.disabled = false,
    this.autofocus = false,
    this.tabindex,
    this.attributes,
    this.customClasses,
    this.hasError = false,
    super.key,
  });

  @override
  Component build(BuildContext context) {
    final errorClasses = hasError ? ' ${FormStyles.inputError}' : '';
    final extraClasses = customClasses != null ? ' $customClasses' : '';
    final classes = '${FormStyles.select}$errorClasses$extraClasses';

    final attrs = <String, String>{
      if (multiple) 'multiple': 'true',
      if (size != null) 'size': size.toString(),
      if (required) 'required': 'true',
      if (disabled) 'disabled': 'true',
      if (autofocus) 'autofocus': 'true',
      if (tabindex != null) 'tabindex': tabindex.toString(),
      ...?attributes,
    };

    return select(id: id, name: name, classes: classes, attributes: attrs.isEmpty ? null : attrs, [
      // Placeholder option
      if (placeholder != null)
        option(
          value: '',
          classes: FormStyles.placeholderOption,
          attributes: {'disabled': '', if (selectedValue == null) 'selected': ''},
          [text(placeholder!)],
        ),

      // Grouped options
      if (groups != null)
        for (final group in groups!) _buildOptgroup(group)
      else
        // Flat options
        for (final opt in options) _buildOption(opt),
    ]);
  }

  Component _buildOptgroup(FormSelectOptionGroup group) {
    return optgroup(label: group.label, classes: FormStyles.optgroup, [
      for (final opt in group.options) _buildOption(opt),
    ]);
  }

  Component _buildOption(FormSelectOption opt) {
    final isSelected = selectedValue != null && opt.value == selectedValue;
    final attrs = <String, String>{if (isSelected) 'selected': '', if (opt.disabled) 'disabled': ''};

    return option(value: opt.value, attributes: attrs.isEmpty ? null : attrs, [text(opt.label)]);
  }
}

/// A single option for a select field.
class FormSelectOption {
  /// The value sent to the server.
  final String value;

  /// The label displayed to the user.
  final String label;

  /// Whether this option is disabled.
  final bool disabled;

  const FormSelectOption({required this.value, required this.label, this.disabled = false});

  /// Creates options from a map of value -> label.
  static List<FormSelectOption> fromMap(Map<String, String> map) {
    return map.entries.map((e) => FormSelectOption(value: e.key, label: e.value)).toList();
  }
}

/// A group of options for a select field.
class FormSelectOptionGroup {
  /// The group label.
  final String label;

  /// The options in this group.
  final List<FormSelectOption> options;

  const FormSelectOptionGroup({required this.label, required this.options});
}

/// A styled checkbox input component.
///
/// Example:
/// ```dart
/// FormCheckbox(
///   id: 'terms',
///   name: 'terms',
///   value: '1',
///   checked: true,
/// )
/// ```
class FormCheckbox extends StatelessComponent {
  /// The checkbox ID attribute.
  final String? id;

  /// The checkbox name attribute.
  final String? name;

  /// The value sent when checked.
  final String value;

  /// Whether the checkbox is checked.
  final bool checked;

  /// Whether the field is required.
  final bool required;

  /// Whether the field is disabled.
  final bool disabled;

  /// Tab index for keyboard navigation.
  final int? tabindex;

  /// Additional attributes.
  final Map<String, String>? attributes;

  /// Custom CSS classes to add.
  final String? customClasses;

  const FormCheckbox({
    this.id,
    this.name,
    this.value = '1',
    this.checked = false,
    this.required = false,
    this.disabled = false,
    this.tabindex,
    this.attributes,
    this.customClasses,
    super.key,
  });

  @override
  Component build(BuildContext context) {
    final extraClasses = customClasses != null ? ' $customClasses' : '';
    final classes = '${FormStyles.checkbox}$extraClasses';

    final attrs = <String, String>{
      'value': value,
      if (checked) 'checked': '',
      if (required) 'required': 'true',
      if (disabled) 'disabled': 'true',
      if (tabindex != null) 'tabindex': tabindex.toString(),
      ...?attributes,
    };

    return input(
      type: InputType.checkbox,
      id: id,
      name: name,
      classes: classes,
      attributes: attrs.isEmpty ? null : attrs,
    );
  }
}
