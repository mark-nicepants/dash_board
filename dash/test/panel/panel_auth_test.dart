import 'package:dash/src/auth/authenticatable.dart';
import 'package:dash/src/auth/session_store.dart';
import 'package:dash/src/model/model.dart';
import 'package:dash/src/panel/panel_auth.dart';
import 'package:dash/src/panel/panel_config.dart';
import 'package:dash/src/service_locator.dart';
import 'package:test/test.dart';

/// Minimal test user model for auth manager tests.
class _TestUser extends Model with Authenticatable {
  int? id;
  String email;
  String password;

  _TestUser({this.id, this.email = '', this.password = ''});

  @override
  String get table => 'users';

  @override
  Map<String, dynamic> toMap() => {'id': id, 'email': email, 'password': password};

  @override
  _TestUser fromMap(Map<String, dynamic> map) {
    return _TestUser(
      id: map['id'] as int?,
      email: map['email'] as String? ?? '',
      password: map['password'] as String? ?? '',
    );
  }

  @override
  dynamic getKey() => id;

  @override
  void setKey(dynamic key) => id = key as int?;

  @override
  List<String> getFields() => ['id', 'email', 'password'];

  @override
  String getAuthIdentifier() => email;

  @override
  String getAuthIdentifierName() => 'email';

  @override
  String getAuthPassword() => password;

  @override
  String getDisplayName() => email;

  @override
  void setAuthPassword(String hash) => password = hash;
}

void main() {
  group('PanelAuthManager', () {
    setUp(() async {
      await inject.reset();
    });

    tearDown(() async {
      await inject.reset();
    });

    test('hasAuthModel returns false initially', () {
      final manager = PanelAuthManager();
      expect(manager.hasAuthModel, isFalse);
    });

    test('authModel sets hasAuthModel to true', () {
      final manager = PanelAuthManager()..authModel<_TestUser>();
      expect(manager.hasAuthModel, isTrue);
    });

    test('authService throws when not initialized', () {
      final manager = PanelAuthManager();
      expect(() => manager.authService, throwsStateError);
    });

    test('sessionStore returns self for chaining', () {
      final manager = PanelAuthManager();
      final store = InMemorySessionStore();
      final result = manager.sessionStore(store);

      expect(result, same(manager));
    });

    test('initialize does nothing when no auth model configured', () {
      final manager = PanelAuthManager();
      final config = PanelConfig();

      // Should not throw
      manager.initialize(config: config);

      // Still not initialized
      expect(() => manager.authService, throwsStateError);
    });

    test('initialize throws when model not registered', () {
      final manager = PanelAuthManager()..authModel<_TestUser>();
      final config = PanelConfig();

      expect(() => manager.initialize(config: config), throwsStateError);
    });

    test('authModel with custom resolver stores resolver', () {
      final manager = PanelAuthManager()..authModel<_TestUser>(userResolver: (identifier) async => null);

      expect(manager.hasAuthModel, isTrue);
    });

    test('fluent API allows chaining authModel and sessionStore', () {
      final store = InMemorySessionStore();
      final manager = PanelAuthManager()
        ..authModel<_TestUser>()
        ..sessionStore(store);

      expect(manager.hasAuthModel, isTrue);
    });
  });
}
