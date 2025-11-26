import 'package:dash/src/form/fields/field.dart';
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

  @override
  Component build(BuildContext context) {
    final inputId = getId();
    final attrs = buildInputAttributes();

    final defaultVal = getDefaultValue();
    final isChecked = defaultVal == true || defaultVal == 1 || defaultVal == '1' || defaultVal == _onValue;

    // Size classes
    final (toggleWidth, toggleHeight, knobSize, translateX) = switch (_size) {
      ToggleSize.sm => ('w-8', 'h-4', 'w-3 h-3', 'translate-x-4'),
      ToggleSize.md => ('w-11', 'h-6', 'w-5 h-5', 'translate-x-5'),
      ToggleSize.lg => ('w-14', 'h-7', 'w-6 h-6', 'translate-x-7'),
    };

    return div(classes: 'space-y-2 ${getExtraClasses() ?? ''}'.trim(), [
      div(classes: 'flex items-center justify-between', [
        // Label
        if (getLabel().isNotEmpty)
          label(
            attributes: {'for': inputId},
            classes: 'text-sm font-medium text-gray-300',
            [
              text(getLabel()),
              if (isRequired()) span(classes: 'text-red-500 ml-1', [text('*')]),
            ],
          ),

        // Toggle container
        div(classes: 'flex items-center gap-3', [
          // Off label
          if (_offLabel != null) span(classes: 'text-sm text-gray-400', [text(_offLabel!)]),

          // Toggle switch using Alpine.js for interactivity
          label(
            classes: 'relative inline-flex cursor-pointer',
            attributes: {'x-data': '{checked: $isChecked}'},
            [
              // Hidden checkbox
              input(
                type: InputType.checkbox,
                id: inputId,
                name: getName(),
                value: _onValue,
                classes: 'sr-only peer',
                attributes: {...attrs, if (isChecked) 'checked': '', 'x-model': 'checked'},
              ),
              // Toggle background
              div(
                classes:
                    '$toggleWidth $toggleHeight bg-gray-600 rounded-full peer peer-checked:bg-$_onColor-500 peer-focus:ring-2 peer-focus:ring-$_onColor-500/50 transition-colors duration-200',
                [],
              ),
              // Toggle knob
              div(
                classes:
                    'absolute top-0.5 left-0.5 $knobSize bg-white rounded-full shadow-md transition-transform duration-200 peer-checked:$translateX',
                [],
              ),
            ],
          ),

          // On label
          if (_onLabel != null) span(classes: 'text-sm text-gray-400', [text(_onLabel!)]),
        ]),
      ]),

      // Helper text
      if (getHelperText() != null) p(classes: 'text-sm text-gray-400', [text(getHelperText()!)]),

      // Hidden input for off value
      input(type: InputType.hidden, name: getName(), value: _offValue, attributes: {'x-bind:disabled': 'checked'}),
    ]);
  }
}

/// Toggle size options.
enum ToggleSize { sm, md, lg }
