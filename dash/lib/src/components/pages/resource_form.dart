import 'package:dash_board/src/components/partials/breadcrumbs.dart';
import 'package:dash_board/src/components/partials/page_scaffold.dart';
import 'package:dash_board/src/form/fields/form_renderer.dart';
import 'package:dash_board/src/form/form_schema.dart';
import 'package:dash_board/src/model/model.dart';
import 'package:dash_board/src/panel/panel_config.dart';
import 'package:dash_board/src/resource.dart';
import 'package:dash_board/src/service_locator.dart';
import 'package:jaspr/jaspr.dart';

/// Resource form page that renders the form for creating or editing records.
///
/// Uses the form schema defined on the resource to render form fields.
/// When [record] is null, renders in create mode. When [record] is provided,
/// renders in edit mode with fields pre-populated from the record.
///
/// The [formSchema] parameter should be a pre-configured FormSchema with:
/// - Fields populated with record data (for edit mode)
/// - Operation, action, and method configured
/// - Form actions set
///
/// This design ensures the schema is prepared once in [Resource.buildEditPage]
/// or [Resource.buildCreatePage] and passed through, avoiding duplicate schema
/// creation which would lose populated field values.
class ResourceForm<T extends Model> extends StatelessComponent {
  final Resource<T> resource;

  /// The record being edited, or null for create mode.
  final T? record;

  /// The pre-configured form schema with fields already populated.
  final FormSchema<T> formSchema;

  /// Validation errors from form submission.
  final Map<String, List<String>>? errors;

  /// Old input values (for form repopulation on errors).
  final Map<String, dynamic>? oldInput;

  String get basePath => '${inject<PanelConfig>().path}/resources/${resource.slug}';

  /// Whether this form is in edit mode (has a record) or create mode.
  bool get isEditMode => record != null;

  const ResourceForm({
    required this.resource,
    required this.formSchema,
    this.record,
    this.errors,
    this.oldInput,
    super.key,
  });

  @override
  Component build(BuildContext context) {
    final titlePrefix = isEditMode ? 'Edit' : 'Create';
    return ResourcePageScaffold(
      title: '$titlePrefix ${resource.singularLabel}',
      breadcrumbs: _buildBreadcrumbs(),
      children: [_buildFormCard()],
    );
  }

  List<BreadCrumbItem> _buildBreadcrumbs() {
    final items = <BreadCrumbItem>[BreadCrumbItem(label: resource.label, url: basePath)];

    if (isEditMode) {
      final recordId = _getRecordId();
      final recordLabel = _getRecordLabel();
      items.add(BreadCrumbItem(label: recordLabel, url: '$basePath/$recordId'));
      items.add(const BreadCrumbItem(label: 'Edit'));
    } else {
      items.add(const BreadCrumbItem(label: 'Create'));
    }

    return items;
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
    // Override field values with old input if available (repopulate form on validation errors)
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
}
