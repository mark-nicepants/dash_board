import 'dart:async';

import 'package:dash/dash.dart';
import 'package:jaspr/jaspr.dart';
import 'package:shelf/shelf.dart';

/// Example settings page demonstrating the Custom Pages feature.
///
/// This page shows how to create a custom page that:
/// - Integrates with the admin layout
/// - Appears in sidebar navigation
/// - Has proper breadcrumbs
class SettingsPage extends Page {
  /// Factory constructor following Dash conventions.
  static SettingsPage make() => SettingsPage();

  @override
  String get slug => 'settings';

  @override
  String get title => 'Settings';

  @override
  HeroIcons? get icon => HeroIcons.cog6Tooth;

  @override
  String? get navigationGroup => 'System';

  @override
  int get navigationSort => 100;

  @override
  List<BreadCrumbItem> breadcrumbs(String basePath) => [
    BreadCrumbItem(label: 'Dashboard', url: basePath),
    const BreadCrumbItem(label: 'Settings'),
  ];

  @override
  FutureOr<Component> build(Request request, String basePath) {
    return div(classes: 'space-y-6', [
      // Page header
      div(classes: 'flex flex-col gap-2', [
        nav(classes: 'text-sm', [
          ol(classes: 'flex items-center gap-2', [
            li(classes: 'inline-flex', [
              a(href: basePath, classes: 'text-gray-400 hover:text-gray-200 transition-colors', [text('Dashboard')]),
            ]),
            li(classes: 'text-gray-600 select-none', [text('›')]),
            li(classes: 'inline-flex', [
              span(classes: 'text-gray-200', [text('Settings')]),
            ]),
          ]),
        ]),
        div(classes: 'flex justify-between items-center gap-4', [
          h1(classes: 'text-3xl font-bold text-gray-100', [text('Settings')]),
        ]),
      ]),

      // Settings cards
      div(classes: 'grid grid-cols-1 md:grid-cols-2 gap-6', [
        _buildSettingsCard(
          title: 'General Settings',
          description: 'Configure basic application settings',
          icon: HeroIcons.cog6Tooth,
        ),
        _buildSettingsCard(
          title: 'User Preferences',
          description: 'Customize your personal preferences',
          icon: HeroIcons.user,
        ),
        _buildSettingsCard(
          title: 'Notifications',
          description: 'Manage notification preferences',
          icon: HeroIcons.bell,
        ),
        _buildSettingsCard(title: 'Security', description: 'Configure security settings', icon: HeroIcons.shieldCheck),
      ]),

      // Example info box
      div(classes: 'bg-blue-900/30 border border-blue-700 rounded-lg p-4', [
        div(classes: 'flex gap-3', [
          div(classes: 'text-blue-400', [const Heroicon(HeroIcons.informationCircle)]),
          div([
            h3(classes: 'font-medium text-blue-200', [text('Custom Pages Feature')]),
            p(classes: 'mt-1 text-sm text-blue-300', [
              text(
                'This page demonstrates the Custom Pages feature in Dash. '
                'Custom pages allow you to create arbitrary pages that integrate '
                'with the admin layout, navigation, and breadcrumbs.',
              ),
            ]),
          ]),
        ]),
      ]),
    ]);
  }

  /// Builds a settings card component.
  Component _buildSettingsCard({required String title, required String description, required HeroIcons icon}) {
    return div(classes: 'bg-gray-800 rounded-xl border border-gray-700 p-6', [
      div(classes: 'flex items-start gap-4', [
        div(classes: 'p-3 bg-gray-700 rounded-lg', [
          div(classes: 'text-cyan-400', [Heroicon(icon)]),
        ]),
        div(classes: 'flex-1', [
          h3(classes: 'text-lg font-semibold text-white', [text(title)]),
          p(classes: 'mt-1 text-sm text-gray-400', [text(description)]),
        ]),
      ]),
      div(classes: 'mt-4', [
        a(
          href: '#',
          classes: 'inline-flex items-center gap-2 text-sm text-cyan-400 hover:text-cyan-300 transition-colors',
          [text('Configure'), const Heroicon(HeroIcons.arrowRight, size: 16)],
        ),
      ]),
    ]);
  }
}
