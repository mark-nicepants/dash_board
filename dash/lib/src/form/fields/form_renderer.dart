import 'package:dash/src/components/partials/forms/form_components.dart';
import 'package:dash/src/form/fields/field.dart';
import 'package:dash/src/form/form_schema.dart';
import 'package:jaspr/jaspr.dart';

/// Renders a form schema to Jaspr components.
///
/// The [FormRenderer] takes a [FormSchema] and renders all its fields
/// within a form element, including layout, buttons, and error handling.
///
/// Example:
/// ```dart
/// FormRenderer(
///   schema: userForm,
///   action: '/admin/resources/users',
///   errors: validationErrors,
/// )
/// ```
class FormRenderer extends StatelessComponent {
  /// The form schema to render.
  final FormSchema schema;

  /// Validation errors from form submission.
  final Map<String, List<String>>? errors;

  /// Custom CSS classes for the form.
  final String? customClasses;

  /// Whether this is a partial render (no form wrapper).
  final bool partial;

  const FormRenderer({required this.schema, this.errors, this.customClasses, this.partial = false, super.key});

  @override
  Component build(BuildContext context) {
    final content = _buildFormContent(context);

    if (partial) {
      return content;
    }

    final methodAttr = switch (schema.getMethod()) {
      FormSubmitMethod.post => null,
      FormSubmitMethod.put => 'PUT',
      FormSubmitMethod.patch => 'PATCH',
    };

    return form(
      action: schema.getAction(),
      method: FormMethod.post,
      classes: 'space-y-6 ${customClasses ?? ''}'.trim(),
      [
        // Method spoofing for PUT/PATCH
        if (methodAttr != null) input(type: InputType.hidden, name: '_method', value: methodAttr),
        content,
      ],
    );
  }

  Component _buildFormContent(BuildContext context) {
    final columns = schema.getColumns();
    final gap = schema.getGap();

    return div([
      // Form fields grid
      div(classes: 'grid grid-cols-1 ${columns > 1 ? 'md:grid-cols-$columns' : ''} gap-$gap', [
        for (final field in schema.getFields())
          if (!field.isHidden()) _buildFieldWrapper(field, context, columns),
      ]),

      // Form actions
      div(classes: FormStyles.formActions, [
        button(
          type: ButtonType.submit,
          classes: FormStyles.buttonPrimary,
          attributes: schema.isDisabled() ? {'disabled': ''} : null,
          [text(schema.getSubmitLabel())],
        ),

        if (schema.shouldShowCancelButton())
          button(
            type: ButtonType.button,
            classes: FormStyles.buttonSecondary,
            attributes: {'onclick': 'history.back()'},
            [text(schema.getCancelLabel())],
          ),
      ]),
    ]);
  }

  Component _buildFieldWrapper(FormField field, BuildContext context, int totalColumns) {
    final fieldErrors = errors?[field.getName()];
    final spanClasses = field.getColumnSpanClasses(totalColumns);

    return div(classes: spanClasses, [
      field.build(context),
      // Field errors
      if (fieldErrors != null && fieldErrors.isNotEmpty) FormFieldErrors(errors: fieldErrors),
    ]);
  }
}
