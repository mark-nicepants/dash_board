import 'package:dash/src/components/partials/breadcrumbs.dart';
import 'package:dash/src/components/partials/page_header.dart';
import 'package:dash/src/form/fields/form_renderer.dart';
import 'package:dash/src/form/form_schema.dart';
import 'package:dash/src/model/model.dart';
import 'package:dash/src/panel/panel_config.dart';
import 'package:dash/src/resource.dart';
import 'package:dash/src/service_locator.dart';
import 'package:jaspr/jaspr.dart';

/// Resource view page that renders a read-only display of a record.
///
/// Uses the form schema defined on the resource in disabled/view mode
/// to display the record's data in a consistent layout.
///
/// Example:
/// ```dart
/// ResourceView<User>(
///   resource: userResource,
///   record: user,
/// )
/// ```
class ResourceView<T extends Model> extends StatelessComponent {
  final Resource<T> resource;

  /// The record being viewed.
  final T record;

  String get basePath => '${inject<PanelConfig>().path}/resources/${resource.slug}';

  const ResourceView({required this.resource, required this.record, super.key});

  @override
  Component build(BuildContext context) {
    return div(classes: 'flex flex-col gap-6', [_buildBreadcrumbs(), _buildHeader(), _buildViewCard()]);
  }

  Component _buildBreadcrumbs() {
    final recordId = _getRecordId();
    final recordLabel = _getRecordLabel();

    return BreadCrumbs(
      items: [
        BreadCrumbItem(label: resource.label, url: basePath),
        BreadCrumbItem(label: recordLabel, url: '$basePath/$recordId'),
      ],
    );
  }

  Component _buildHeader() {
    final actions = resource.viewHeaderActions();

    return PageHeader(
      title: 'View ${resource.singularLabel}',
      actions: actions
          .map((action) => action.renderAsHeaderActionWithRecord(record: record, basePath: basePath))
          .toList(),
    );
  }

  /// Gets the record's primary key value.
  dynamic _getRecordId() {
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

  Component _buildViewCard() {
    final recordId = _getRecordId();

    // Build the form schema in view mode
    final formSchema = resource.form(FormSchema<T>());

    formSchema
        .operation(FormOperation.view)
        .record(record)
        .disabled(true) // All fields are disabled in view mode
        .showCancelButton(false); // No cancel button in view mode

    // Pre-populate fields with record values
    _populateFieldsFromRecord(formSchema);

    // Set view-specific form actions (Edit, Back buttons)
    formSchema.formActions(resource.viewFormActions(recordId));

    return FormRenderer(schema: formSchema);
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
