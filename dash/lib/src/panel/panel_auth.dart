import 'package:dash_board/src/auth/auth_service.dart';
import 'package:dash_board/src/auth/authenticatable.dart';
import 'package:dash_board/src/auth/session_store.dart';
import 'package:dash_board/src/model/model.dart';
import 'package:dash_board/src/panel/panel_config.dart';
import 'package:dash_board/src/service_locator.dart';

/// Manages authentication configuration for a panel.
class PanelAuthManager {
  Type? _authModelType;
  UserResolver<Model>? _customUserResolver;
  SessionStore? _sessionStore;
  AuthService<Model>? _authService;

  /// Whether an auth model has been configured.
  bool get hasAuthModel => _authModelType != null;

  /// Returns the initialized auth service.
  AuthService<Model> get authService {
    if (_authService == null) {
      throw StateError('No auth model configured. Call authModel<YourUser>() before accessing authService.');
    }
    return _authService!;
  }

  /// Configures the user model for authentication.
  PanelAuthManager authModel<T extends Model>({UserResolver<T>? userResolver}) {
    _authModelType = T;
    if (userResolver != null) {
      _customUserResolver = (identifier) async => await userResolver(identifier);
    }
    return this;
  }

  /// Configures the session store used by the auth service.
  PanelAuthManager sessionStore(SessionStore store) {
    _sessionStore = store;
    return this;
  }

  /// Initializes the auth service once the panel configuration is ready.
  void initialize({required PanelConfig config}) {
    if (_authModelType == null) {
      return;
    }

    final typeString = _authModelType.toString();
    final modelSlug = _toSnakeCase(typeString);

    Model instance;
    try {
      instance = modelInstanceFromSlug<Model>(modelSlug);
    } catch (_) {
      throw StateError(
        'Model $_authModelType not registered. '
        'Make sure to call $_authModelType.register() before Panel.boot().',
      );
    }

    final resolver = _customUserResolver ?? _createDefaultUserResolver(modelSlug, instance, config);

    _authService = AuthService<Model>(userResolver: resolver, panelId: config.id, sessionStore: _sessionStore);
  }

  UserResolver<Model> _createDefaultUserResolver(String modelSlug, Model templateInstance, PanelConfig config) {
    return (String identifier) async {
      if (templateInstance is! Authenticatable) {
        throw StateError('Model ${templateInstance.runtimeType} must implement Authenticatable mixin');
      }
      final identifierField = templateInstance.getAuthIdentifierName();
      final connector = config.databaseConfig?.connector;
      if (connector == null) {
        throw StateError('Database connector not configured. Call Panel.database() before boot().');
      }

      final results = await connector.query(
        'SELECT * FROM ${templateInstance.table} WHERE $identifierField = ? LIMIT 1',
        [identifier],
      );

      if (results.isEmpty) {
        return null;
      }

      final user = modelInstanceFromSlug<Model>(modelSlug);
      user.fromMap(results.first);
      return user;
    };
  }

  String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(RegExp(r'[A-Z]'), (match) => '_${match.group(0)!.toLowerCase()}')
        .replaceFirst(RegExp(r'^_'), '');
  }
}
