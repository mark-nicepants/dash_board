import 'package:dash/src/components/partials/forms/form_components.dart';
import 'package:dash/src/form/fields/field.dart';
import 'package:jaspr/jaspr.dart';

/// A select/dropdown field.
///
/// This field provides a dropdown menu for selecting one or more options.
/// Supports static options, grouped options, and placeholder text.
///
/// Example:
/// ```dart
/// Select.make('country')
///   .label('Country')
///   .options([
///     SelectOption('us', 'United States'),
///     SelectOption('uk', 'United Kingdom'),
///     SelectOption('ca', 'Canada'),
///   ])
///   .placeholder('Select a country')
///   .searchable(),
///
/// Select.make('role')
///   .options(SelectOption.fromMap({
///     'admin': 'Administrator',
///     'editor': 'Editor',
///     'viewer': 'Viewer',
///   }))
///   .required(),
/// ```
class Select extends FormField {
  /// The available options.
  List<SelectOption> _options = [];

  /// Grouped options.
  List<SelectOptionGroup>? _groups;

  /// Whether multiple selection is allowed.
  bool _multiple = false;

  /// Whether the select is searchable.
  bool _searchable = false;

  /// Whether to allow creating new options.
  bool _creatable = false;

  /// Whether to preload relationship options.
  bool _preload = false;

  /// The size (number of visible options without scrolling).
  int? _size;

  /// Placeholder when no option is selected.
  String? _placeholderOption;

  /// Whether to show the native select or a custom dropdown.
  bool _native = true;

  Select(super.name);

  /// Creates a new select field.
  static Select make(String name) {
    return Select(name);
  }

  /// Sets the options from a list.
  Select options(List<SelectOption> options) {
    _options = options;
    return this;
  }

  /// Gets the options.
  List<SelectOption> getOptions() => _options;

  /// Sets options from a simple list of strings (value = label).
  Select optionsFromList(List<String> values) {
    _options = values.map((v) => SelectOption(v, v)).toList();
    return this;
  }

  /// Sets options from a map.
  Select optionsFromMap(Map<String, String> map) {
    _options = map.entries.map((e) => SelectOption(e.key, e.value)).toList();
    return this;
  }

  /// Sets grouped options.
  Select groups(List<SelectOptionGroup> groups) {
    _groups = groups;
    return this;
  }

  /// Gets the groups.
  List<SelectOptionGroup>? getGroups() => _groups;

  /// Enables multiple selection.
  Select multiple([bool multiple = true]) {
    _multiple = multiple;
    return this;
  }

  /// Checks if multiple selection is enabled.
  bool isMultiple() => _multiple;

  /// Makes the select searchable (requires JS).
  Select searchable([bool searchable = true]) {
    _searchable = searchable;
    _native = !searchable; // Non-native for searchable
    return this;
  }

  /// Checks if the select is searchable.
  bool isSearchable() => _searchable;

  /// Allows creating new options (requires JS).
  Select creatable([bool creatable = true]) {
    _creatable = creatable;
    return this;
  }

  /// Checks if creating options is allowed.
  bool isCreatable() => _creatable;

  /// Preloads options (for relationships).
  Select preload([bool preload = true]) {
    _preload = preload;
    return this;
  }

  /// Checks if options should be preloaded.
  bool shouldPreload() => _preload;

  /// Sets the visible size.
  Select size(int size) {
    _size = size;
    return this;
  }

  /// Gets the size.
  int? getSize() => _size;

  /// Sets the placeholder option text.
  Select selectPlaceholder(String placeholder) {
    _placeholderOption = placeholder;
    return this;
  }

  /// Gets the placeholder option.
  String? getSelectPlaceholder() => _placeholderOption ?? getPlaceholder();

  /// Uses native HTML select.
  Select native([bool native = true]) {
    _native = native;
    return this;
  }

  /// Checks if using native select.
  bool isNative() => _native;

  /// Adds in-list validation.
  Select validateInList() {
    final validValues = _options.map((o) => o.value).toList();
    rule(InList(validValues));
    return this;
  }

  @override
  Component build(BuildContext context) {
    final inputId = getId();

    // For now, always render native select
    // Custom searchable dropdown would require Alpine.js integration
    return _buildNativeSelect(inputId);
  }

  Component _buildNativeSelect(String inputId) {
    final defaultVal = getDefaultValue();

    // Convert internal SelectOption to FormSelectOption
    final formOptions = _options
        .map((opt) => FormSelectOption(value: opt.value, label: opt.label, disabled: opt.disabled))
        .toList();

    // Convert internal SelectOptionGroup to FormSelectOptionGroup
    final formGroups = _groups
        ?.map(
          (group) => FormSelectOptionGroup(
            label: group.label,
            options: group.options
                .map((opt) => FormSelectOption(value: opt.value, label: opt.label, disabled: opt.disabled))
                .toList(),
          ),
        )
        .toList();

    return FormFieldWrapper(
      extraClasses: getExtraClasses(),
      children: [
        // Label
        if (!isHidden()) FormLabel(labelText: getLabel(), forId: inputId, required: isRequired(), hint: getHint()),

        // Select
        FormSelect(
          id: inputId,
          name: getName(),
          options: formOptions,
          groups: formGroups,
          selectedValue: defaultVal?.toString(),
          placeholder: getSelectPlaceholder(),
          multiple: _multiple,
          size: _size,
          required: isRequired(),
          disabled: isDisabled(),
          autofocus: shouldAutofocus(),
          tabindex: getTabindex(),
        ),

        // Helper text
        if (getHelperText() != null) FormHelperText(helperText: getHelperText()!),
      ],
    );
  }

  // Remove old _buildOptgroup and _buildOption methods - now using FormSelect
}

/// A single option in a select field.
class SelectOption {
  /// The value sent to the server.
  final String value;

  /// The label displayed to the user.
  final String label;

  /// Whether this option is disabled.
  final bool disabled;

  const SelectOption(this.value, this.label, {this.disabled = false});

  /// Creates options from a map of value -> label.
  static List<SelectOption> fromMap(Map<String, String> map) {
    return map.entries.map((e) => SelectOption(e.key, e.value)).toList();
  }

  /// Creates options from a list of enums.
  static List<SelectOption> fromEnum<T extends Enum>(List<T> values, {String Function(T)? labelBuilder}) {
    return values.map((v) {
      final label = labelBuilder?.call(v) ?? _humanize(v.name);
      return SelectOption(v.name, label);
    }).toList();
  }

  /// Converts camelCase/snake_case to Title Case.
  static String _humanize(String name) {
    return name
        .replaceAllMapped(RegExp(r'[A-Z]'), (m) => ' ${m.group(0)}')
        .replaceAll('_', ' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }
}

/// A group of options in a select field.
class SelectOptionGroup {
  /// The group label.
  final String label;

  /// The options in this group.
  final List<SelectOption> options;

  const SelectOptionGroup({required this.label, required this.options});
}
