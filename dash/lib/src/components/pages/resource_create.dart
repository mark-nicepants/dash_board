import 'package:dash/src/components/partials/breadcrumbs.dart';
import 'package:dash/src/components/partials/page_header.dart';
import 'package:dash/src/form/fields/form_renderer.dart';
import 'package:dash/src/form/form_schema.dart';
import 'package:dash/src/model/model.dart';
import 'package:dash/src/resource.dart';
import 'package:jaspr/jaspr.dart';

/// Resource create page that renders the form for creating new records.
///
/// Uses the form schema defined on the resource to render form fields
/// with proper validation and styling.
class ResourceCreate<T extends Model> extends StatelessComponent {
  final Resource<T> resource;

  /// Validation errors from form submission.
  final Map<String, List<String>>? errors;

  /// Old input values (for form repopulation on errors).
  final Map<String, dynamic>? oldInput;

  String get basePath => '/admin/resources/${resource.slug}';

  const ResourceCreate({required this.resource, this.errors, this.oldInput, super.key});

  @override
  Component build(BuildContext context) {
    return div(classes: 'flex flex-col gap-6', [_buildBreadcrumbs(), _buildHeader(), _buildFormCard()]);
  }

  Component _buildBreadcrumbs() {
    return BreadCrumbs(
      items: [
        BreadCrumbItem(label: resource.label, url: basePath),
        const BreadCrumbItem(label: 'Create'),
      ],
    );
  }

  Component _buildHeader() {
    return PageHeader(title: 'Create ${resource.singularLabel}');
  }

  Component _buildFormCard() {
    // Build the form schema for creation
    final formSchema = resource
        .form(FormSchema<T>())
        .operation(FormOperation.create)
        .action('$basePath/store')
        .method(FormSubmitMethod.post)
        .submitLabel('Create ${resource.singularLabel}')
        .cancelLabel('Cancel')
        .showCancelButton();

    // Apply old input if available (repopulate form on validation errors)
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
        p(classes: 'mt-1 text-sm text-gray-400', [
          text('Fill in the details below to create a new ${resource.singularLabel.toLowerCase()}.'),
        ]),
      ]),
      div(classes: 'p-6', [FormRenderer(schema: formSchema, errors: errors)]),
    ]);
  }
}
