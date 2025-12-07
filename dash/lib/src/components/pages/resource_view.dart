import 'package:dash_board/src/components/partials/breadcrumbs.dart';
import 'package:dash_board/src/components/partials/page_header.dart';
import 'package:dash_board/src/form/fields/form_renderer.dart';
import 'package:dash_board/src/form/form_schema.dart';
import 'package:dash_board/src/model/model.dart';
import 'package:dash_board/src/panel/panel_config.dart';
import 'package:dash_board/src/resource.dart';
import 'package:dash_board/src/service_locator.dart';
import 'package:jaspr/jaspr.dart';

/// Resource view page that renders a read-only display of a record.
///
/// Uses the form schema defined on the resource in disabled/view mode
/// to display the record's data in a consistent layout.
///
/// The [formSchema] parameter should be a pre-configured FormSchema with:
/// - Fields populated with record data
/// - Operation set to view mode
/// - All fields disabled (read-only)
/// - Form actions set
///
/// This design ensures the schema is prepared once in [Resource.buildViewPage]
/// and passed through, avoiding duplicate schema creation which would lose
/// populated field values.
///
/// Example:
/// ```dart
/// ResourceView<User>(
///   resource: userResource,
///   record: user,
///   formSchema: preparedSchema,
/// )
/// ```
class ResourceView<T extends Model> extends StatelessComponent {
  final Resource<T> resource;

  /// The record being viewed.
  final T record;

  /// The pre-configured form schema with fields already populated.
  final FormSchema<T> formSchema;

  String get basePath => '${inject<PanelConfig>().path}/resources/${resource.slug}';

  const ResourceView({required this.resource, required this.record, required this.formSchema, super.key});

  @override
  Component build(BuildContext context) {
    return div(classes: 'flex flex-col gap-6', [_buildHeader(), _buildViewCard()]);
  }

  Component _buildHeader() {
    final actions = resource.viewHeaderActions();
    final recordId = _getRecordId();
    final recordLabel = _getRecordLabel();

    return PageHeader(
      title: 'View ${resource.singularLabel}',
      breadcrumbs: BreadCrumbs(
        items: [
          BreadCrumbItem(label: resource.label, url: basePath),
          BreadCrumbItem(label: recordLabel, url: '$basePath/$recordId'),
        ],
      ),
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
    return FormRenderer(schema: formSchema);
  }
}
