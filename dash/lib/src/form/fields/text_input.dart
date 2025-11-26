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
  TextInputType _type = TextInputType.text;

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
  String? _prefixIcon;

  /// Suffix icon.
  String? _suffixIcon;

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
  TextInput type(TextInputType type) {
    _type = type;
    return this;
  }

  /// Gets the input type.
  TextInputType getType() => _type;

  /// Sets the input type to email and adds email validation.
  TextInput email() {
    _type = TextInputType.email;
    rule(EmailRule());
    autocomplete('email');
    return this;
  }

  /// Sets the input type to password.
  TextInput password() {
    _type = TextInputType.password;
    autocomplete('current-password');
    return this;
  }

  /// Sets the input type to new password (for registration/change password).
  TextInput newPassword() {
    _type = TextInputType.password;
    autocomplete('new-password');
    return this;
  }

  /// Sets the input type to URL and adds URL validation.
  TextInput url() {
    _type = TextInputType.url;
    rule(UrlRule());
    autocomplete('url');
    return this;
  }

  /// Sets the input type to telephone.
  TextInput tel() {
    _type = TextInputType.tel;
    autocomplete('tel');
    return this;
  }

  /// Sets the input type to search.
  TextInput search() {
    _type = TextInputType.search;
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
  TextInput prefixIcon(String icon) {
    _prefixIcon = icon;
    return this;
  }

  /// Gets the prefix icon.
  String? getPrefixIcon() => _prefixIcon;

  /// Sets a suffix icon.
  TextInput suffixIcon(String icon) {
    _suffixIcon = icon;
    return this;
  }

  /// Gets the suffix icon.
  String? getSuffixIcon() => _suffixIcon;

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

    return div(classes: 'space-y-2 ${getExtraClasses() ?? ''}'.trim(), [
      // Label
      if (!isHidden())
        label(
          attributes: {'for': inputId},
          classes: 'block text-sm font-medium text-gray-300',
          [
            text(getLabel()),
            if (isRequired()) span(classes: 'text-red-500 ml-1', [text('*')]),
            if (getHint() != null) span(classes: 'text-gray-500 ml-2 font-normal', [text('(${getHint()})')]),
          ],
        ),

      // Input wrapper (for prefix/suffix)
      if (hasAdornments) _buildInputWithAdornments(inputId) else _buildInput(inputId),

      // Helper text
      if (getHelperText() != null) p(classes: 'text-sm text-gray-400', [text(getHelperText()!)]),

      // Character count
      if (_showCharacterCount && _maxLength != null)
        p(classes: 'text-xs text-gray-500 text-right', [text('0 / $_maxLength')]),

      // Datalist - using raw HTML approach since Jaspr doesn't have datalist
      // The datalist will be rendered as part of the attributes
    ]);
  }

  Component _buildInput(String inputId) {
    final inputType = switch (_type) {
      TextInputType.text => InputType.text,
      TextInputType.email => InputType.email,
      TextInputType.password => InputType.password,
      TextInputType.url => InputType.url,
      TextInputType.tel => InputType.tel,
      TextInputType.search => InputType.search,
    };

    final attrs = buildInputAttributes();
    if (_maxLength != null) attrs['maxlength'] = _maxLength.toString();
    if (_minLength != null) attrs['minlength'] = _minLength.toString();
    if (_pattern != null) attrs['pattern'] = _pattern!.pattern;
    if (_datalist != null) attrs['list'] = '$inputId-list';

    return input(
      type: inputType,
      id: inputId,
      name: getName(),
      value: getDefaultValue()?.toString(),
      classes: _getInputClasses(),
      attributes: attrs.isEmpty ? null : attrs,
    );
  }

  Component _buildInputWithAdornments(String inputId) {
    return div(
      classes:
          'flex rounded-lg overflow-hidden border border-gray-600 focus-within:ring-2 focus-within:ring-lime-500 focus-within:border-transparent',
      [
        // Prefix
        if (_prefix != null)
          span(classes: 'inline-flex items-center px-3 bg-gray-700 text-gray-400 text-sm border-r border-gray-600', [
            text(_prefix!),
          ]),

        // Prefix icon
        if (_prefixIcon != null)
          span(classes: 'inline-flex items-center px-3 bg-gray-700 text-gray-400 border-r border-gray-600', [
            // Icon would go here
            text(_prefixIcon!),
          ]),

        // Input
        div(classes: 'flex-1', [_buildInput(inputId)]),

        // Suffix icon
        if (_suffixIcon != null)
          span(classes: 'inline-flex items-center px-3 bg-gray-700 text-gray-400 border-l border-gray-600', [
            text(_suffixIcon!),
          ]),

        // Suffix
        if (_suffix != null)
          span(classes: 'inline-flex items-center px-3 bg-gray-700 text-gray-400 text-sm border-l border-gray-600', [
            text(_suffix!),
          ]),
      ],
    );
  }

  String _getInputClasses() {
    final hasAdornments = _prefix != null || _suffix != null || _prefixIcon != null || _suffixIcon != null;

    if (hasAdornments) {
      // Simpler classes when inside wrapper
      return 'w-full px-3 py-2 bg-gray-700 text-gray-100 placeholder-gray-400 focus:outline-none disabled:opacity-50 disabled:cursor-not-allowed';
    }

    return 'w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-gray-100 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-lime-500 focus:border-transparent transition-all disabled:opacity-50 disabled:cursor-not-allowed';
  }
}

/// The type of text input.
enum TextInputType { text, email, password, url, tel, search }
