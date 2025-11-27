import 'package:dash/src/components/partials/heroicon.dart';
import 'package:dash/src/form/fields/section.dart';
import 'package:jaspr/jaspr.dart';

/// A form section component that groups related fields together.
///
/// Renders a card with optional heading, description, icon, and
/// collapsible behavior.
///
/// Example:
/// ```dart
/// FormSection(
///   section: mySection,
///   children: [
///     // field components
///   ],
/// )
/// ```
class FormSection extends StatelessComponent {
  /// The section configuration.
  final Section section;

  /// The content to render inside the section.
  final List<Component> children;

  const FormSection({required this.section, required this.children, super.key});

  @override
  Component build(BuildContext context) {
    final isCollapsible = section.isCollapsible();
    final isCollapsed = section.isCollapsed();
    final isCompact = section.isCompact();
    final isAside = section.isAside();

    // Section padding based on compact mode
    final contentPadding = isCompact ? 'p-4' : 'p-6';
    final headerPadding = isCompact ? 'px-4 py-3' : 'px-6 py-4';

    if (isAside) {
      return _buildAsideLayout(
        context,
        isCollapsible: isCollapsible,
        isCollapsed: isCollapsed,
        contentPadding: contentPadding,
      );
    }

    return _buildStandardLayout(
      context,
      isCollapsible: isCollapsible,
      isCollapsed: isCollapsed,
      contentPadding: contentPadding,
      headerPadding: headerPadding,
    );
  }

  /// Builds the aside layout: heading on left, content on right.
  Component _buildAsideLayout(
    BuildContext context, {
    required bool isCollapsible,
    required bool isCollapsed,
    required String contentPadding,
  }) {
    return div(
      classes: 'bg-gray-800/50 rounded-xl border border-gray-700',
      attributes: isCollapsible ? {'x-data': '{ open: ${!isCollapsed} }'} : null,
      [
        div(classes: 'grid grid-cols-1 lg:grid-cols-3 gap-6 $contentPadding', [
          // Left side: heading and description
          div(classes: 'lg:col-span-1', [
            if (section.getHeading() != null) ...[
              div(classes: 'flex items-center gap-3', [
                if (section.getIcon() != null) _buildSectionIcon(section.getIcon()!),
                h3(classes: 'text-base font-semibold text-gray-100', [text(section.getHeading()!)]),
              ]),
            ],
            if (section.getDescription() != null)
              p(classes: 'mt-1 text-sm text-gray-400', [text(section.getDescription()!)]),
          ]),
          // Right side: fields
          div(classes: 'lg:col-span-2', children),
        ]),
      ],
    );
  }

  /// Builds the standard layout: header on top, content below.
  Component _buildStandardLayout(
    BuildContext context, {
    required bool isCollapsible,
    required bool isCollapsed,
    required String contentPadding,
    required String headerPadding,
  }) {
    final hasHeader = section.getHeading() != null || section.getDescription() != null;

    return div(
      classes: 'bg-gray-800/50 rounded-xl border border-gray-700 overflow-hidden',
      attributes: isCollapsible ? {'x-data': '{ open: ${!isCollapsed} }'} : null,
      [
        // Section header
        if (hasHeader)
          div(
            classes: [
              headerPadding,
              if (isCollapsible) 'cursor-pointer hover:bg-gray-700/30',
              // Only show border when content is visible (not collapsed)
              if (isCollapsible)
                "border-b border-gray-700 transition-colors duration-200 x-bind:class=\"{ 'border-transparent': !open }\"",
              if (!isCollapsible) 'border-b border-gray-700',
            ].join(' '),
            attributes: {
              if (isCollapsible) '@click': 'open = !open',
              if (isCollapsible) ':class': "{ 'border-transparent': !open }",
            },
            [
              div(classes: 'flex items-center justify-between', [
                div(classes: 'flex items-center gap-3', [
                  if (section.getIcon() != null) _buildSectionIcon(section.getIcon()!),
                  div([
                    if (section.getHeading() != null)
                      h3(classes: 'text-base font-semibold text-gray-100', [text(section.getHeading()!)]),
                    if (section.getDescription() != null)
                      p(classes: 'text-sm text-gray-400', [text(section.getDescription()!)]),
                  ]),
                ]),
                if (isCollapsible)
                  span(
                    classes: 'text-gray-400 transition-transform duration-200',
                    attributes: {':class': "open ? 'rotate-180' : ''"},
                    [const Heroicon(HeroIcons.chevronUp, size: 20)],
                  ),
              ]),
            ],
          ),

        // Section content
        div(classes: contentPadding, attributes: isCollapsible ? {'x-show': 'open', 'x-collapse': ''} : null, children),
      ],
    );
  }

  Component _buildSectionIcon(String iconName) {
    final heroIcon = _getHeroIconFromName(iconName);
    if (heroIcon != null) {
      return span(classes: 'text-gray-400', [Heroicon(heroIcon, size: 20)]);
    }
    return span([]);
  }

  HeroIcons? _getHeroIconFromName(String name) {
    // Convert kebab-case to camelCase for enum lookup
    final camelCase = name.replaceAllMapped(RegExp(r'-([a-z])'), (match) => match.group(1)!.toUpperCase());

    try {
      return HeroIcons.values.firstWhere((icon) => icon.name.toLowerCase() == camelCase.toLowerCase());
    } catch (_) {
      return null;
    }
  }
}
