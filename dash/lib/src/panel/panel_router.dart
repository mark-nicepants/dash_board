import 'package:dash/dash.dart';
import 'package:dash/src/utils/resource_loader.dart';
import 'package:jaspr/server.dart';

/// Combines a page component with optional page-specific assets.
class _PageWithAssets {
  final Component page;
  final PageAssetCollector? assets;

  _PageWithAssets(this.page, [this.assets]);
}

/// Handles routing and page rendering for the Dash panel.
///
/// Responsible for matching URL paths to appropriate pages
/// and rendering Jaspr components into HTML responses.
class PanelRouter {
  final PanelConfig _config;
  final ResourceLoader _resourceLoader;

  PanelRouter(this._config, this._resourceLoader);

  /// Creates a DashLayout with all required properties from config.
  /// Optionally wraps with page assets. Gets user info from RequestSession.
  _PageWithAssets _wrapInLayout({required String title, required Component child, PageAssetCollector? pageAssets}) {
    return _PageWithAssets(
      DashLayout(
        basePath: _config.path,
        resources: _config.resources,
        navigationItems: _config.navigationItems,
        renderHooks: _config.renderHooks,
        title: title,
        child: child,
      ),
      pageAssets,
    );
  }

  /// Routes a request to the appropriate page handler.
  Future<Response> route(Request request) async {
    final path = request.url.path;
    final method = request.method;

    // Try Dash internal routes first (admin UI, resources, login, etc.)

    // Handle relationship search API requests
    if (path.startsWith('dash/relationship-search/')) {
      return await _handleRelationshipSearch(request, path);
    }

    // Handle form submissions (POST/PUT/DELETE) for Dash resources
    if (path.startsWith(_config.path.replaceFirst('/', ''))) {
      if (method == 'POST') {
        return await _handleFormSubmission(request, path);
      }

      final result = await _getPageForPath(path, request);
      return await _renderPage(result.page, pageAssets: result.assets);
    } else {
      // If Dash routing fails, try custom routes (plugins)

      // Check for exact match custom routes
      final handler = _config.customRoutes[path];
      if (handler != null) {
        return await handler(request);
      }
    }

    // No matching route found - return 404
    return Response.notFound('Page not found');
  }

  /// Handles form submissions for create, update, delete, and action operations.
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

