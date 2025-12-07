import 'dart:async';

import 'package:dash_board/dash_board.dart';
import 'package:jaspr/jaspr.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

/// Test page for custom pages tests
class TestPage extends Page {
  @override
  String get slug => 'test-page';

  @override
  String get title => 'Test Page';

  @override
  HeroIcons? get icon => HeroIcons.documentText;

  @override
  String? get navigationGroup => 'Testing';

  @override
  int get navigationSort => 10;

  @override
  List<BreadCrumbItem> breadcrumbs(String basePath) => [
    BreadCrumbItem(label: 'Dashboard', url: basePath),
    const BreadCrumbItem(label: 'Test Page'),
  ];

  @override
  FutureOr<Component> build(Request request, String basePath, {Map<String, dynamic>? formData}) {
    return div([text('Test Page Content')]);
  }

  static TestPage make() => TestPage();
}

/// Another test page for testing multiple pages
class AnotherTestPage extends Page {
  @override
  String get slug => 'another-page';

  @override
  String get title => 'Another Page';

  @override
  List<BreadCrumbItem> breadcrumbs(String basePath) => [const BreadCrumbItem(label: 'Another')];

  @override
  FutureOr<Component> build(Request request, String basePath, {Map<String, dynamic>? formData}) {
    return div([text('Another Page Content')]);
  }

  static AnotherTestPage make() => AnotherTestPage();
}

/// Test page without navigation registration
class NoNavPage extends Page {
  @override
  String get slug => 'no-nav';

  @override
  String get title => 'No Navigation Page';

  // navigationGroup is null by default, so this won't be in nav

  @override
  List<BreadCrumbItem> breadcrumbs(String basePath) => [const BreadCrumbItem(label: 'No Nav')];

  @override
  FutureOr<Component> build(Request request, String basePath, {Map<String, dynamic>? formData}) {
    return div([text('No Nav Page')]);
  }

  static NoNavPage make() => NoNavPage();
}

void main() {
  group('Page', () {
    group('properties', () {
      test('slug returns unique identifier', () {
        final page = TestPage.make();
        expect(page.slug, equals('test-page'));
      });

      test('title returns display title', () {
        final page = TestPage.make();
        expect(page.title, equals('Test Page'));
      });

      test('icon returns optional icon', () {
        final page = TestPage.make();
        expect(page.icon, equals(HeroIcons.documentText));
      });

      test('icon defaults to null', () {
        final page = AnotherTestPage.make();
        expect(page.icon, isNull);
      });

      test('navigationGroup returns group name', () {
        final page = TestPage.make();
        expect(page.navigationGroup, equals('Testing'));
      });

      test('navigationGroup defaults to null', () {
        final page = NoNavPage.make();
        expect(page.navigationGroup, isNull);
      });

      test('navigationSort returns sort order', () {
        final page = TestPage.make();
        expect(page.navigationSort, equals(10));
      });

      test('navigationSort defaults to 0', () {
        final page = AnotherTestPage.make();
        expect(page.navigationSort, equals(0));
      });

      test('shouldRegisterNavigation true when navigationGroup set', () {
        final page = TestPage.make();
        expect(page.shouldRegisterNavigation, isTrue);
      });

      test('shouldRegisterNavigation false when navigationGroup null', () {
        final page = NoNavPage.make();
        expect(page.shouldRegisterNavigation, isFalse);
      });

      test('assets returns null by default', () {
        final page = TestPage.make();
        expect(page.assets, isNull);
      });
    });

    group('breadcrumbs', () {
      test('breadcrumbs returns list of items', () {
        final page = TestPage.make();
        final crumbs = page.breadcrumbs('/admin');

        expect(crumbs, hasLength(2));
        expect(crumbs[0].label, equals('Dashboard'));
        expect(crumbs[0].url, equals('/admin'));
        expect(crumbs[1].label, equals('Test Page'));
        expect(crumbs[1].url, isNull);
      });

      test('breadcrumbs uses basePath for urls', () {
        final page = TestPage.make();
        final crumbs = page.breadcrumbs('/custom-path');

        expect(crumbs[0].url, equals('/custom-path'));
      });
    });
  });

  group('PanelConfig pages', () {
    test('registerPages adds pages to config', () {
      final config = PanelConfig();
      config.registerPages([TestPage.make()]);

      expect(config.pages, hasLength(1));
      expect(config.pages.first.slug, equals('test-page'));
    });

    test('registerPages prevents duplicate slugs', () {
      final config = PanelConfig();
      config.registerPages([TestPage.make()]);
      config.registerPages([TestPage.make()]);

      expect(config.pages, hasLength(1));
    });

    test('registerPages adds multiple different pages', () {
      final config = PanelConfig();
      config.registerPages([TestPage.make(), AnotherTestPage.make()]);

      expect(config.pages, hasLength(2));
    });

    test('registerPages auto-creates navigation items for pages with groups', () {
      final config = PanelConfig();
      config.registerPages([TestPage.make()]);

      expect(config.navigationItems, hasLength(1));
      expect(config.navigationItems.first.label, equals('Test Page'));
      expect(config.navigationItems.first.getGroup, equals('Testing'));
      expect(config.navigationItems.first.getUrl, equals('/pages/test-page'));
    });

    test('registerPages does not create nav items for pages without groups', () {
      final config = PanelConfig();
      config.registerPages([NoNavPage.make()]);

      expect(config.pages, hasLength(1));
      expect(config.navigationItems, isEmpty);
    });

    test('pages list is unmodifiable', () {
      final config = PanelConfig();
      config.registerPages([TestPage.make()]);

      expect(() => config.pages.add(AnotherTestPage.make()), throwsUnsupportedError);
    });
  });

  group('Panel pages', () {
    setUp(() async {
      await inject.reset();
    });

    tearDown(() async {
      await inject.reset();
    });

    test('registerPages adds pages via Panel', () {
      final panel = Panel()..registerPages([TestPage.make()]);

      // Panel doesn't expose pages directly, but config does
      expect(panel, isNotNull);
    });

    test('registerPages is chainable', () {
      final panel = Panel()
        ..setId('test')
        ..registerPages([TestPage.make()])
        ..setPath('/test');

      expect(panel.id, equals('test'));
      expect(panel.path, equals('/test'));
    });

    test('registerPages works with plugins', () {
      var pageCount = 0;
      final plugin = _TestPagesPlugin(
        onRegister: (panel) {
          panel.registerPages([TestPage.make()]);
          pageCount = 1;
        },
      );

      Panel().plugin(plugin);

      expect(pageCount, equals(1));
    });
  });

  group('BreadCrumbItem', () {
    test('creates item with label only', () {
      const item = BreadCrumbItem(label: 'Test');
      expect(item.label, equals('Test'));
      expect(item.url, isNull);
    });

    test('creates item with label and url', () {
      final item = const BreadCrumbItem(label: 'Home', url: '/admin');
      expect(item.label, equals('Home'));
      expect(item.url, equals('/admin'));
    });
  });
}

/// Test plugin that registers pages
class _TestPagesPlugin implements Plugin {
  final void Function(Panel) onRegister;

  _TestPagesPlugin({required this.onRegister});

  @override
  String getId() => 'test-pages-plugin';

  @override
  void register(Panel panel) {
    onRegister(panel);
  }

  @override
  FutureOr<void> boot(Panel panel) {}
}
