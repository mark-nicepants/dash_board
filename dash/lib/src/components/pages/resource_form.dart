import 'package:dash/src/components/partials/breadcrumbs.dart';
import 'package:dash/src/components/partials/page_header.dart';
import 'package:dash/src/form/fields/form_renderer.dart';
import 'package:dash/src/form/form_schema.dart';
import 'package:dash/src/model/model.dart';
import 'package:dash/src/panel/panel_config.dart';
import 'package:dash/src/resource.dart';
import 'package:dash/src/service_locator.dart';
import 'package:jaspr/jaspr.dart';

/// Resource form page that renders the form for creating or editing records.
///
/// Uses the form schema defined on the resource to render form fields.
/// When [record] is null, renders in create mode. When [record] is provided,
/// renders in edit mode with fields pre-populated from the record.
class ResourceForm<T extends Model> extends StatelessComponent {
  final Resource<T> resource;

  /// The record being edited, or null for create mode.
  final T? record;

  /// Validation errors from form submission.
  final Map<String, List<String>>? errors;

  /// Old input values (for form repopulation on errors).
  final Map<String, dynamic>? oldInput;

  String get basePath => '${inject<PanelConfig>().path}/resources/${resource.slug}';

  /// Whether this form is in edit mode (has a record) or create mode.
  bool get isEditMode => record != null;

  const ResourceForm({required this.resource, this.record, this.errors, this.oldInput, super.key});

  @override
  Component build(BuildContext context) {
    return div(classes: 'flex flex-col gap-6', [_buildBreadcrumbs(), _buildHeader(), _buildFormCard()]);
  }

  Component _buildBreadcrumbs() {
    final items = <BreadCrumbItem>[BreadCrumbItem(label: resource.label, url: basePath)];

    if (isEditMode) {
      final recordId = _getRecordId();
      final recordLabel = _getRecordLabel();
      items.add(BreadCrumbItem(label: recordLabel, url: '$basePath/$recordId'));
      items.add(const BreadCrumbItem(label: 'Edit'));
    } else {
      items.add(const BreadCrumbItem(label: 'Create'));
    }

    return BreadCrumbs(items: items);
  }

  Component _buildHeader() {
    final action = isEditMode ? 'Edit' : 'Create';
    return PageHeader(title: '$action ${resource.singularLabel}');
  }

  /// Gets the record's primary key value.
  dynamic _getRecordId() {
    if (record == null) return null;
    final fields = record!.toMap();
    final primaryKey = record!.primaryKey;
    return fields[primaryKey];
  }

  /// Gets a display label for the record.
  String _getRecordLabel() {
    if (record == null) return '';
    final fields = record!.toMap();
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

    // Build the form schema
    final formSchema = resource.form(FormSchema<T>());

    if (isEditMode) {
      formSchema
          .operation(FormOperation.edit)
          .record(record as T)
          .action('$basePath/$recordId')
          .method(FormSubmitMethod.put);

      // Pre-populate fields with record values
      _populateFieldsFromRecord(formSchema);
    } else {
      formSchema.operation(FormOperation.create).action('$basePath/store').method(FormSubmitMethod.post);
    }

    // Set form actions from resource
    final operation = isEditMode ? FormOperation.edit : FormOperation.create;
    formSchema.formActions(resource.formActions(operation));

    // Override with old input if available (repopulate form on validation errors)
    if (oldInput != null) {
      for (final field in formSchema.getFields()) {
        final name = field.getName();
        if (oldInput!.containsKey(name)) {
          field.defaultValue(oldInput![name]);
        }
      }
    }

    return FormRenderer(schema: formSchema, errors: errors);
  }

  /// Populates form fields with values from the record.
  void _populateFieldsFromRecord(FormSchema<T> formSchema) {
    if (record == null) return;
    final recordData = record!.toMap();

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
