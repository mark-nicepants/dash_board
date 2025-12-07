import 'package:dash_board/src/components/partials/forms/form_styles.dart';
import 'package:jaspr/jaspr.dart';

/// A form label component with support for required indicator and hint text.
///
/// This component renders a consistent label across all form fields with
/// optional required asterisk and hint text.
///
/// Example:
/// ```dart
/// FormLabel(
///   labelText: 'Email Address',
///   forId: 'email',
///   required: true,
///   hint: 'We will never share your email',
/// )
/// ```
class FormLabel extends StatelessComponent {
  /// The label text to display.
  final String labelText;

  /// The ID of the input this label is for.
  final String? forId;

  /// Whether the field is required (shows asterisk).
  final bool required;

  /// Optional hint text displayed after the label.
  final String? hint;

  /// Custom CSS classes to add to the label.
  final String? customClasses;

  const FormLabel({
    required this.labelText,
    this.forId,
    this.required = false,
    this.hint,
    this.customClasses,
    super.key,
  });

  @override
  Component build(BuildContext context) {
    final classes = customClasses != null ? '${FormStyles.label} $customClasses' : FormStyles.label;

    return label(attributes: forId != null ? {'for': forId!} : null, classes: classes, [
      text(labelText),
      if (required) const RequiredIndicator(),
      if (hint != null) LabelHint(hintText: hint!),
    ]);
  }
}

/// A small red asterisk indicating a required field.
///
/// Example:
/// ```dart
/// span([text('Name'), const RequiredIndicator()])
/// ```
class RequiredIndicator extends StatelessComponent {
  const RequiredIndicator({super.key});

  @override
  Component build(BuildContext context) {
    return span(classes: FormStyles.requiredIndicator, [text('*')]);
  }
}

/// Hint text displayed inline with a label.
///
/// Example:
/// ```dart
/// label([text('Email'), LabelHint(hintText: 'optional')])
/// ```
class LabelHint extends StatelessComponent {
  /// The hint text to display.
  final String hintText;

  const LabelHint({required this.hintText, super.key});

  @override
  Component build(BuildContext context) {
    return span(classes: FormStyles.labelHint, [text('($hintText)')]);
  }
}
