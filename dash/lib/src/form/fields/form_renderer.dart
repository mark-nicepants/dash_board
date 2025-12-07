import 'package:dash_board/src/auth/csrf_protection.dart';
import 'package:dash_board/src/components/partials/forms/form_components.dart';
import 'package:dash_board/src/components/partials/forms/form_section.dart';
import 'package:dash_board/src/context/request_context.dart';
import 'package:dash_board/src/form/fields/field.dart';
import 'package:dash_board/src/form/fields/grid.dart';
import 'package:dash_board/src/form/fields/section.dart';
import 'package:dash_board/src/form/form_schema.dart';
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
    final formState = _buildInitialState();
    final content = _buildFormContent(context, formState);

    if (partial) {
      return content;
    }

    final methodAttr = switch (schema.getMethod()) {
      FormSubmitMethod.post => null,
      FormSubmitMethod.put => 'PUT',
      FormSubmitMethod.patch => 'PATCH',
    };

    return form(action: schema.getAction(), method: FormMethod.post, classes: customClasses, [
      // CSRF token for protection against cross-site request forgery
      _buildCsrfTokenField(),
      // Method spoofing for PUT/PATCH (placed inside content to avoid space-y-6 gap)
      if (methodAttr != null) input(type: InputType.hidden, name: '_method', value: methodAttr),
      content,
    ]);
  }

  /// Builds the hidden CSRF token field.
  ///
  /// Generates a CSRF token bound to the current session ID using
  /// [CsrfProtection.generateToken]. If no session is available,
  /// generates a token with a random fallback ID.
  Component _buildCsrfTokenField() {
    final sessionId = RequestContext.sessionId;
    final token = CsrfProtection.generateToken(sessionId ?? 'no-session');
    return input(type: InputType.hidden, name: CsrfProtection.tokenFieldName, value: token);
  }

  Component _buildFormContent(BuildContext context, Map<String, dynamic> formState) {
    final columns = schema.getColumns();
    final gap = schema.getGap();
    final components = schema.getComponents();
    final isFormDisabled = schema.isDisabled();

    // If form is disabled, disable all fields
    if (isFormDisabled) {
      for (final field in schema.getFields()) {
        field.disabled(true);
      }
    }

    // Check if we have sections, grids or just flat fields
    final hasLayoutComponents = components.any((c) => c is Section || c is Grid);

    if (hasLayoutComponents) {
      // Render sections, grids, and standalone fields
      return div(classes: 'space-y-6', [
        for (final component in components)
          if (component is Section)
            _buildSection(component, context, formState)
          else if (component is Grid)
            _buildGrid(component, context, formState)
          else if (component is FormField && !component.isHidden())
            _buildFieldWrapper(component, context, columns, formState),
        // Form actions
        _buildFormActions(),
      ]);
    }

    return div([
      // Form fields grid
      div(classes: 'grid grid-cols-1 ${columns > 1 ? 'md:grid-cols-$columns' : ''} gap-$gap', [
        for (final component in components)
          if (component is FormField && !component.isHidden())
            _buildFieldWrapper(component, context, columns, formState),
      ]),

      // Form actions
      _buildFormActions(),
    ]);
  }

  Component _buildFormActions() {
    // If custom form actions are set, render them
    if (schema.hasFormActions()) {
      final actions = schema.getFormActions()!;
      return div(classes: FormStyles.formActions, [
        for (final action in actions) action.renderAsFormAction(isDisabled: schema.isDisabled()),
      ]);
    }

    // Default: render standard submit/cancel buttons
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

  Component _buildSection(Section section, BuildContext context, Map<String, dynamic> formState) {
    final sectionColumns = section.getColumns();
    final sectionGap = section.getGap();

    // Build the field grid for this section
    final fieldGrid =
        div(classes: 'grid grid-cols-1 ${sectionColumns > 1 ? 'md:grid-cols-$sectionColumns' : ''} gap-$sectionGap', [
          for (final field in section.getFields())
            if (!field.isHidden()) _buildFieldWrapper(field, context, sectionColumns, formState),
        ]);

    return FormSection(section: section, children: [fieldGrid]);
  }

  /// Builds a Grid layout component.
  Component _buildGrid(Grid grid, BuildContext context, Map<String, dynamic> formState) {
    if (grid.isHidden()) {
      return div([]);
    }

    final gridClasses = grid.getGridClasses();
    final defaultColumns = grid.getDefaultColumns();

    return div(classes: gridClasses, [
      for (final component in grid.getComponents())
        if (component is Section && !component.isHidden())
          _buildSectionInGrid(component, context, defaultColumns, formState)
        else if (component is Grid && !component.isHidden())
          _buildNestedGrid(component, context, defaultColumns, formState)
        else if (component is FormField && !component.isHidden())
          _buildFieldWrapper(component, context, defaultColumns, formState),
    ]);
  }

  /// Builds a section inside a grid, applying column span.
  Component _buildSectionInGrid(
    Section section,
    BuildContext context,
    int totalColumns,
    Map<String, dynamic> formState,
  ) {
    final spanClasses = section.getColumnSpanClasses(totalColumns);
    final sectionColumns = section.getColumns();
    final sectionGap = section.getGap();

    // Build the field grid for this section
    final fieldGrid =
        div(classes: 'grid grid-cols-1 ${sectionColumns > 1 ? 'md:grid-cols-$sectionColumns' : ''} gap-$sectionGap', [
          for (final field in section.getFields())
            if (!field.isHidden()) _buildFieldWrapper(field, context, sectionColumns, formState),
        ]);

    return div(classes: spanClasses, [
      FormSection(section: section, children: [fieldGrid]),
    ]);
  }

  /// Builds a nested grid inside a parent grid, applying column span.
  Component _buildNestedGrid(Grid grid, BuildContext context, int totalColumns, Map<String, dynamic> formState) {
    final spanClasses = grid.getColumnSpanClasses(totalColumns);
    final gridClasses = grid.getGridClasses();
    final defaultColumns = grid.getDefaultColumns();

    return div(classes: spanClasses, [
      div(classes: gridClasses, [
        for (final component in grid.getComponents())
          if (component is Section && !component.isHidden())
            _buildSectionInGrid(component, context, defaultColumns, formState)
          else if (component is Grid && !component.isHidden())
            _buildNestedGrid(component, context, defaultColumns, formState)
          else if (component is FormField && !component.isHidden())
            _buildFieldWrapper(component, context, defaultColumns, formState),
      ]),
    ]);
  }

  Component _buildFieldWrapper(
    FormField field,
    BuildContext context,
    int totalColumns,
    Map<String, dynamic> formState,
  ) {
    final fieldErrors = errors?[field.getName()];
    final spanClasses = field.getColumnSpanClasses(totalColumns);
    final isVisible = field.shouldShow(formState);
    final wrapperAttributes = field.buildWrapperAttributes(isVisible: isVisible);
    final wrapperClasses = isVisible ? spanClasses : '$spanClasses hidden';

    return div(classes: wrapperClasses, attributes: wrapperAttributes, [
      field.build(context),
      // Field errors
      if (fieldErrors != null && fieldErrors.isNotEmpty) FormFieldErrors(errors: fieldErrors),
    ]);
  }

  Map<String, dynamic> _buildInitialState() {
    final state = <String, dynamic>{};
    for (final field in schema.getFields()) {
      state[field.getName()] = field.getDefaultValue();
    }
    return state;
  }
}
