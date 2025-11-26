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
      div(classes: 'flex items-center justify-end gap-3 pt-4 border-t border-gray-700', [
        if (schema.shouldShowCancelButton())
          button(
            type: ButtonType.button,
            classes:
                'px-4 py-2 text-sm font-medium text-gray-300 bg-gray-700 hover:bg-gray-600 rounded-lg transition-colors',
            attributes: {'onclick': 'history.back()'},
            [text(schema.getCancelLabel())],
          ),
        button(
          type: ButtonType.submit,
          classes:
              'px-4 py-2 text-sm font-medium text-white bg-lime-500 hover:bg-lime-600 rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed',
          attributes: schema.isDisabled() ? {'disabled': ''} : null,
          [text(schema.getSubmitLabel())],
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
      if (fieldErrors != null && fieldErrors.isNotEmpty)
        ul(classes: 'mt-2 text-sm text-red-400 list-disc list-inside', [
          for (final error in fieldErrors) li([text(error)]),
        ]),
    ]);
  }
}

/// A field group component for organizing fields.
///
/// Example:
/// ```dart
/// FieldGroup(
///   label: 'Personal Information',
///   description: 'Enter your personal details',
///   fields: [
///     TextInput.make('name'),
///     TextInput.make('email'),
///   ],
/// )
/// ```
class FieldGroup extends FormField {
  /// The fields in this group.
  final List<FormField> _groupFields;

  /// Description for the group.
  String? _description;

  /// Number of columns within this group.
  int _groupColumns = 1;

  /// Whether the group is collapsible.
  bool _collapsible = false;

  /// Whether the group starts collapsed.
  bool _collapsed = false;

  FieldGroup(super.name, {required List<FormField> fields}) : _groupFields = fields;

  /// Creates a new field group.
  static FieldGroup make(String name, {required List<FormField> fields}) {
    return FieldGroup(name, fields: fields);
  }

  /// Sets the description.
  FieldGroup description(String description) {
    _description = description;
    return this;
  }

  /// Gets the description.
  String? getDescription() => _description;

  /// Sets the number of columns within the group.
  FieldGroup columns(int columns) {
    _groupColumns = columns;
    return this;
  }

  /// Gets the number of columns.
  int getGroupColumns() => _groupColumns;

  /// Makes the group collapsible.
  FieldGroup collapsible([bool collapsible = true]) {
    _collapsible = collapsible;
    return this;
  }

  /// Checks if collapsible.
  bool isCollapsible() => _collapsible;

  /// Starts the group collapsed.
  FieldGroup collapsed([bool collapsed = true]) {
    _collapsed = collapsed;
    return this;
  }

  /// Checks if starts collapsed.
  bool isCollapsed() => _collapsed;

  /// Gets the fields in this group.
  List<FormField> getGroupFields() => _groupFields;

  @override
  List<String> getValidationRules() {
    // Aggregate rules from all child fields
    return _groupFields.expand((f) => f.getValidationRules()).toList();
  }

  @override
  List<String> validate(dynamic value) {
    // Groups don't validate directly; child fields do
    return [];
  }

  @override
  Component build(BuildContext context) {
    final gap = '4';

    if (_collapsible) {
      return _buildCollapsibleGroup(context, gap);
    }

    return fieldset(classes: 'space-y-4 ${getExtraClasses() ?? ''}'.trim(), [
      // Legend/Header
      if (getLabel().isNotEmpty) legend(classes: 'text-lg font-semibold text-gray-200 mb-2', [text(getLabel())]),
      if (_description != null) p(classes: 'text-sm text-gray-400 mb-4', [text(_description!)]),

      // Fields grid
      div(classes: 'grid grid-cols-1 ${_groupColumns > 1 ? 'md:grid-cols-$_groupColumns' : ''} gap-$gap', [
        for (final field in _groupFields)
          if (!field.isHidden()) div(classes: field.getColumnSpanClasses(_groupColumns), [field.build(context)]),
      ]),
    ]);
  }

  Component _buildCollapsibleGroup(BuildContext context, String gap) {
    return div(
      classes: 'border border-gray-700 rounded-lg overflow-hidden ${getExtraClasses() ?? ''}'.trim(),
      attributes: {'x-data': '{open: ${!_collapsed}}'},
      [
        // Header (clickable)
        button(
          type: ButtonType.button,
          classes: 'w-full flex items-center justify-between px-4 py-3 bg-gray-800 hover:bg-gray-750 transition-colors',
          attributes: {'x-on:click': 'open = !open'},
          [
            div([
              span(classes: 'text-lg font-semibold text-gray-200', [text(getLabel())]),
              if (_description != null) span(classes: 'ml-2 text-sm text-gray-400', [text(_description!)]),
            ]),
            span(
              classes: 'text-gray-400 transition-transform duration-200',
              attributes: {'x-bind:class': "{'rotate-180': open}"},
              [text('▼')],
            ),
          ],
        ),

        // Content
        div(
          classes: 'px-4 py-4 bg-gray-800/50',
          attributes: {'x-show': 'open', 'x-collapse': ''},
          [
            div(classes: 'grid grid-cols-1 ${_groupColumns > 1 ? 'md:grid-cols-$_groupColumns' : ''} gap-$gap', [
              for (final field in _groupFields)
                if (!field.isHidden()) div(classes: field.getColumnSpanClasses(_groupColumns), [field.build(context)]),
            ]),
          ],
        ),
      ],
    );
  }
}
