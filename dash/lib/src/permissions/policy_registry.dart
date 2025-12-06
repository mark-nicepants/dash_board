import 'package:dash/src/model/model.dart';
import 'package:dash/src/permissions/policy.dart';

/// Registry for model policies with Laravel-style dynamic lookups.
///
/// Policies can be registered explicitly or discovered by naming convention:
/// - `User` model → `UserPolicy`
/// - `Post` model → `PostPolicy`
///
/// ## Usage
///
/// Register policies explicitly:
///
/// ```dart
/// PolicyRegistry.register<Post>(PostPolicy());
/// PolicyRegistry.register<User>(UserPolicy());
/// ```
///
/// Authorize actions:
///
/// ```dart
/// final canView = await PolicyRegistry.authorize('view', currentUser, post);
/// final canCreate = await PolicyRegistry.authorize('create', currentUser, Post.empty());
/// ```
class PolicyRegistry {
  /// Registered policies by model type.
  static final Map<Type, Policy> _policies = {};

  /// Convention-based policy factories.
  /// Maps model type name to policy factory function.
  static final Map<String, Policy Function()> _policyFactories = {};

  /// Default policy to use when no policy is found.
  /// Defaults to [AllowAllPolicy] (allows all actions).
  static Policy Function() _defaultPolicyFactory = AllowAllPolicy.new;

  /// Registers a policy for a specific model type.
  ///
  /// ```dart
  /// PolicyRegistry.register<Post>(PostPolicy());
  /// ```
  static void register<T extends Model>(Policy<T> policy) {
    _policies[T] = policy;
  }

  /// Registers a policy factory for convention-based lookup.
  ///
  /// Use this to register policies by model name when the type isn't
  /// available at registration time.
  ///
  /// ```dart
  /// PolicyRegistry.registerFactory('Post', () => PostPolicy());
  /// ```
  static void registerFactory(String modelTypeName, Policy Function() factory) {
    _policyFactories[modelTypeName] = factory;
  }

  /// Sets the default policy factory used when no policy is found.
  ///
  /// ```dart
  /// // Deny all by default (more secure)
  /// PolicyRegistry.setDefaultPolicy(() => DenyAllPolicy());
  ///
  /// // Allow all by default (less secure, but simpler for development)
  /// PolicyRegistry.setDefaultPolicy(() => AllowAllPolicy());
  /// ```
  static void setDefaultPolicy(Policy Function() factory) {
    _defaultPolicyFactory = factory;
  }

  /// Gets the policy for a model type.
  ///
  /// Lookup order:
  /// 1. Explicitly registered policy for the type
  /// 2. Convention-based factory by model type name
  /// 3. Default policy
  static Policy<T> forModel<T extends Model>([T? model]) {
    // First check explicitly registered policies
    if (_policies.containsKey(T)) {
      return _policies[T]! as Policy<T>;
    }

    // Try convention-based lookup by type name
    final typeName = T.toString();
    if (_policyFactories.containsKey(typeName)) {
      final policy = _policyFactories[typeName]!();
      // Cache for future lookups
      _policies[T] = policy;
      return policy as Policy<T>;
    }

    // If we have a model instance, try using its runtime type
    if (model != null) {
      final runtimeTypeName = model.runtimeType.toString();
      if (_policyFactories.containsKey(runtimeTypeName)) {
        final policy = _policyFactories[runtimeTypeName]!();
        _policies[T] = policy;
        return policy as Policy<T>;
      }
    }

    // Fall back to default policy - create a typed version
    // We use a wrapper that delegates to the default policy
    return _TypedPolicyWrapper<T>(_defaultPolicyFactory());
  }

  /// Authorizes an action against a model using its policy.
  ///
  /// ```dart
  /// if (await PolicyRegistry.authorize('update', user, post)) {
  ///   // User can update this post
  /// }
  /// ```
  ///
  /// For actions that don't require a model instance (like `create` or `viewAny`):
  ///
  /// ```dart
  /// if (await PolicyRegistry.authorize<Post>('create', user)) {
  ///   // User can create posts
  /// }
  /// ```
  static Future<bool> authorize<T extends Model>(String ability, Model? user, [T? model]) async {
    final policy = forModel<T>(model);
    return policy.authorize(ability, user, model);
  }

  /// Checks if the user can view any models of this type.
  static Future<bool> canViewAny<T extends Model>(Model? user) {
    return authorize<T>('viewAny', user);
  }

  /// Checks if the user can view a specific model.
  static Future<bool> canView<T extends Model>(Model? user, T model) {
    return authorize<T>('view', user, model);
  }

  /// Checks if the user can create a new model.
  static Future<bool> canCreate<T extends Model>(Model? user) {
    return authorize<T>('create', user);
  }

  /// Checks if the user can update the given model.
  static Future<bool> canUpdate<T extends Model>(Model? user, T model) {
    return authorize<T>('update', user, model);
  }

  /// Checks if the user can delete the given model.
  static Future<bool> canDelete<T extends Model>(Model? user, T model) {
    return authorize<T>('delete', user, model);
  }

  /// Checks if the user can restore a soft-deleted model.
  static Future<bool> canRestore<T extends Model>(Model? user, T model) {
    return authorize<T>('restore', user, model);
  }

  /// Checks if the user can force delete the given model.
  static Future<bool> canForceDelete<T extends Model>(Model? user, T model) {
    return authorize<T>('forceDelete', user, model);
  }

  /// Clears all registered policies.
  ///
  /// Useful for testing.
  static void clear() {
    _policies.clear();
    _policyFactories.clear();
    _defaultPolicyFactory = AllowAllPolicy.new;
  }
}

/// A typed policy wrapper that delegates to an untyped policy.
///
/// This allows the default policy (which may be `AllowAllPolicy<Model>`)
/// to work with any specific model type.
class _TypedPolicyWrapper<T extends Model> extends Policy<T> {
  final Policy _delegate;

  _TypedPolicyWrapper(this._delegate);

  @override
  Future<bool?> before(Model? user, String ability) => _delegate.before(user, ability);

  @override
  Future<bool> viewAny(Model? user) => _delegate.viewAny(user);

  @override
  Future<bool> view(Model? user, T model) => _delegate.view(user, model);

  @override
  Future<bool> create(Model? user) => _delegate.create(user);

  @override
  Future<bool> update(Model? user, T model) => _delegate.update(user, model);

  @override
  Future<bool> delete(Model? user, T model) => _delegate.delete(user, model);

  @override
  Future<bool> restore(Model? user, T model) => _delegate.restore(user, model);

  @override
  Future<bool> forceDelete(Model? user, T model) => _delegate.forceDelete(user, model);
}
