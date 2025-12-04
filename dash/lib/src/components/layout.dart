import 'package:dash/dash.dart';
import 'package:jaspr/jaspr.dart';

/// Base layout component for authenticated pages in the admin panel.
///
/// Provides the standard admin layout with:
/// - Sidebar navigation
/// - Top header with user menu
/// - Main content area
/// - Plugin render hooks
class DashLayout extends StatelessComponent {
  final Component child;
  final String title;
  final String basePath;
  final List<Resource> resources;
  final List<NavigationItem> navigationItems;
  final RenderHookRegistry? renderHooks;

  const DashLayout({
    required this.child,
    required this.title,
    required this.basePath,
    required this.resources,
    this.navigationItems = const [],
    this.renderHooks,
    super.key,
  });

  @override
  Component build(BuildContext context) {
    // Get user info from RequestSession
    final user = RequestContext.user as Authenticatable?;

    final userName = user?.getDisplayName();
    final userAvatarUrl =
        user?.toMap()['avatarUrl'] as String?; // Improve via schema update and expose via Authenticatable

    return div(classes: 'flex h-screen bg-gray-900 overflow-hidden', [
      // Sidebar (fixed)
      aside(classes: 'w-64 bg-gray-900 text-white flex flex-col h-screen', [
        div(classes: 'px-6 py-4 border-b border-gray-700 flex items-center h-[60px] bg-gray-800 shrink-0', [
          img(src: '$basePath/assets/img/logo_square.png', alt: 'Dash Logo', classes: 'h-10'),
        ]),
        nav(classes: 'flex-1 py-6 overflow-y-auto', [
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
            // Render hook: sidebar nav start
            ...?renderHooks?.render(RenderHook.sidebarNavStart),
            // Dynamically generate grouped resource navigation
            ..._buildGroupedNavigation(),
            // Render hook: sidebar nav end
            ...?renderHooks?.render(RenderHook.sidebarNavEnd),
          ]),
        ]),
        // Render hook: sidebar footer
        ...?renderHooks?.render(RenderHook.sidebarFooter),
      ]),
      // Main content area
      div(classes: 'flex-1 flex flex-col h-screen overflow-hidden', [
        // Top header with user menu (sticky)
        if (user != null)
          header(classes: 'flex items-center justify-end px-8 bg-gray-800 border-b border-gray-700 h-[60px] shrink-0', [
            UserMenu(name: userName!, avatarUrl: userAvatarUrl, basePath: basePath),
          ]),
        // Scrollable content area
        main_(classes: 'flex-1 p-8 overflow-y-auto', [
          // Render hook: content before
          ...?renderHooks?.render(RenderHook.contentBefore),
          child,
          // Render hook: content after
          ...?renderHooks?.render(RenderHook.contentAfter),
        ]),
      ]),
    ]);
  }

  /// Builds grouped navigation items from resources and plugin navigation items.
  List<Component> _buildGroupedNavigation() {
    final navigationResources = resources.where((resource) => resource.shouldRegisterNavigation).toList()
      ..sort((a, b) => a.navigationSort.compareTo(b.navigationSort));

    // Filter visible plugin navigation items
    final visibleNavItems = navigationItems.where((item) => item.isVisible).toList()
      ..sort((a, b) => a.getSort.compareTo(b.getSort));

    // Group resources by navigationGroup
    final groupedResources = <String, List<Resource>>{};
    for (final resource in navigationResources) {
      final group = resource.navigationGroup ?? 'Main';
      groupedResources.putIfAbsent(group, () => []).add(resource);
    }

    // Group plugin navigation items
    final groupedNavItems = <String, List<NavigationItem>>{};
    for (final item in visibleNavItems) {
      groupedNavItems.putIfAbsent(item.getGroup, () => []).add(item);
    }

    // Merge group names (resources first, then plugin items)
    final allGroups = <String>{...groupedResources.keys, ...groupedNavItems.keys};

    // Build navigation items for each group
    final items = <Component>[];
    for (final groupName in allGroups) {
      final groupResources = groupedResources[groupName] ?? [];
      final groupNavItems = groupedNavItems[groupName] ?? [];

      // Skip empty groups
      if (groupResources.isEmpty && groupNavItems.isEmpty) continue;

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

      // Add plugin navigation items in this group
      for (final navItem in groupNavItems) {
        final resolvedUrl = navItem.resolveUrl(basePath);
        final targetAttr = navItem.shouldOpenInNewTab ? {'target': '_blank', 'rel': 'noopener noreferrer'} : null;

        items.add(
          li([
            a(
              href: resolvedUrl,
              classes:
                  'flex items-center gap-3 px-6 py-3 text-gray-300 hover:bg-gray-700 hover:text-white transition-colors',
              attributes: targetAttr,
              [
                if (navItem.getIcon != null) Heroicon(navItem.getIcon!),
                span([text(navItem.label)]),
              ],
            ),
          ]),
        );
      }
    }

    return items;
  }
}
