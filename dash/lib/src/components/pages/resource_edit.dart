import 'package:dash/src/components/partials/breadcrumbs.dart';
import 'package:dash/src/components/partials/page_header.dart';
import 'package:dash/src/form/fields/form_renderer.dart';
import 'package:dash/src/form/form_schema.dart';
import 'package:dash/src/model/model.dart';
import 'package:dash/src/resource.dart';
import 'package:jaspr/jaspr.dart';

/// Resource edit page that renders the form for editing existing records.
///
/// Uses the form schema defined on the resource to render form fields
/// pre-populated with the record's current values.
class ResourceEdit<T extends Model> extends StatelessComponent {
  final Resource<T> resource;

  /// The record being edited.
  final T record;

  /// Validation errors from form submission.
  final Map<String, List<String>>? errors;

  /// Old input values (for form repopulation on errors).
  final Map<String, dynamic>? oldInput;

  String get basePath => '/admin/resources/${resource.slug}';

  const ResourceEdit({required this.resource, required this.record, this.errors, this.oldInput, super.key});

  @override
  Component build(BuildContext context) {
    return div(classes: 'flex flex-col gap-6', [_buildBreadcrumbs(), _buildHeader(), _buildFormCard()]);
  }

  Component _buildBreadcrumbs() {
    final recordId = _getRecordId();
    final recordLabel = _getRecordLabel();

    return BreadCrumbs(
      items: [
        BreadCrumbItem(label: resource.label, url: basePath),
        BreadCrumbItem(label: recordLabel, url: '$basePath/$recordId'),
        const BreadCrumbItem(label: 'Edit'),
      ],
    );
  }

  Component _buildHeader() {
    return PageHeader(title: 'Edit ${resource.singularLabel}');
  }

  /// Gets the record's primary key value.
  dynamic _getRecordId() {
    // Use the model's primaryKey field to get the ID
    final fields = record.toMap();
    final primaryKey = record.primaryKey;
    return fields[primaryKey];
  }

  /// Gets a display label for the record.
  String _getRecordLabel() {
    final fields = record.toMap();
    // Try common name fields first
    final nameFields = ['name', 'title', 'label', 'email', 'username'];
    for (final field in nameFields) {
      if (fields.containsKey(field) && fields[field] != null) {
        return fields[field].toString();
      }
    }
    // Fall back to ID
    return '#${_getRecordId()}';
  }

  Component _buildFormCard() {
    final recordId = _getRecordId();

    // Build the form schema for editing
    final formSchema = resource
        .form(FormSchema<T>())
        .operation(FormOperation.edit)
        .record(record)
        .action('$basePath/$recordId')
        .method(FormSubmitMethod.put)
        .submitLabel('Save Changes')
        .cancelLabel('Cancel')
        .showCancelButton();

    // Pre-populate fields with record values
    _populateFieldsFromRecord(formSchema);

    // Override with old input if available (repopulate form on validation errors)
    if (oldInput != null) {
      for (final field in formSchema.getFields()) {
        final name = field.getName();
        if (oldInput!.containsKey(name)) {
          field.defaultValue(oldInput![name]);
        }
      }
    }

    return div(classes: 'bg-gray-800 rounded-xl border border-gray-700 overflow-hidden', [
      div(classes: 'px-6 py-4 border-b border-gray-700', [
        h3(classes: 'text-lg font-semibold text-gray-200', [text('${resource.singularLabel} Details')]),
        p(classes: 'mt-1 text-sm text-gray-400', [text('Update the details below.')]),
      ]),
      div(classes: 'p-6', [FormRenderer(schema: formSchema, errors: errors)]),
    ]);
  }

  /// Populates form fields with values from the record.
  void _populateFieldsFromRecord(FormSchema<T> formSchema) {
    final recordData = record.toMap();

    for (final field in formSchema.getFields()) {
      final name = field.getName();
      if (recordData.containsKey(name)) {
        final value = recordData[name];
        if (value != null) {
          field.defaultValue(value);
        }
      }
    }
  }
}
