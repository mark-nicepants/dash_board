import 'package:dash/dash.dart';
import 'package:dash/src/widgets/widget.dart' as dash;
import 'package:jaspr/jaspr.dart';
import 'package:test/test.dart';

/// Test model for panel config tests
class TestModel extends Model {
  int? id;
  String name;

  TestModel({this.id, this.name = ''});

  @override
  String get table => 'test_models';

  @override
  Map<String, dynamic> toMap() => {'id': id, 'name': name};

  @override
  TestModel fromMap(Map<String, dynamic> map) {
    return TestModel(id: map['id'] as int?, name: map['name'] as String? ?? '');
  }

  @override
  dynamic getKey() => id;

  @override
  void setKey(dynamic key) {
    id = key as int?;
  }

  @override
  List<String> getFields() => ['id', 'name'];
}

/// Test resource for panel config tests
class TestResource extends Resource<TestModel> {
  @override
  String get label => 'Tests';

  @override
  String get singularLabel => 'Test';

  @override
  String get slug => 'tests';
}

/// Second test resource
class AnotherResource extends Resource<TestModel> {
  @override
  String get label => 'Another';

  @override
  String get singularLabel => 'Another';

  @override
  String get slug => 'another';
}

/// Test plugin for config tests
class TestPlugin implements Plugin {
  @override
  String getId() => 'test-plugin';

  @override
  void register(Panel panel) {}

  @override
  void boot(Panel panel) {}
}

/// Test widget for config tests
class TestWidget extends dash.Widget {
  @override
  String? get heading => 'Test';

  @override
  Component build() => div([text('Test')]);
}

void main() {
  group('PanelConfig', () {
    group('initialization', () {
      test('creates config with default values', () {
        final config = PanelConfig();

        expect(config.id, equals('admin'));
        expect(config.path, equals('/admin'));
        expect(config.resources, isEmpty);
        expect(config.widgets, isEmpty);
        expect(config.databaseConfig, isNull);
        expect(config.colors, equals(PanelColors.defaults));
      });
    });

    group('id and path', () {
      test('setId changes id', () {
        final config = PanelConfig()..setId('dashboard');

        expect(config.id, equals('dashboard'));
      });

      test('setPath changes path', () {
        final config = PanelConfig()..setPath('/dashboard');

        expect(config.path, equals('/dashboard'));
      });
    });

    group('colors', () {
      test('setColors changes color scheme', () {
        const customColors = PanelColors(primary: 'indigo', danger: 'rose');
        final config = PanelConfig()..setColors(customColors);

        expect(config.colors.primary, equals('indigo'));
        expect(config.colors.danger, equals('rose'));
      });
    });

    group('resources', () {
      test('registerResources adds resources', () {
        final config = PanelConfig()..registerResources([TestResource()]);

        expect(config.resources, hasLength(1));
        expect(config.resources.first, isA<TestResource>());
      });

      test('registerResources prevents duplicates of same type', () {
        final config = PanelConfig()
          ..registerResources([TestResource()])
          ..registerResources([TestResource()]);

        expect(config.resources, hasLength(1));
      });

      test('registerResources allows different resource types', () {
        final config = PanelConfig()..registerResources([TestResource(), AnotherResource()]);

        expect(config.resources, hasLength(2));
      });

      test('resources returns unmodifiable list', () {
        final config = PanelConfig()..registerResources([TestResource()]);

        expect(() => config.resources.add(AnotherResource()), throwsUnsupportedError);
      });
    });

    group('widgets', () {
      test('registerWidgets adds widgets', () {
        final config = PanelConfig()..registerWidgets([TestWidget()]);

        expect(config.widgets, hasLength(1));
        expect(config.widgets.first, isA<TestWidget>());
      });

      test('widgets returns unmodifiable list', () {
        final config = PanelConfig()..registerWidgets([TestWidget()]);

        expect(() => config.widgets.add(TestWidget()), throwsUnsupportedError);
      });
    });

    group('plugins', () {
      test('registerPlugin adds plugin', () {
        final plugin = TestPlugin();
        final config = PanelConfig()..registerPlugin(plugin);

        expect(config.hasPlugin('test-plugin'), isTrue);
        expect(config.plugins, hasLength(1));
      });

      test('registerPlugin throws for duplicate ID', () {
        final plugin1 = TestPlugin();
        final plugin2 = TestPlugin();
        final config = PanelConfig()..registerPlugin(plugin1);

        expect(() => config.registerPlugin(plugin2), throwsStateError);
      });

      test('getPlugin returns registered plugin', () {
        final plugin = TestPlugin();
        final config = PanelConfig()..registerPlugin(plugin);

        expect(config.getPlugin('test-plugin'), equals(plugin));
      });

      test('getPlugin throws for unknown plugin', () {
        final config = PanelConfig();

        expect(() => config.getPlugin('unknown'), throwsStateError);
      });

      test('hasPlugin returns false for unknown plugin', () {
        final config = PanelConfig();

        expect(config.hasPlugin('unknown'), isFalse);
      });

      test('plugins returns unmodifiable map', () {
        final config = PanelConfig()..registerPlugin(TestPlugin());

        expect(() => config.plugins['new'] = TestPlugin(), throwsUnsupportedError);
      });
    });

    group('navigation items', () {
      test('registerNavigationItems adds items', () {
        final config = PanelConfig()..registerNavigationItems([NavigationItem.make('Test').url('/test')]);

        expect(config.navigationItems, hasLength(1));
        expect(config.navigationItems.first.label, equals('Test'));
      });

      test('navigationItems returns unmodifiable list', () {
        final config = PanelConfig()..registerNavigationItems([NavigationItem.make('Test').url('/test')]);

        expect(() => config.navigationItems.add(NavigationItem.make('New').url('/new')), throwsUnsupportedError);
      });
    });

    group('render hooks', () {
      test('registerRenderHook adds hook', () {
        final config = PanelConfig()..registerRenderHook(RenderHook.sidebarFooter, () => span([text('Footer')]));

        expect(config.renderHooks.hasHook(RenderHook.sidebarFooter), isTrue);
      });

      test('multiple hooks for same location', () {
        final config = PanelConfig()
          ..registerRenderHook(RenderHook.sidebarFooter, () => span([text('One')]))
          ..registerRenderHook(RenderHook.sidebarFooter, () => span([text('Two')]));

        expect(config.renderHooks.render(RenderHook.sidebarFooter), hasLength(2));
      });
    });

    group('assets', () {
      test('registerAssets adds CSS assets', () {
        final config = PanelConfig()..registerAssets([CssAsset.url('test', 'https://example.com/style.css')]);

        expect(config.assets.cssAssets, hasLength(1));
      });

      test('registerAssets adds JS assets', () {
        final config = PanelConfig()..registerAssets([JsAsset.url('test', 'https://example.com/script.js')]);

        expect(config.assets.jsAssets, hasLength(1));
      });
    });

    group('validation', () {
      test('validate throws for empty path', () {
        final config = PanelConfig()..setPath('');

        expect(config.validate, throwsStateError);
      });

      test('validate throws for empty id', () {
        final config = PanelConfig()..setId('');

        expect(config.validate, throwsStateError);
      });

      test('validate passes with valid config', () {
        final config = PanelConfig()
          ..setId('admin')
          ..setPath('/admin');

        expect(config.validate, returnsNormally);
      });
    });
  });
}
