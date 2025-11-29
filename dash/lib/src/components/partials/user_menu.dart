import 'package:dash/src/components/partials/heroicon.dart';
import 'package:dash/src/service_locator.dart';
import 'package:jaspr/jaspr.dart';

/// User menu component that displays a user avatar with dropdown menu.
///
/// Displays the user's avatar image if available, otherwise falls back to
/// showing the user's initials in a colored circle.
///
/// Example:
/// ```dart
/// UserMenu(
///   name: 'John Doe',
///   avatarUrl: 'https://example.com/avatar.jpg',
///   basePath: '/admin',
/// )
/// ```
class UserMenu extends StatelessComponent {
  /// The user's display name.
  final String name;

  /// Optional avatar image URL.
  final String? avatarUrl;

  /// Base path for constructing menu links.
  final String basePath;

  const UserMenu({required this.name, required this.basePath, this.avatarUrl, super.key});

  /// Factory constructor following Dash conventions.
  static UserMenu make({required String name, required String basePath, String? avatarUrl}) =>
      UserMenu(name: name, basePath: basePath, avatarUrl: avatarUrl);

  @override
  Component build(BuildContext context) {
    return div(classes: 'relative', [
      // User avatar button
      button(
        type: ButtonType.button,
        classes:
            'flex items-center gap-2 p-1 rounded-full hover:bg-gray-700 transition-colors focus:outline-none focus:ring-2 focus:ring-purple-500',
        [_buildAvatar()],
      ),
      // Dropdown menu (non-interactive for now, hidden by default)
      _buildDropdownMenu(),
    ]);
  }

  /// Builds the avatar element - image if available, initials fallback otherwise.
  Component _buildAvatar() {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      // Use getStorageUrl to resolve the proper URL (handles relative paths)
      final resolvedUrl = getStorageUrl(avatarUrl!, disk: 'public');
      return img(src: resolvedUrl, alt: name, classes: 'w-9 h-9 rounded-full object-cover ring-2 ring-gray-600');
    }

    // Initials fallback
    final initials = _getInitials(name);
    return div(
      classes:
          'w-9 h-9 rounded-full bg-gradient-to-br from-purple-500 to-indigo-600 flex items-center justify-center text-white text-sm font-medium ring-2 ring-gray-600',
      [
        span([text(initials)]),
      ],
    );
  }

  /// Builds the dropdown menu with user actions.
  /// Currently hidden - interactivity will be added via framework conventions.
  Component _buildDropdownMenu() {
    return div(
      classes: 'hidden absolute right-0 mt-2 w-56 bg-gray-800 rounded-lg shadow-lg border border-gray-700 py-1 z-50',
      [
        // User info header
        div(classes: 'px-4 py-3 border-b border-gray-700', [
          p(classes: 'text-sm font-medium text-white truncate', [text(name)]),
        ]),
        // Menu items
        div(classes: 'py-1', [
          _buildMenuItem(icon: HeroIcons.user, label: 'Profile', href: '$basePath/profile'),
          _buildMenuItem(icon: HeroIcons.cog6Tooth, label: 'Settings', href: '$basePath/settings'),
        ]),
        // Logout divider
        div(classes: 'border-t border-gray-700', [
          _buildMenuItem(
            icon: HeroIcons.arrowRightOnRectangle,
            label: 'Logout',
            href: '$basePath/logout',
            isDanger: true,
          ),
        ]),
      ],
    );
  }

  /// Builds a single menu item with icon and label.
  Component _buildMenuItem({
    required HeroIcons icon,
    required String label,
    required String href,
    bool isDanger = false,
  }) {
    final textColorClass = isDanger ? 'text-red-400 hover:text-red-300' : 'text-gray-300 hover:text-white';
    final bgHoverClass = isDanger ? 'hover:bg-red-500/10' : 'hover:bg-gray-700';

    return a(
      href: href,
      classes: 'flex items-center gap-3 px-4 py-2 text-sm $textColorClass $bgHoverClass transition-colors',
      [
        Heroicon(icon, size: 18),
        span([text(label)]),
      ],
    );
  }

  /// Extracts initials from a name (up to 2 characters).
  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
    }
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }
}
