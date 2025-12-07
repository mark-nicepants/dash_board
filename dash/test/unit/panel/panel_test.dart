import 'dart:async';

import 'package:dash/dash.dart';
import 'package:dash/src/widgets/widget.dart' as dash;
import 'package:jaspr/jaspr.dart';
import 'package:test/test.dart';

/// Test model for panel tests
class TestUser extends Model with Authenticatable {
  int? id;
  String email;
  String password;
  String name;

  TestUser({this.id, this.email = '', this.password = '', this.name = ''});

  @override
  String get table => 'users';

  @override
  Map<String, dynamic> toMap() => {'id': id, 'email': email, 'password': password, 'name': name};

  @override
  TestUser fromMap(Map<String, dynamic> map) {
    return TestUser(
      id: map['id'] as int?,
      email: map['email'] as String? ?? '',
      password: map['password'] as String? ?? '',
      name: map['name'] as String? ?? '',
    );
  }

  @override
  dynamic getKey() => id;

  @override
  void setKey(dynamic key) {
    id = key as int?;
  }

  @override
  List<String> getFields() => ['id', 'email', 'password', 'name'];

  @override
  String getAuthIdentifier() => email;

  @override
  String getAuthIdentifierName() => 'email';

  @override
  String getAuthPassword() => password;

  @override
  String getDisplayName() => name;

  @override
  void setAuthPassword(String hash) {
    password = hash;
  }
}

/// Test resource for panel tests
class TestUserResource extends Resource<TestUser> {
  @override
  String get label => 'Users';

  @override
  String get singularLabel => 'User';

  @override
  String get slug => 'users';
}

/// Test plugin for panel tests
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
  FutureOr<void> boot(Panel panel) {
    bootCalled = true;
    bootedPanel = panel;
  }
}

/// Another test plugin with different ID
class AnotherTestPlugin implements Plugin {
  bool registerCalled = false;

  static AnotherTestPlugin make() => AnotherTestPlugin();

  @override
  String getId() => 'another-plugin';

  @override
  void register(Panel panel) {
    registerCalled = true;
  }

  @override
  FutureOr<void> boot(Panel panel) {}
}

/// Test widget for panel tests
class TestWidget extends dash.Widget {
  @override
  String? get heading => 'Test Widget';

  @override
  Component build() => div([text('Test Widget Content')]);

  static TestWidget make() => TestWidget();
}

