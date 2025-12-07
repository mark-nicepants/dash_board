import 'package:dash_board/src/service_locator.dart';
import 'package:jaspr/jaspr.dart';

/// Input field component with consistent Tailwind styling.
class Input extends StatelessComponent {
  final String? labelText;
  final InputType type;
  final String? name;
  final String? id;
  final String? value;
  final String? placeholder;
  final bool required;
  final bool disabled;
  final Map<String, String>? attributes;

  const Input({
    this.labelText,
    this.type = InputType.text,
    this.name,
    this.id,
    this.value,
    this.placeholder,
    this.required = false,
    this.disabled = false,
    this.attributes,
    super.key,
  });

  @override
  Component build(BuildContext context) {
    final inputId = id ?? name ?? 'input-$hashCode';
    final primary = panelColors.primary;

    final inputClasses =
        'w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-gray-100 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-$primary-500 focus:border-transparent transition-all disabled:opacity-50 disabled:cursor-not-allowed';

    final inputAttrs = {
      ...?attributes,
      if (placeholder != null) 'placeholder': placeholder!,
      if (required) 'required': 'true',
      if (disabled) 'disabled': 'true',
    };

    final inputElement = input(
      type: type,
      id: inputId,
      name: name,
      value: value,
      classes: inputClasses,
      attributes: inputAttrs.isEmpty ? null : inputAttrs,
    );

    if (labelText != null) {
      return div(classes: 'space-y-2', [
        label(
          attributes: {'for': inputId},
          classes: 'block text-sm font-medium text-gray-300',
          [
            text(labelText!),
            if (required) span(classes: 'text-red-500 ml-1', [text('*')]),
          ],
        ),
        inputElement,
      ]);
    }

    return inputElement;
  }
}

/// Form group container for inputs with labels
class FormGroup extends StatelessComponent {
  final Component child;

  const FormGroup({required this.child, super.key});

  @override
  Component build(BuildContext context) {
    return div(classes: 'mb-5', [child]);
  }
}
