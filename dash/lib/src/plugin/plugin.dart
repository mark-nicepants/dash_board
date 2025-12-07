import 'dart:async';

import 'package:dash_board/src/panel/panel.dart';

/// Base contract for all Dash plugins.
///
/// A [Plugin] allows you to extend a Dash panel with additional functionality
/// such as resources, pages, navigation items, render hooks, and more.
///
/// Plugins follow a two-phase lifecycle:
/// 1. **Registration** - Called immediately when the plugin is added to a panel
/// 2. **Boot** - Called when the panel boots, before serving requests
///
/// Example:
/// ```dart
/// class BlogPlugin implements Plugin {
///   static BlogPlugin make() => BlogPlugin();
///
///   @override
///   String getId() => 'blog';
///
///   @override
///   void register(Panel panel) {
///     panel.registerResources([
///       PostResource(),
///       CategoryResource(),
///     ]);
///   }
///
///   @override
///   void boot(Panel panel) {
///     // Runtime initialization
///   }
/// }
/// ```
abstract class Plugin {
  /// Returns the unique identifier for this plugin.
  ///
  /// This ID is used to:
  /// - Prevent duplicate plugin registration
  /// - Retrieve the plugin instance later via `panel.getPlugin(id)`
  ///
  /// Convention: Use lowercase with hyphens (e.g., 'my-plugin').
  String getId();

  /// Called immediately when the plugin is added to a panel.
  ///
  /// Use this method to configure the panel with:
  /// - Resources via `panel.registerResources()`
  /// - Navigation items via `panel.navigationItems()`
  /// - Render hooks via `panel.renderHook()`
  /// - Assets via `panel.assets()`
  /// - Pages via `panel.pages()`
  ///
  /// This is called during panel configuration, before `boot()`.
  void register(Panel panel);

  /// Called when the panel boots, before serving requests.
  ///
  /// Use this method for runtime initialization:
  /// - Service registration with dependency injection
  /// - Database setup
  /// - External service connections
  ///
  /// The panel's database connection is available at this point.
  ///
  /// This method can return a [Future] for async initialization.
  FutureOr<void> boot(Panel panel);
}
