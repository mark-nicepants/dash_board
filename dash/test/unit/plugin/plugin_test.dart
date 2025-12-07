import 'package:dash/dash.dart';
import 'package:jaspr/jaspr.dart';
import 'package:test/test.dart';

/// Test plugin for unit testing.
class TestPlugin implements Plugin {
  bool registerCalled = false;
  bool bootCalled = false;
  Panel? registeredPanel;
  Panel? bootedPanel;

  static TestPlugin make() => TestPlugin();

  @override
  String getId() => 'test-plugin';

  @override
  void register(Panel panel) {
    registerCalled = true;
    registeredPanel = panel;
  }

  @override
  void boot(Panel panel) {
    bootCalled = true;
    bootedPanel = panel;
  }
}

/// Plugin that registers resources.
class ResourcePlugin implements Plugin {
  final List<Resource> resources;

  ResourcePlugin(this.resources);

  static ResourcePlugin make(List<Resource> resources) => ResourcePlugin(resources);

  @override
  String getId() => 'resource-plugin';

  @override
  void register(Panel panel) {
    panel.registerResources(resources);
  }

  @override
  void boot(Panel panel) {}
}

void main() {
  group('Plugin', () {
    test('plugin is called on registration', () {
      final plugin = TestPlugin.make();
      final panel = Panel();

      panel.plugin(plugin);

      expect(plugin.registerCalled, isTrue);
      expect(plugin.registeredPanel, equals(panel));
      expect(plugin.bootCalled, isFalse);
    });

    test('multiple plugins can be registered', () {
      final plugin1 = TestPlugin.make();
      final plugin2 = _AnotherTestPlugin.make();
      final panel = Panel();

      panel.plugins([plugin1, plugin2]);

      expect(plugin1.registerCalled, isTrue);
      expect(plugin2.registerCalled, isTrue);
    });

    test('hasPlugin returns true for registered plugins', () {
      final plugin = TestPlugin.make();
      final panel = Panel();

      panel.plugin(plugin);

      expect(panel.hasPlugin('test-plugin'), isTrue);
      expect(panel.hasPlugin('unknown'), isFalse);
    });

    test('getPlugin returns the registered plugin', () {
      final plugin = TestPlugin.make();
      final panel = Panel();

      panel.plugin(plugin);

      expect(panel.getPlugin<TestPlugin>('test-plugin'), equals(plugin));
    });

    test('getPlugin throws for unknown plugin', () {
      final panel = Panel();

      expect(() => panel.getPlugin<TestPlugin>('unknown'), throwsStateError);
    });

    test('duplicate plugin ID throws error', () {
      final plugin1 = TestPlugin.make();
      final plugin2 = TestPlugin.make();
      final panel = Panel();

      panel.plugin(plugin1);

      expect(() => panel.plugin(plugin2), throwsStateError);
    });
  });

  group('NavigationItem', () {
    test('creates navigation item with label', () {
      final item = NavigationItem.make('Dashboard');

      expect(item.label, equals('Dashboard'));
    });

    test('fluent configuration works', () {
      final item = NavigationItem.make(
        'Settings',
      ).url('/settings').icon(HeroIcons.cog6Tooth).group('Admin').sort(10).openInNewTab();

      expect(item.label, equals('Settings'));
      expect(item.getUrl, equals('/settings'));
      expect(item.getIcon, equals(HeroIcons.cog6Tooth));
      expect(item.getGroup, equals('Admin'));
      expect(item.getSort, equals(10));
      expect(item.shouldOpenInNewTab, isTrue);
    });

    test('resolveUrl handles relative paths', () {
      final item = NavigationItem.make('Test').url('/test');

      expect(item.resolveUrl('/admin'), equals('/admin/test'));
    });

    test('resolveUrl preserves absolute URLs', () {
      final item = NavigationItem.make('Docs').url('https://docs.example.com');

      expect(item.resolveUrl('/admin'), equals('https://docs.example.com'));
    });

    test('visibility condition works', () {
      var isVisible = true;
      final item = NavigationItem.make('Test').visibleWhen(() => isVisible);

      expect(item.isVisible, isTrue);

      isVisible = false;
      expect(item.isVisible, isFalse);
    });
  });

  group('RenderHookRegistry', () {
    test('registers and renders hooks', () {
      final registry = RenderHookRegistry();

      registry.register(RenderHook.sidebarFooter, () => span([text('Footer')]));

      expect(registry.hasHook(RenderHook.sidebarFooter), isTrue);
      expect(registry.render(RenderHook.sidebarFooter).length, equals(1));
    });

    test('multiple hooks for same location', () {
      final registry = RenderHookRegistry();

      registry.register(RenderHook.sidebarFooter, () => span([text('One')]));
      registry.register(RenderHook.sidebarFooter, () => span([text('Two')]));

      expect(registry.render(RenderHook.sidebarFooter).length, equals(2));
    });

    test('returns empty list for unregistered hooks', () {
      final registry = RenderHookRegistry();

      expect(registry.hasHook(RenderHook.sidebarFooter), isFalse);
      expect(registry.render(RenderHook.sidebarFooter), isEmpty);
    });

    test('clear removes all hooks', () {
      final registry = RenderHookRegistry();

      registry.register(RenderHook.sidebarFooter, () => span([text('Test')]));
      registry.clear();

      expect(registry.hasHook(RenderHook.sidebarFooter), isFalse);
    });
  });

  group('AssetRegistry', () {
    test('registers CSS assets', () {
      final registry = AssetRegistry();

      registry.registerCss(CssAsset.url('my-plugin', 'https://example.com/style.css'));

      expect(registry.cssAssets.length, equals(1));
      expect(registry.cssAssets.first.id, equals('my-plugin'));
    });

    test('registers JS assets', () {
      final registry = AssetRegistry();

      registry.registerJs(JsAsset.inline('my-plugin', 'console.log("hello")'));

      expect(registry.jsAssets.length, equals(1));
      expect(registry.jsAssets.first.id, equals('my-plugin'));
    });

    test('prevents duplicate assets', () {
      final registry = AssetRegistry();

      registry.registerCss(CssAsset.url('my-plugin', 'https://example.com/style.css'));
      registry.registerCss(CssAsset.url('my-plugin', 'https://example.com/other.css'));

      expect(registry.cssAssets.length, equals(1));
    });

    test('renders CSS assets correctly', () {
      final registry = AssetRegistry();

      registry.registerCss(CssAsset.url('plugin1', 'https://example.com/style.css'));
      registry.registerCss(CssAsset.inline('plugin2', '.foo { color: red; }'));

      final rendered = registry.renderCss();

      expect(rendered, contains('href="https://example.com/style.css"'));
      expect(rendered, contains('.foo { color: red; }'));
    });
  });
}

/// Another test plugin with different ID.
class _AnotherTestPlugin implements Plugin {
  bool registerCalled = false;

  static _AnotherTestPlugin make() => _AnotherTestPlugin();

  @override
  String getId() => 'another-test-plugin';

  @override
  void register(Panel panel) {
    registerCalled = true;
  }

  @override
  void boot(Panel panel) {}
}
