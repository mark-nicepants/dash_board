import 'package:dash/src/auth/auth_service.dart';
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

  // ============================================================
  // Covariant overrides for fluent API
  // ============================================================

  @override
  TextInput id(String id) {
    super.id(id);
    return this;
  }

  @override
  TextInput label(String label) {
    super.label(label);
    return this;
  }

  @override
  TextInput placeholder(String placeholder) {
    super.placeholder(placeholder);
    return this;
  }

  @override
  TextInput helperText(String text) {
    super.helperText(text);
    return this;
  }

  @override
  TextInput hint(String hint) {
    super.hint(hint);
    return this;
  }

  @override
  TextInput defaultValue(dynamic value) {
    super.defaultValue(value);
    return this;
  }

  @override
  TextInput required([bool required = true]) {
    super.required(required);
    return this;
  }

  @override
  TextInput disabled([bool disabled = true]) {
    super.disabled(disabled);
    return this;
  }

  @override
  TextInput readonly([bool readonly = true]) {
    super.readonly(readonly);
    return this;
  }

  @override
  TextInput hidden([bool hidden = true]) {
    super.hidden(hidden);
    return this;
  }

  @override
  TextInput columnSpan(int span) {
    super.columnSpan(span);
    return this;
  }

  @override
  TextInput columnSpanBreakpoint(String breakpoint, int span) {
    super.columnSpanBreakpoint(breakpoint, span);
    return this;
  }

  @override
  TextInput columnSpanFull() {
    super.columnSpanFull();
    return this;
  }

  @override
  TextInput extraClasses(String classes) {
    super.extraClasses(classes);
    return this;
  }

  @override
  TextInput rule(ValidationRule rule) {
    super.rule(rule);
    return this;
  }

  @override
  TextInput rules(List<ValidationRule> rules) {
    super.rules(rules);
    return this;
  }

  @override
  TextInput validationMessage(String rule, String message) {
    super.validationMessage(rule, message);
    return this;
  }

  @override
  TextInput autofocus([bool autofocus = true]) {
    super.autofocus(autofocus);
    return this;
  }

  @override
  TextInput autocomplete(String value) {
    super.autocomplete(value);
    return this;
  }

  @override
  TextInput tabindex(int index) {
    super.tabindex(index);
    return this;
  }

  // ============================================================
  // TextInput-specific methods
  // ============================================================

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
    rule(Email());
    autocomplete('email');
    return this;
  }

  /// Sets the input type to password.
  ///
  /// Automatically hashes the password value using bcrypt when the form is
  /// submitted (dehydration). This ensures passwords are never stored in
  /// plain text.
  TextInput password() {
    _type = InputType.password;
    autocomplete('current-password');
    dehydrate(_hashPassword);
    return this;
  }

  /// Sets the input type to new password (for registration/change password).
  ///
  /// Automatically hashes the password value using bcrypt when the form is
  /// submitted (dehydration). This ensures passwords are never stored in
  /// plain text.
  TextInput newPassword() {
    _type = InputType.password;
    autocomplete('new-password');
    dehydrate(_hashPassword);
    return this;
  }

  /// Hashes a password value if it's not empty and not already hashed.
  dynamic _hashPassword(dynamic value) {
    if (value == null || value is! String || value.isEmpty) {
      return value;
    }
    // Skip if already a bcrypt hash (starts with $2a$, $2b$, or $2y$)
    if (value.startsWith(r'$2a$') || value.startsWith(r'$2b$') || value.startsWith(r'$2y$')) {
      return value;
    }
    return AuthService.hashPassword(value);
  }

  /// Sets the input type to URL and adds URL validation.
  TextInput url() {
    _type = InputType.url;
    rule(Url());
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
    rule(MinLength(length));
    return this;
  }

  /// Gets the minimum length.
  int? getMinLength() => _minLength;

  /// Sets the maximum length.
  TextInput maxLength(int length) {
    _maxLength = length;
    rule(MaxLength(length));
    return this;
  }

  /// Gets the maximum length.
  int? getMaxLength() => _maxLength;

  /// Sets the pattern for validation.
  TextInput pattern(RegExp pattern, {String? message}) {
    _pattern = pattern;
    rule(Pattern(pattern, message: message));
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
    rule(Numeric());
    return this;
  }

  /// Adds integer validation.
  TextInput integer() {
    rule(Integer());
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
