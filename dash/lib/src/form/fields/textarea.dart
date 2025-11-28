import 'package:dash/src/components/partials/forms/form_components.dart';
import 'package:dash/src/form/fields/field.dart';
import 'package:jaspr/jaspr.dart';

/// A textarea field for multi-line text input.
///
/// This field is used for longer text content like descriptions,
/// comments, or any multi-line input.
///
/// Example:
/// ```dart
/// Textarea.make('description')
///   .label('Description')
///   .rows(5)
///   .placeholder('Enter a detailed description...')
///   .maxLength(1000)
///   .characterCount(),
///
/// Textarea.make('content')
///   .autoResize()
///   .minRows(3)
///   .maxRows(10),
/// ```
class Textarea extends FormField {
  /// The number of visible rows.
  int _rows = 4;

  /// Minimum number of rows (for auto-resize).
  int? _minRows;

  /// Maximum number of rows (for auto-resize).
  int? _maxRows;

  /// Minimum length validation.
  int? _minLength;

  /// Maximum length validation.
  int? _maxLength;

  /// Whether to auto-resize based on content.
  bool _autoResize = false;

  /// Whether to show a character count.
  bool _showCharacterCount = false;

  /// Whether to resize horizontally.
  TextareaResize _resize = TextareaResize.vertical;

  Textarea(super.name);

  /// Creates a new textarea field.
  static Textarea make(String name) {
    return Textarea(name);
  }

  /// Sets the number of visible rows.
  Textarea rows(int rows) {
    _rows = rows;
    return this;
  }

  /// Gets the number of rows.
  int getRows() => _rows;

  /// Sets the minimum number of rows.
  Textarea minRows(int rows) {
    _minRows = rows;
    return this;
  }

  /// Gets the minimum rows.
  int? getMinRows() => _minRows;

  /// Sets the maximum number of rows.
  Textarea maxRows(int rows) {
    _maxRows = rows;
    return this;
  }

  /// Gets the maximum rows.
  int? getMaxRows() => _maxRows;

  /// Sets the minimum length.
  Textarea minLength(int length) {
    _minLength = length;
    rule(MinLength(length));
    return this;
  }

  /// Gets the minimum length.
  int? getMinLength() => _minLength;

  /// Sets the maximum length.
  Textarea maxLength(int length) {
    _maxLength = length;
    rule(MaxLength(length));
    return this;
  }

  /// Gets the maximum length.
  int? getMaxLength() => _maxLength;

  /// Enables auto-resize based on content.
  Textarea autoResize([bool enable = true]) {
    _autoResize = enable;
    return this;
  }

  /// Checks if auto-resize is enabled.
  bool shouldAutoResize() => _autoResize;

  /// Shows a character count.
  Textarea characterCount([bool show = true]) {
    _showCharacterCount = show;
    return this;
  }

  /// Checks if character count should be shown.
  bool shouldShowCharacterCount() => _showCharacterCount;

  /// Sets the resize behavior.
  Textarea resize(TextareaResize resize) {
    _resize = resize;
    return this;
  }

  /// Gets the resize behavior.
  TextareaResize getResize() => _resize;

  /// Disables resizing.
  Textarea noResize() {
    _resize = TextareaResize.none;
    return this;
  }

  @override
  Component build(BuildContext context) {
    final inputId = getId();

    return FormFieldWrapper(
      extraClasses: getExtraClasses(),
      children: [
        // Label
        if (!isHidden()) FormLabel(labelText: getLabel(), forId: inputId, required: isRequired(), hint: getHint()),

        // Textarea
        FormTextarea(
          id: inputId,
          name: getName(),
          value: getDefaultValue()?.toString(),
          placeholder: getPlaceholder(),
          rows: _rows,
          required: isRequired(),
          disabled: isDisabled(),
          readonly: isReadonly(),
          autofocus: shouldAutofocus(),
          tabindex: getTabindex(),
          maxLength: _maxLength,
          minLength: _minLength,
          resize: _resize,
        ),

        // Helper text and character count row
        if (getHelperText() != null || (_showCharacterCount && _maxLength != null))
          FormHelperRow(helperText: getHelperText(), maxLength: _showCharacterCount ? _maxLength : null),
      ],
    );
  }
}
