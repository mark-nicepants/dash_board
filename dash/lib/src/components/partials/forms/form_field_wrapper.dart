import 'package:dash_board/src/components/partials/forms/form_styles.dart';
import 'package:jaspr/jaspr.dart';

/// A wrapper component for form fields with consistent spacing.
///
/// This component wraps form field content with the standard spacing
/// and optional extra classes.
///
/// Example:
/// ```dart
/// FormFieldWrapper(
///   extraClasses: 'col-span-2',
///   children: [
///     FormLabel(labelText: 'Email', forId: 'email'),
///     input(type: InputType.email, id: 'email'),
///   ],
/// )
/// ```
class FormFieldWrapper extends StatelessComponent {
  /// The children components to render inside the wrapper.
  final List<Component> children;

  /// Extra CSS classes to append to the wrapper.
  final String? extraClasses;

  /// Additional HTML attributes for the wrapper.
  final Map<String, String>? attributes;

  const FormFieldWrapper({required this.children, this.extraClasses, this.attributes, super.key});

  @override
  Component build(BuildContext context) {
    return div(classes: FormStyles.wrapperClasses(extraClasses), attributes: attributes, children);
  }
}

/// An inline form field wrapper for checkboxes and toggles.
///
/// This component provides horizontal alignment for fields where
/// the input appears before or alongside the label.
///
/// Example:
/// ```dart
/// FormFieldWrapperInline(
///   children: [
///     input(type: InputType.checkbox),
///     label([text('Accept terms')]),
///   ],
/// )
/// ```
class FormFieldWrapperInline extends StatelessComponent {
  /// The children components to render inside the wrapper.
  final List<Component> children;

  /// Extra CSS classes to append to the wrapper.
  final String? extraClasses;

  const FormFieldWrapperInline({required this.children, this.extraClasses, super.key});

  @override
  Component build(BuildContext context) {
    final classes = extraClasses != null
        ? '${FormStyles.fieldWrapperInline} $extraClasses'
        : FormStyles.fieldWrapperInline;

    return div(classes: classes, children);
  }
}

/// A container for a checkbox input element.
///
/// Ensures proper vertical alignment of the checkbox with the label.
class CheckboxInputContainer extends StatelessComponent {
  /// The checkbox input component.
  final Component child;

  const CheckboxInputContainer({required this.child, super.key});

  @override
  Component build(BuildContext context) {
    return div(classes: FormStyles.checkboxContainer, [child]);
  }
}

/// Label for inline form fields (checkbox, toggle).
///
/// Example:
/// ```dart
/// InlineFieldLabel(
///   labelText: 'I agree to the terms',
///   forId: 'terms',
///   required: true,
/// )
/// ```
class InlineFieldLabel extends StatelessComponent {
  /// The label text to display.
  final String labelText;

  /// The ID of the input this label is for.
  final String? forId;

  /// Whether the field is required (shows asterisk).
  final bool required;

  const InlineFieldLabel({required this.labelText, this.forId, this.required = false, super.key});

  @override
  Component build(BuildContext context) {
    return label(attributes: forId != null ? {'for': forId!} : null, classes: FormStyles.checkboxLabel, [
      text(labelText),
      if (required) span(classes: FormStyles.requiredIndicator, [text('*')]),
    ]);
  }
}
