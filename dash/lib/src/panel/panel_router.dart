import 'package:jaspr/server.dart';

import '../components/layout.dart';
import '../components/pages/dashboard_page.dart';
import '../components/pages/login_page.dart';
import '../components/styles.dart';
import 'panel_config.dart';

/// Handles routing and page rendering for the Dash panel.
///
/// Responsible for matching URL paths to appropriate pages
/// and rendering Jaspr components into HTML responses.
class PanelRouter {
  final PanelConfig _config;

  PanelRouter(this._config);

  /// Routes a request to the appropriate page handler.
  Future<Response> route(Request request) async {
    final path = request.url.path;
    final page = await _getPageForPath(path, request);
    return await _renderPage(page);
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

      // Extract query parameters for filtering, sorting, pagination
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
    final html =
        '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>DASH Admin</title>
  <style>$dashStyles</style>
  <script src="https://unpkg.com/htmx.org@1.9.10"></script>
  <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.14.1/dist/cdn.min.js"></script>
  <script>
    (function() {
      const STORAGE_PREFIX = 'dash:columns:';
      const stateRegistry = window.DashColumnToggleStates = window.DashColumnToggleStates || {};

      function storageKey(slug) {
        return STORAGE_PREFIX + slug;
      }

      function loadState(slug, defaults) {
        try {
          const raw = window.localStorage.getItem(storageKey(slug));
          if (raw) {
            const parsed = JSON.parse(raw);
            return { ...defaults, ...parsed };
          }
        } catch (_) {
          // Ignore storage issues (private browsing, etc.)
        }
        return { ...defaults };
      }

      function saveState(slug, state) {
        try {
          window.localStorage.setItem(storageKey(slug), JSON.stringify(state));
        } catch (_) {
          // Ignore persistence failures and keep state in memory
        }
      }

      function applyState(slug, state) {
        const container = document.querySelector('[data-table-container="true"][data-resource-slug="' + slug + '"]');
        if (!container) {
          return;
        }
        Object.keys(state).forEach((column) => {
          const isVisible = state[column] ?? true;
          container.querySelectorAll('[data-column="' + column + '"]').forEach((el) => {
            el.classList.toggle('column-hidden', !isVisible);
          });
        });
      }

      window.DashColumnToggle = {
        load: loadState,
        save: saveState,
        apply: applyState,
      };

      document.addEventListener('alpine:init', () => {
        Alpine.data('columnVisibility', (slug, defaults) => ({
          open: false,
          slug,
          defaults,
          state: {},
          init() {
            this.state = window.DashColumnToggle.load(slug, defaults);
            stateRegistry[slug] = this.state;
            this.apply();
          },
          isVisible(column) {
            return this.state[column] ?? true;
          },
          toggle(column) {
            this.state[column] = !this.isVisible(column);
            this.persist();
          },
          showAll() {
            Object.keys(this.defaults).forEach((col) => {
              this.state[col] = true;
            });
            this.persist();
          },
          hideAll() {
            Object.keys(this.defaults).forEach((col) => {
              this.state[col] = false;
            });
            this.persist();
          },
          reset() {
            this.state = { ...this.defaults };
            this.persist();
          },
          persist() {
            stateRegistry[this.slug] = this.state;
            window.DashColumnToggle.save(this.slug, this.state);
            this.apply();
          },
          apply() {
            window.DashColumnToggle.apply(this.slug, this.state);
          },
        }));
      });

      document.addEventListener('htmx:afterSwap', (event) => {
        const target = event.target;
        if (window.Alpine && target instanceof Element) {
          window.Alpine.initTree(target);
        }
        if (!(target instanceof Element)) {
          return;
        }
        const slug = target.getAttribute('data-resource-slug');
        if (slug && stateRegistry[slug]) {
          window.DashColumnToggle.apply(slug, stateRegistry[slug]);
        }
      });
    })();
  </script>
</head>
<body>
  ${rendered.body}
</body>
</html>
''';

    return Response.ok(html, headers: {'content-type': 'text/html; charset=utf-8'});
  }
}