      // Check for action handler routes: /{id}/actions/{actionName}
      if (path.contains('/actions/')) {
        final actionsIndex = parts.indexOf('actions');
        final actionName = actionsIndex + 1 < parts.length ? parts[actionsIndex + 1] : '';
        final recordId = actionsIndex > 0 ? parts[actionsIndex - 1] : null;

        if (actionName.isNotEmpty) {
          return await _handleAction(
            resource: resource,
            resourceSlug: resourceSlug,
            actionName: actionName,
            recordId: recordId,
            formData: formData,
          );
        }
      }

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
        final wrapped = _wrapInLayout(title: 'Create ${resource.singularLabel}', child: page);
        return await _renderPage(wrapped.page, pageAssets: wrapped.assets);
      }

      // Create the record
      await resource.createRecord(formData);

      // Redirect to index with success message
      final basePath = '${_config.path}/resources/${resource.slug}';
      return Response.found(basePath);
    } catch (e) {
      // Handle error - re-render create page
      final page = resource.buildCreatePage(
        errors: {
          '_error': ['Failed to create record: $e'],
        },
        oldInput: formData,
      );
      final wrapped = _wrapInLayout(title: 'Create ${resource.singularLabel}', child: page);
      return await _renderPage(wrapped.page, pageAssets: wrapped.assets);
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
        final page = await resource.buildEditPage(record: record, errors: errors, oldInput: formData);
        final wrapped = _wrapInLayout(title: 'Edit ${resource.singularLabel}', child: page);
        return await _renderPage(wrapped.page, pageAssets: wrapped.assets);
      }

      // Update the record
      await resource.updateRecord(record, formData);

      // Redirect to index with success message
      final basePath = '${_config.path}/resources/${resource.slug}';
      return Response.found(basePath);
    } catch (e) {
      // Handle error
      final basePath = '${_config.path}/resources/${resource.slug}';
      return Response.found('$basePath/$recordId/edit');
    }
  }

  /// Handles executing an action handler for a specific record.
  ///
  /// This is a fallback for form-based action submissions. For better UX,
  /// actions should use DashWire (wire:click) for XHR-based execution.
  Future<Response> _handleAction({
    required dynamic resource,
    required String resourceSlug,
    required String actionName,
    required String? recordId,
    required Map<String, dynamic> formData,
  }) async {
    try {
      // Look up the handler from the registry
      final handler = ActionHandlerRegistry.getForRoute(resourceSlug, actionName);
      if (handler == null) {
        print('[Router] No handler found for action: $actionName');
        final basePath = '${_config.path}/resources/$resourceSlug';
        return Response.found(basePath);
      }

      // Find the record
      final record = await resource.findRecord(int.tryParse(recordId ?? '') ?? recordId);
      if (record == null) {
        print('[Router] Record not found: $recordId');
        final basePath = '${_config.path}/resources/$resourceSlug';
        return Response.found(basePath);
      }

      // Build the action context
      final context = ActionContext(
        record: record,
        data: formData,
        resourceSlug: resourceSlug,
        actionName: actionName,
        basePath: '${_config.path}/resources/$resourceSlug',
      );

      // Validate if the handler has validation
      final validationError = await handler.validate(context);
      if (validationError != null) {
        print('[Router] Validation error: $validationError');
        final basePath = '${_config.path}/resources/$resourceSlug';
        return Response.found(basePath);
      }

      // Execute hooks and handler
      await handler.beforeHandle(context);
      final result = await handler.handle(context);
      await handler.afterHandle(context, result);

      // Handle redirect
      if (result.redirectUrl != null) {
        return Response.found(result.redirectUrl!);
      }

      // Default redirect to index
      final basePath = '${_config.path}/resources/$resourceSlug';
      return Response.found(basePath);
    } catch (e, stack) {
      print('[Router] Action error: $e');
      print(stack);
      final basePath = '${_config.path}/resources/$resourceSlug';
      return Response.found(basePath);
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
      return Response.found(basePath);
    } catch (e) {
      final basePath = '${_config.path}/resources/${resource.slug}';
      return Response.found(basePath);
    }
  }

  /// Handles relationship search API requests.
  ///
  /// Path format: /dash/relationship-search/{modelSlug}
  Future<Response> _handleRelationshipSearch(Request request, String path) async {
    final handler = RelationshipSearchHandler();

    // Extract model slug from path
    final parts = path.split('/');
    final searchIndex = parts.indexOf('relationship-search');
    if (searchIndex == -1 || searchIndex + 1 >= parts.length) {
      return Response.badRequest(body: 'Invalid relationship search path');
    }
    final modelSlug = parts[searchIndex + 1];

    return handler.handle(request, modelSlug);
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
  /// Handles array fields like `tags[]` by collecting multiple values into a list.
  Future<Map<String, dynamic>> _parseFormData(Request request) async {
    final contentType = request.headers['content-type'] ?? '';
    final body = await request.readAsString();

    if (contentType.contains('application/x-www-form-urlencoded')) {
      return _parseUrlEncodedFormData(body);
    } else if (contentType.contains('application/json')) {
      // Handle JSON data if needed in future
      return {};
    }

    return _parseUrlEncodedFormData(body);
  }

  /// Parses URL-encoded form data, handling array fields.
  Map<String, dynamic> _parseUrlEncodedFormData(String body) {
    final result = <String, dynamic>{};
    final pairs = body.split('&');

    for (final pair in pairs) {
      if (pair.isEmpty) continue;

      final equalIndex = pair.indexOf('=');
      if (equalIndex == -1) continue;

      var key = Uri.decodeQueryComponent(pair.substring(0, equalIndex));
      final value = Uri.decodeQueryComponent(pair.substring(equalIndex + 1));

      // Check for array notation (key[])
      if (key.endsWith('[]')) {
        key = key.substring(0, key.length - 2);

        // Initialize or append to the list
        if (result[key] == null) {
          result[key] = <String>[value];
        } else if (result[key] is List) {
          (result[key] as List).add(value);
        } else {
          // Convert existing value to list and add new value
          result[key] = <String>[result[key].toString(), value];
        }
      } else {
        // Non-array field - just set the value
        result[key] = value;
      }
    }

    return result;
  }

  /// Determines which page component to render based on the path.
  Future<_PageWithAssets> _getPageForPath(String path, Request request) async {
    if (path.contains('login')) {
      return _PageWithAssets(LoginPage(basePath: _config.path));
    }

    // Handle custom pages: /admin/pages/{slug}
    if (path.contains('pages/')) {
      final parts = path.split('/');
      final pagesIndex = parts.indexOf('pages');
      final pageSlug = pagesIndex + 1 < parts.length ? parts[pagesIndex + 1] : '';

      // Find the matching page by slug
      final page = _config.pages.firstWhere(
        (p) => p.slug == pageSlug,
        orElse: () => throw Exception('Page not found: $pageSlug'),
      );

      // Build the page content
      final pageContent = await page.build(request, _config.path);

      // Collect page-specific assets if any
      final pageAssets = page.assets;

      return _wrapInLayout(title: page.title, child: pageContent, pageAssets: pageAssets);
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
        return _wrapInLayout(title: 'Create ${resource.singularLabel}', child: createPage);
      }

      if (action != null && parts.length > resourceIndex + 3 && parts[resourceIndex + 3] == 'edit') {
        // Edit page - action is the record ID
        final recordId = int.tryParse(action) ?? action;
        final record = await resource.findRecord(recordId);

        if (record == null) {
          throw Exception('Record not found: $recordId');
        }

        final editPage = await resource.buildEditPage(record: record);
        return _wrapInLayout(title: 'Edit ${resource.singularLabel}', child: editPage);
      }

      // View page - /resources/{slug}/{id} (when action looks like an ID and no further path segment)
      if (action != null && parts.length == resourceIndex + 3) {
        // Check if action looks like a record ID (numeric or any non-reserved string)
        final recordId = int.tryParse(action) ?? action;
        if (recordId != 'create') {
          final record = await resource.findRecord(recordId);

          if (record != null) {
            final viewPage = resource.buildViewPage(record: record);
            return _wrapInLayout(title: resource.singularLabel, child: viewPage);
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
      return _wrapInLayout(title: resource.label, child: indexPage);
    }

    // Default dashboard page with widgets
    final widgets = _config.widgets;

    // Preload all widget data in parallel
    await Future.wait(widgets.map((w) => w.preload()));

    return _wrapInLayout(
      title: 'Dashboard',
      child: DashboardPage(widgets: widgets, renderHooks: _config.renderHooks),
      pageAssets: PageAssetCollector()..collectFromAll(widgets),
    );
  }

  /// Renders a Jaspr component into a complete HTML response.
  ///
  /// [pageAssets] optionally provides page-specific CSS/JS assets
  /// that will be injected into the template head/body sections.
  Future<Response> _renderPage(Component page, {PageAssetCollector? pageAssets}) async {
    final rendered = await renderComponent(page);

    // Render the template with pre-loaded resources
    final html = _resourceLoader.renderTemplate(
      title: 'DASH Admin',
      body: rendered.body,
      basePath: _config.path,
      pageHeadAssets: pageAssets?.renderHeadAssets() ?? '',
      pageBodyAssets: pageAssets?.renderBodyAssets() ?? '',
    );

    return Response.ok(html, headers: {'content-type': 'text/html; charset=utf-8'});
  }
}
