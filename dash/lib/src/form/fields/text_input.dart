import 'package:dash/src/components/partials/forms/form_components.dart';
import 'package:dash/src/components/partials/heroicon.dart';
import 'package:dash/src/form/fields/field.dart';
import 'package:jaspr/jaspr.dart';

/// A text input field.
///
/// This is the most common field type, used for single-line text input.
/// Supports various input types (text, email, password, url, etc.) and
/// provides convenient methods for common configurations.
///
/// Example:
/// ```dart
/// TextInput.make('name')
///   .label('Full Name')
///   .placeholder('John Doe')
///   .required()
///   .maxLength(100),
///
/// TextInput.make('email')
///   .email()
///   .required(),
///
/// TextInput.make('website')
///   .url()
///   .placeholder('https://example.com'),
/// ```
class TextInput extends FormField {
  /// The input type (text, email, password, url, tel, search).
  InputType _type = InputType.text;

  /// Minimum length validation.
  int? _minLength;

  /// Maximum length validation.
  int? _maxLength;

  /// Pattern for validation.
  RegExp? _pattern;

  /// Prefix text displayed before the input.
  String? _prefix;

  /// Suffix text displayed after the input.
  String? _suffix;

  /// Prefix icon.
  HeroIcons? _prefixIcon;

  /// Suffix icon.
  HeroIcons? _suffixIcon;

  /// Whether to show a character count.
  bool _showCharacterCount = false;

  /// Input mask pattern.
  String? _mask;

  /// Datalist options for autocomplete.
  List<String>? _datalist;

  TextInput(super.name);

  /// Creates a new text input field.
  static TextInput make(String name) {
    return TextInput(name);
  }

  /// Sets the input type.
  TextInput type(InputType type) {
    _type = type;
    return this;
  }

  /// Gets the input type.
  InputType getType() => _type;

  /// Sets the input type to email and adds email validation.
  TextInput email() {
    _type = InputType.email;
    rule(EmailRule());
    autocomplete('email');
    return this;
  }

  /// Sets the input type to password.
  TextInput password() {
    _type = InputType.password;
    autocomplete('current-password');
    return this;
  }

  /// Sets the input type to new password (for registration/change password).
  TextInput newPassword() {
    _type = InputType.password;
    autocomplete('new-password');
    return this;
  }

  /// Sets the input type to URL and adds URL validation.
  TextInput url() {
    _type = InputType.url;
    rule(UrlRule());
    autocomplete('url');
    return this;
  }

  /// Sets the input type to telephone.
  TextInput tel() {
    _type = InputType.tel;
    autocomplete('tel');
    return this;
  }

  /// Sets the input type to search.
  TextInput search() {
    _type = InputType.search;
    return this;
  }

  /// Sets the minimum length.
  TextInput minLength(int length) {
    _minLength = length;
    rule(MinLengthRule(length));
    return this;
  }

  /// Gets the minimum length.
  int? getMinLength() => _minLength;

  /// Sets the maximum length.
  TextInput maxLength(int length) {
    _maxLength = length;
    rule(MaxLengthRule(length));
    return this;
  }

  /// Gets the maximum length.
  int? getMaxLength() => _maxLength;

  /// Sets the pattern for validation.
  TextInput pattern(RegExp pattern, {String? message}) {
    _pattern = pattern;
    rule(RegexRule(pattern, customMessage: message));
    return this;
  }

  /// Gets the pattern.
  RegExp? getPattern() => _pattern;

  /// Sets a prefix text.
  TextInput prefix(String prefix) {
    _prefix = prefix;
    return this;
  }

  /// Gets the prefix.
  String? getPrefix() => _prefix;

  /// Sets a suffix text.
  TextInput suffix(String suffix) {
    _suffix = suffix;
    return this;
  }

  /// Gets the suffix.
  String? getSuffix() => _suffix;

  /// Sets a prefix icon.
  TextInput prefixIcon(HeroIcons icon) {
    _prefixIcon = icon;
    return this;
  }

  /// Gets the prefix icon.
  HeroIcons? getPrefixIcon() => _prefixIcon;

  /// Sets a suffix icon.
  TextInput suffixIcon(HeroIcons icon) {
    _suffixIcon = icon;
    return this;
  }

  /// Gets the suffix icon.
  HeroIcons? getSuffixIcon() => _suffixIcon;

  /// Shows a character count.
  TextInput characterCount([bool show = true]) {
    _showCharacterCount = show;
    return this;
  }

  /// Checks if character count should be shown.
  bool shouldShowCharacterCount() => _showCharacterCount;

  /// Sets an input mask.
  TextInput mask(String mask) {
    _mask = mask;
    return this;
  }

  /// Gets the mask.
  String? getMask() => _mask;

  /// Sets datalist options for autocomplete suggestions.
  TextInput datalist(List<String> options) {
    _datalist = options;
    return this;
  }

  /// Gets the datalist options.
  List<String>? getDatalist() => _datalist;

  /// Adds numeric validation (numbers only).
  TextInput numeric() {
    rule(NumericRule());
    return this;
  }

  /// Adds integer validation.
  TextInput integer() {
    rule(IntegerRule());
    return this;
  }

  @override
  Component build(BuildContext context) {
    final inputId = getId();
    final hasAdornments = _prefix != null || _suffix != null || _prefixIcon != null || _suffixIcon != null;

    return FormFieldWrapper(
      extraClasses: getExtraClasses(),
      children: [
        // Label
        if (!isHidden()) FormLabel(labelText: getLabel(), forId: inputId, required: isRequired(), hint: getHint()),

        // Input wrapper (for prefix/suffix)
        if (hasAdornments) _buildInputWithAdornments(inputId) else _buildInput(inputId),

        // Helper text
        if (getHelperText() != null) FormHelperText(helperText: getHelperText()!),

        // Character count
        if (_showCharacterCount && _maxLength != null) FormCharacterCount(max: _maxLength!, alignRight: true),

        // Datalist - using raw HTML approach since Jaspr doesn't have datalist
        // The datalist will be rendered as part of the attributes
      ],
    );
  }

  Component _buildInput(String inputId) {
    final hasAdornments = _prefix != null || _suffix != null || _prefixIcon != null || _suffixIcon != null;

    return FormInput(
      type: _type,
      id: inputId,
      name: getName(),
      value: getDefaultValue()?.toString(),
      placeholder: getPlaceholder(),
      required: isRequired(),
      disabled: isDisabled(),
      readonly: isReadonly(),
      autofocus: shouldAutofocus(),
      autocomplete: getAutocomplete(),
      tabindex: getTabindex(),
      maxLength: _maxLength,
      minLength: _minLength,
      pattern: _pattern?.pattern,
      listId: _datalist != null ? '$inputId-list' : null,
      hasAdornments: hasAdornments,
    );
  }

  Component _buildInputWithAdornments(String inputId) {
    return InputWithAdornments.build(
      input: _buildInput(inputId),
      prefixText: _prefix,
      suffixText: _suffix,
      prefixIcon: _prefixIcon != null ? Heroicon(_prefixIcon!, size: 20) : null,
      suffixIcon: _suffixIcon != null ? Heroicon(_suffixIcon!, size: 20) : null,
    );
  }

  // _getInputClasses is no longer needed - using FormInput component
}
