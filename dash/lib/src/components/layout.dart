import 'package:dash/src/components/partials/heroicon.dart';
import 'package:dash/src/resource.dart';
import 'package:jaspr/jaspr.dart';

/// Base layout component for authenticated pages in the admin panel.
///
/// Provides the standard admin layout with:
/// - Sidebar navigation
/// - Top header with user menu
/// - Main content area
class DashLayout extends StatelessComponent {
  final Component child;
  final String title;
  final String basePath;
  final List<Resource> resources;

  const DashLayout({
    required this.child,
    required this.title,
    required this.basePath,
    required this.resources,
    super.key,
  });

  @override
  Component build(BuildContext context) {
    return div(classes: 'flex min-h-screen bg-gray-900', [
      // Sidebar
      aside(classes: 'w-64 bg-gray-800 text-white flex flex-col', [
        div(classes: 'p-6 border-b border-gray-700', [
          h2(classes: 'text-2xl font-bold text-indigo-500', [text('DASH')]),
        ]),
        nav(classes: 'flex-1 py-6', [
          ul(classes: 'space-y-1', [
            li([
              a(
                href: basePath,
                classes:
                    'flex items-center gap-3 px-6 py-3 text-gray-300 hover:bg-gray-700 hover:text-white transition-colors',
                [
                  const Heroicon(HeroIcons.home),
                  span([text('Dashboard')]),
                ],
              ),
            ]),
            // Dynamically generate grouped resource navigation
            ..._buildGroupedNavigation(),
          ]),
        ]),
        // Logout button
        div(classes: 'p-6 border-t border-gray-700', [
          a(
            href: '$basePath/logout',
            classes:
                'flex items-center justify-center gap-2 px-4 py-2.5 text-gray-300 border border-gray-700 rounded-lg hover:bg-gray-700 hover:text-white transition-all',
            [
              const Heroicon(HeroIcons.arrowRightOnRectangle),
              span([text('Logout')]),
            ],
          ),
        ]),
      ]),
      // Main content
      div(classes: 'flex-1 flex flex-col', [
        main_(classes: 'flex-1 p-8', [child]),
      ]),
    ]);
  }

  /// Builds grouped navigation items from resources.
  List<Component> _buildGroupedNavigation() {
    final navigationResources = resources.where((resource) => resource.shouldRegisterNavigation).toList()
      ..sort((a, b) => a.navigationSort.compareTo(b.navigationSort));

    // Group resources by navigationGroup
    final groupedResources = <String, List<Resource>>{};
    for (final resource in navigationResources) {
      final group = resource.navigationGroup ?? 'Main';
      groupedResources.putIfAbsent(group, () => []).add(resource);
    }

    // Build navigation items for each group
    final items = <Component>[];
    for (final entry in groupedResources.entries) {
      final groupName = entry.key;
      final groupResources = entry.value;

      // Add group header
      items.add(
        li(classes: 'mt-6 first:mt-0 mb-2 px-6', [
          span(classes: 'text-xs uppercase font-semibold tracking-wider text-gray-500', [text(groupName)]),
        ]),
      );

      // Add resources in this group
      for (final resource in groupResources) {
        items.add(
          li([
            a(
              href: '$basePath/resources/${resource.slug}',
              classes:
                  'flex items-center gap-3 px-6 py-3 text-gray-300 hover:bg-gray-700 hover:text-white transition-colors',
              [
                resource.iconComponent,
                span([text(resource.label)]),
              ],
            ),
          ]),
        );
      }
    }

    return items;
  }
}
