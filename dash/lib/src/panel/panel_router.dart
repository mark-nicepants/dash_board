import 'package:dash/src/components/layout.dart';
import 'package:dash/src/components/pages/dashboard_page.dart';
import 'package:dash/src/components/pages/login_page.dart';
import 'package:dash/src/panel/panel_config.dart';
import 'package:dash/src/utils/resource_loader.dart';
import 'package:jaspr/server.dart';

/// Handles routing and page rendering for the Dash panel.
///
/// Responsible for matching URL paths to appropriate pages
/// and rendering Jaspr components into HTML responses.
class PanelRouter {
  final PanelConfig _config;
  final ResourceLoader _resourceLoader;

  PanelRouter(this._config, this._resourceLoader);

  /// Routes a request to the appropriate page handler.
  Future<Response> route(Request request) async {
    final path = request.url.path;
    final method = request.method;

    // Handle form submissions (POST/PUT/DELETE)
    if (method == 'POST') {
      return await _handleFormSubmission(request, path);
    }

    final page = await _getPageForPath(path, request);
    return await _renderPage(page);
  }

  /// Handles form submissions for create, update, delete operations.
  Future<Response> _handleFormSubmission(Request request, String path) async {
    // Parse form data
    final formData = await _parseFormData(request);
    final method = formData['_method']?.toString().toUpperCase() ?? 'POST';

    if (path.contains('resources/')) {
      final parts = path.split('/');
      final resourceIndex = parts.indexOf('resources');
      final resourceSlug = resourceIndex + 1 < parts.length ? parts[resourceIndex + 1] : '';

      // Find the matching resource by slug
      final resource = _config.resources.firstWhere(
        (r) => r.slug == resourceSlug,
        orElse: () => throw Exception('Resource not found: $resourceSlug'),
      );

      // Determine action: /store (create) or /{id} (update) or /{id}/delete
      if (path.endsWith('/store')) {
        // Create new record
        return await _handleCreate(resource, formData, request);
      } else if (method == 'PUT' || method == 'PATCH') {
        // Update existing record
        final recordId = parts.length > resourceIndex + 2 ? parts[resourceIndex + 2] : null;
        if (recordId != null) {
          return await _handleUpdate(resource, recordId, formData, request);
        }
      } else if (path.endsWith('/delete') || method == 'DELETE') {
        // Delete record
        final recordId = parts.length > resourceIndex + 2 ? parts[resourceIndex + 2] : null;
        if (recordId != null) {
          return await _handleDelete(resource, recordId);
        }
      }
    }

    // Unknown action, redirect back
    return Response.found(_config.path);
  }

  /// Handles creating a new record.
  Future<Response> _handleCreate(dynamic resource, Map<String, dynamic> formData, Request request) async {
    try {
      // Validate the form data
      final errors = await _validateFormData(resource, formData);

      if (errors.isNotEmpty) {
        // Re-render create page with errors
        final page = resource.buildCreatePage(errors: errors, oldInput: formData);
        final wrapped = DashLayout(
          basePath: _config.path,
          resources: _config.resources,
          title: 'Create ${resource.singularLabel}',
          child: page,
        );
        return await _renderPage(wrapped);
      }

      // Create the record
      await resource.createRecord(formData);

      // Redirect to index with success message
      final basePath = '${_config.path}/resources/${resource.slug}';
      return Response.found(basePath, headers: {'HX-Redirect': basePath});
    } catch (e) {
      // Handle error - re-render create page
      final page = resource.buildCreatePage(
        errors: {
          '_error': ['Failed to create record: $e'],
        },
        oldInput: formData,
      );
      final wrapped = DashLayout(
        basePath: _config.path,
        resources: _config.resources,
        title: 'Create ${resource.singularLabel}',
        child: page,
      );
      return await _renderPage(wrapped);
    }
  }

  /// Handles updating an existing record.
  Future<Response> _handleUpdate(
    dynamic resource,
    String recordId,
    Map<String, dynamic> formData,
    Request request,
  ) async {
    try {
      // Find the existing record
      final record = await resource.findRecord(int.tryParse(recordId) ?? recordId);
      if (record == null) {
        return Response.notFound('Record not found');
      }

      // Validate the form data
      final errors = await _validateFormData(resource, formData, existingRecord: record);

      if (errors.isNotEmpty) {
        // Re-render edit page with errors
        final page = resource.buildEditPage(record: record, errors: errors, oldInput: formData);
        final wrapped = DashLayout(
          basePath: _config.path,
          resources: _config.resources,
          title: 'Edit ${resource.singularLabel}',
          child: page,
        );
        return await _renderPage(wrapped);
      }

      // Update the record
      await resource.updateRecord(record, formData);

      // Redirect to index with success message
      final basePath = '${_config.path}/resources/${resource.slug}';
      return Response.found(basePath, headers: {'HX-Redirect': basePath});
    } catch (e) {
      // Handle error
      final basePath = '${_config.path}/resources/${resource.slug}';
      return Response.found('$basePath/$recordId/edit');
    }
  }

