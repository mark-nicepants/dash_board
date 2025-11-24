import 'package:jaspr/jaspr.dart';

import '../resource.dart';
import 'heroicon.dart';

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
    return div(classes: 'dash-layout', [
      // Sidebar
      aside(classes: 'dash-sidebar', [
        div(classes: 'dash-logo', [
          h2([text('DASH')]),
        ]),
        nav(classes: 'dash-nav', [
          ul([
            li([
              a(href: basePath, [
                const Heroicon(HeroIcons.home),
                span([text('Dashboard')]),
              ]),
            ]),
            // Dynamically generate grouped resource navigation
            ..._buildGroupedNavigation(),
          ]),
        ]),
        // Logout button
        div(classes: 'dash-sidebar-footer', [
          a(href: '$basePath/logout', classes: 'logout-button', [
            const Heroicon(HeroIcons.arrowRightOnRectangle),
            span([text('Logout')]),
          ]),
        ]),
      ]),
      // Main content
      div(classes: 'dash-main', [
        main_(classes: 'dash-content', [child]),
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
        li(classes: 'nav-group-header', [
          span([text(groupName)]),
        ]),
      );

      // Add resources in this group
      for (final resource in groupResources) {
        items.add(
          li([
            a(href: '$basePath/resources/${resource.slug}', [
              resource.iconComponent,
              span([text(resource.label)]),
            ]),
          ]),
        );
      }
    }

    return items;
  }
}