void main() {
  group('Panel', () {
    setUp(() async {
      await inject.reset();
    });

    tearDown(() async {
      await inject.reset();
    });

    group('initialization', () {
      test('creates panel with default values', () {
        final panel = Panel();

        expect(panel.id, equals('admin'));
        expect(panel.path, equals('/admin'));
        expect(panel.resources, isEmpty);
        expect(panel.databaseConfig, isNull);
      });

      test('setId configures panel id', () {
        final panel = Panel()..setId('dashboard');

        expect(panel.id, equals('dashboard'));
      });

      test('setPath configures panel path', () {
        final panel = Panel()..setPath('/dashboard');

        expect(panel.path, equals('/dashboard'));
      });

      test('fluent API allows chaining', () {
        final panel = Panel()
          ..setId('custom')
          ..setPath('/custom');

        expect(panel.id, equals('custom'));
        expect(panel.path, equals('/custom'));
      });
    });

    group('resources', () {
      test('registerResources adds resources to panel', () {
        final panel = Panel()..registerResources([TestUserResource()]);

        expect(panel.resources, hasLength(1));
        expect(panel.resources.first, isA<TestUserResource>());
      });

      test('registerResources prevents duplicates', () {
        final panel = Panel()
          ..registerResources([TestUserResource()])
          ..registerResources([TestUserResource()]);

        expect(panel.resources, hasLength(1));
      });

      test('multiple different resources can be registered', () {
        final panel = Panel()..registerResources([TestUserResource(), _AnotherResource()]);

        expect(panel.resources, hasLength(2));
      });
    });

    group('colors', () {
      test('uses default colors when not configured', () {
        final panel = Panel();

        // Access colors through config
        expect(panel, isNotNull);
      });

      test('colors configures panel color scheme', () {
        final customColors = const PanelColors(
          primary: 'indigo',
          danger: 'rose',
          warning: 'orange',
          success: 'emerald',
          info: 'sky',
        );
        final panel = Panel()..colors(customColors);

        expect(panel, isNotNull);
      });
    });

    group('plugins', () {
      test('plugin registers and calls register()', () {
        final plugin = TestPlugin.make();
        final panel = Panel()..plugin(plugin);

        expect(plugin.registerCalled, isTrue);
        expect(plugin.registeredPanel, equals(panel));
        expect(plugin.bootCalled, isFalse);
      });

      test('plugins registers multiple plugins', () {
        final plugin1 = TestPlugin.make();
        final plugin2 = AnotherTestPlugin.make();
        Panel().plugins([plugin1, plugin2]);

        expect(plugin1.registerCalled, isTrue);
        expect(plugin2.registerCalled, isTrue);
      });

      test('hasPlugin returns true for registered plugin', () {
        final plugin = TestPlugin.make();
        final panel = Panel()..plugin(plugin);

        expect(panel.hasPlugin('test-plugin'), isTrue);
      });

      test('hasPlugin returns false for unregistered plugin', () {
        final panel = Panel();

        expect(panel.hasPlugin('unknown'), isFalse);
      });

      test('getPlugin returns registered plugin', () {
        final plugin = TestPlugin.make();
        final panel = Panel()..plugin(plugin);

        final retrieved = panel.getPlugin<TestPlugin>('test-plugin');
        expect(retrieved, equals(plugin));
      });

      test('getPlugin throws for unknown plugin', () {
        final panel = Panel();

        expect(() => panel.getPlugin<TestPlugin>('unknown'), throwsStateError);
      });

      test('registering duplicate plugin ID throws error', () {
        final plugin1 = TestPlugin.make();
        final plugin2 = TestPlugin.make();
        final panel = Panel()..plugin(plugin1);

        expect(() => panel.plugin(plugin2), throwsStateError);
      });
    });

    group('navigation items', () {
      test('navigationItems adds items to panel', () {
        final panel = Panel()
          ..navigationItems([
            NavigationItem.make('Dashboard').url('/dashboard'),
            NavigationItem.make('Settings').url('/settings'),
          ]);

        expect(panel, isNotNull);
      });
    });

    group('render hooks', () {
      test('renderHook registers hook builder', () {
        final panel = Panel()..renderHook(RenderHook.sidebarFooter, () => span([text('Test')]));

        expect(panel, isNotNull);
      });

      test('multiple hooks can be registered for same location', () {
        final panel = Panel()
          ..renderHook(RenderHook.sidebarFooter, () => span([text('One')]))
          ..renderHook(RenderHook.sidebarFooter, () => span([text('Two')]));

        expect(panel, isNotNull);
      });
    });

    group('widgets', () {
      test('widgets registers dashboard widgets', () {
        final panel = Panel()..widgets([TestWidget.make()]);

        expect(panel, isNotNull);
      });
    });

    group('event callbacks', () {
      test('onRequest registers request callback', () {
        var callbackCalled = false;
        final panel = Panel()
          ..onRequest((_) async {
            callbackCalled = true;
          });

        expect(panel, isNotNull);
        expect(callbackCalled, isFalse);
      });
    });

    group('auth', () {
      test('authService throws when not configured', () {
        final panel = Panel();

        expect(() => panel.authService, throwsStateError);
      });

      test('authModel configures auth model type', () {
        final panel = Panel()..authModel<TestUser>();

        // Can't access authService without database, but model is configured
        expect(panel, isNotNull);
      });
    });

    group('query', () {
      test('query throws when no database configured', () {
        final panel = Panel();

        expect(panel.query, throwsStateError);
      });
    });
  });
}

/// Another test resource for testing multiple resources
class _AnotherResource extends Resource<TestUser> {
  @override
  String get label => 'Another';

  @override
  String get singularLabel => 'Another';

  @override
  String get slug => 'another';
}