  /// Handles deleting a record.
  Future<Response> _handleDelete(dynamic resource, String recordId) async {
    try {
      // Find and delete the record
      final record = await resource.findRecord(int.tryParse(recordId) ?? recordId);
      if (record != null) {
        await resource.deleteRecord(record);
      }

      // Redirect to index
      final basePath = '${_config.path}/resources/${resource.slug}';
      return Response.found(basePath, headers: {'HX-Redirect': basePath});
    } catch (e) {
      final basePath = '${_config.path}/resources/${resource.slug}';
      return Response.found(basePath);
    }
  }

  /// Validates form data against the resource's form schema.
  Future<Map<String, List<String>>> _validateFormData(
    dynamic resource,
    Map<String, dynamic> formData, {
    dynamic existingRecord,
  }) async {
    // Get the form schema
    final formSchema = resource.form(resource.newFormSchema());

    // Validate using the schema
    return formSchema.validate(formData);
  }

  /// Parses form data from the request body.
  Future<Map<String, dynamic>> _parseFormData(Request request) async {
    final contentType = request.headers['content-type'] ?? '';
    final body = await request.readAsString();

    if (contentType.contains('application/x-www-form-urlencoded')) {
      return Uri.splitQueryString(body);
    } else if (contentType.contains('application/json')) {
      // Handle JSON data if needed in future
      return {};
    }

    return Uri.splitQueryString(body);
  }

  /// Determines which page component to render based on the path.
  Future<Component> _getPageForPath(String path, Request request) async {
    if (path.contains('login')) {
      return LoginPage(basePath: _config.path);
    }

    if (path.contains('resources/')) {
      final parts = path.split('/');
      final resourceIndex = parts.indexOf('resources');
      final resourceSlug = resourceIndex + 1 < parts.length ? parts[resourceIndex + 1] : '';

      // Find the matching resource by slug
      final resource = _config.resources.firstWhere(
        (r) => r.slug == resourceSlug,
        orElse: () => throw Exception('Resource not found: $resourceSlug'),
      );

      // Check for create/edit/view routes
      // /resources/{slug}/create - Create new record
      // /resources/{slug}/{id}/edit - Edit existing record
      // /resources/{slug}/{id} - View record (when id is numeric or valid ID)
      // /resources/{slug} - Index page
      final hasMoreParts = parts.length > resourceIndex + 2;
      final action = hasMoreParts ? parts[resourceIndex + 2] : null;

      if (action == 'create') {
        // Create page
        final createPage = resource.buildCreatePage();
        return DashLayout(
          basePath: _config.path,
          resources: _config.resources,
          title: 'Create ${resource.singularLabel}',
          child: createPage,
        );
      }

      if (action != null && parts.length > resourceIndex + 3 && parts[resourceIndex + 3] == 'edit') {
        // Edit page - action is the record ID
        final recordId = int.tryParse(action) ?? action;
        final record = await resource.findRecord(recordId);

        if (record == null) {
          throw Exception('Record not found: $recordId');
        }

        final editPage = resource.buildEditPage(record: record);
        return DashLayout(
          basePath: _config.path,
          resources: _config.resources,
          title: 'Edit ${resource.singularLabel}',
          child: editPage,
        );
      }

      // View page - /resources/{slug}/{id} (when action looks like an ID and no further path segment)
      if (action != null && parts.length == resourceIndex + 3) {
        // Check if action looks like a record ID (numeric or any non-reserved string)
        final recordId = int.tryParse(action) ?? action;
        if (recordId != 'create') {
          final record = await resource.findRecord(recordId);

          if (record != null) {
            final viewPage = resource.buildViewPage(record: record);
            return DashLayout(
              basePath: _config.path,
              resources: _config.resources,
              title: resource.singularLabel,
              child: viewPage,
            );
          }
        }
      }

      // Index page - Extract query parameters for filtering, sorting, pagination
      final queryParams = request.url.queryParameters;
      final searchQuery = queryParams['search'];
      final sortColumn = queryParams['sort'];
      final sortDirection = queryParams['direction'];
      final pageNum = int.tryParse(queryParams['page'] ?? '1') ?? 1;

      // Fetch records and total count
      final records = await resource.getRecords(
        searchQuery: searchQuery,
        sortColumn: sortColumn,
        sortDirection: sortDirection,
        page: pageNum,
      );
      final totalRecords = await resource.getRecordsCount(searchQuery: searchQuery);

      // Build the index page with current state
      final indexPage = resource.buildIndexPage(
        records: records,
        totalRecords: totalRecords,
        searchQuery: searchQuery,
        sortColumn: sortColumn,
        sortDirection: sortDirection,
        currentPage: pageNum,
      );
      return DashLayout(basePath: _config.path, resources: _config.resources, title: resource.label, child: indexPage);
    }

    // Default dashboard page
    return DashLayout(
      basePath: _config.path,
      resources: _config.resources,
      title: 'Dashboard',
      child: const DashboardPage(),
    );
  }

  /// Renders a Jaspr component into a complete HTML response.
  Future<Response> _renderPage(Component page) async {
    final rendered = await renderComponent(page);

    // Render the template with pre-loaded resources
    final html = _resourceLoader.renderTemplate(title: 'DASH Admin', body: rendered.body);

    return Response.ok(html, headers: {'content-type': 'text/html; charset=utf-8'});
  }
}
