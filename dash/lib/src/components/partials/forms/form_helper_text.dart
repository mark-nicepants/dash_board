import 'package:dash_board/src/components/partials/forms/form_styles.dart';
import 'package:jaspr/jaspr.dart';

/// Helper text displayed below a form field.
///
/// Example:
/// ```dart
/// FormHelperText(text: 'Password must be at least 8 characters.')
/// ```
class FormHelperText extends StatelessComponent {
  /// The helper text to display.
  final String helperText;

  /// Custom CSS classes to add.
  final String? customClasses;

  const FormHelperText({required this.helperText, this.customClasses, super.key});

  @override
  Component build(BuildContext context) {
    final classes = customClasses != null ? '${FormStyles.helperText} $customClasses' : FormStyles.helperText;

    return p(classes: classes, [text(helperText)]);
  }
}

/// Character count indicator for text inputs.
///
/// Shows the current length relative to the maximum allowed characters.
///
/// Example:
/// ```dart
/// FormCharacterCount(current: 45, max: 100)
/// // Displays: "45 / 100"
/// ```
class FormCharacterCount extends StatelessComponent {
  /// The current character count (optional, defaults to 0 for static rendering).
  final int current;

  /// The maximum allowed characters.
  final int max;

  /// Whether to align the text to the right.
  final bool alignRight;

  /// Custom CSS classes to add.
  final String? customClasses;

  const FormCharacterCount({
    required this.max,
    this.current = 0,
    this.alignRight = true,
    this.customClasses,
    super.key,
  });

  @override
  Component build(BuildContext context) {
    final baseClasses = alignRight ? FormStyles.characterCountRight : FormStyles.characterCount;
    final classes = customClasses != null ? '$baseClasses $customClasses' : baseClasses;

    return p(classes: classes, [text('$current / $max')]);
  }
}

/// Error messages list for a form field.
///
/// Example:
/// ```dart
/// FormFieldErrors(errors: ['Email is required', 'Invalid format'])
/// ```
class FormFieldErrors extends StatelessComponent {
  /// The list of error messages to display.
  final List<String> errors;

  /// Custom CSS classes to add.
  final String? customClasses;

  const FormFieldErrors({required this.errors, this.customClasses, super.key});

  @override
  Component build(BuildContext context) {
    if (errors.isEmpty) {
      return div([]);
    }

    final classes = customClasses != null ? '${FormStyles.errorList} $customClasses' : FormStyles.errorList;

    return ul(classes: classes, [
      for (final error in errors) li([text(error)]),
    ]);
  }
}

/// A row showing both helper text and character count.
///
/// Example:
/// ```dart
/// FormHelperRow(
///   helperText: 'Enter a description',
///   maxLength: 500,
///   currentLength: 42,
/// )
/// ```
class FormHelperRow extends StatelessComponent {
  /// Optional helper text.
  final String? helperText;

  /// Maximum character length (shows count if provided).
  final int? maxLength;

  /// Current character count.
  final int currentLength;

  const FormHelperRow({this.helperText, this.maxLength, this.currentLength = 0, super.key});

  @override
  Component build(BuildContext context) {
    final hasHelper = helperText != null;
    final hasCount = maxLength != null;

    if (!hasHelper && !hasCount) {
      return div([]);
    }

    return div(classes: 'flex justify-between items-center', [
      if (hasHelper) FormHelperText(helperText: helperText!) else div([]),
      if (hasCount) FormCharacterCount(max: maxLength!, current: currentLength),
    ]);
  }
}
