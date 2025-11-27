import 'package:dash/src/components/partials/forms/form_components.dart';
import 'package:dash/src/components/partials/forms/form_section.dart';
import 'package:dash/src/form/fields/field.dart';
import 'package:dash/src/form/fields/section.dart';
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
    final components = schema.getComponents();

    // Check if we have sections or just flat fields
    final hasSections = components.any((c) => c is Section);

    if (hasSections) {
      // Render sections and standalone fields
      return div(classes: 'space-y-6', [
        for (final component in components)
          if (component is Section)
            _buildSection(component, context)
          else if (component is FormField && !component.isHidden())
            _buildFieldWrapper(component, context, columns),
        // Form actions
        _buildFormActions(),
      ]);
    }

    return div([
      // Form fields grid
      div(classes: 'grid grid-cols-1 ${columns > 1 ? 'md:grid-cols-$columns' : ''} gap-$gap', [
        for (final component in components)
          if (component is FormField && !component.isHidden()) _buildFieldWrapper(component, context, columns),
      ]),

      // Form actions
      _buildFormActions(),
    ]);
  }

  Component _buildFormActions() {
    return div(classes: FormStyles.formActions, [
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
    ]);
  }

  Component _buildSection(Section section, BuildContext context) {
    final sectionColumns = section.getColumns();
    final sectionGap = section.getGap();

    // Build the field grid for this section
    final fieldGrid = div(
      classes: 'grid grid-cols-1 ${sectionColumns > 1 ? 'md:grid-cols-$sectionColumns' : ''} gap-$sectionGap',
      [
        for (final field in section.getFields())
          if (!field.isHidden()) _buildFieldWrapper(field, context, sectionColumns),
      ],
    );

    return FormSection(section: section, children: [fieldGrid]);
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
