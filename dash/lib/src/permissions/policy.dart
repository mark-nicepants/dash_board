import 'package:dash/src/model/model.dart';

/// Base class for model policies.
///
/// Policies define authorization rules for specific model types.
/// They follow Laravel's policy pattern with dynamic lookups.
///
/// ## Usage
///
/// Create a policy for each model that needs authorization:
///
/// ```dart
/// class PostPolicy extends Policy<Post> {
///   @override
///   Future<bool> viewAny(Model? user) async => true;
///
///   @override
///   Future<bool> view(Model? user, Post model) async => true;
///
///   @override
///   Future<bool> create(Model? user) async {
///     if (user == null) return false;
///     return user is Authorizable && await user.can('create_posts');
///   }
///
///   @override
///   Future<bool> update(Model? user, Post model) async {
///     // Only the author can update their own posts
///     return model.authorId == user?.getKey();
///   }
///
///   @override
///   Future<bool> delete(Model? user, Post model) async {
///     if (user == null) return false;
///     return user is Authorizable && await user.can('delete_posts');
///   }
/// }
/// ```
///
/// Then register the policy:
///
/// ```dart
/// PolicyRegistry.register<Post>(PostPolicy());
/// ```
///
/// ## Naming Convention
///
/// If you follow the naming convention `{Model}Policy`, the policy will be
/// auto-discovered. For example:
/// - `User` model → `UserPolicy`
/// - `Post` model → `PostPolicy`
/// - `Comment` model → `CommentPolicy`
abstract class Policy<T extends Model> {
  /// Determines if all abilities should be granted to the user.
  ///
  /// Override this to implement a "super user" check. If this returns
  /// `true`, all other policy methods will automatically pass.
  ///
  /// Returns `null` to continue with normal checks, `true` to grant all,
  /// or `false` to deny all.
  Future<bool?> before(Model? user, String ability) async => null;

  /// Determines if the user can view any models of this type.
  ///
  /// This is typically used for index/list pages.
  Future<bool> viewAny(Model? user) async => true;

  /// Determines if the user can view a specific model.
  Future<bool> view(Model? user, T model) async => true;

  /// Determines if the user can create new models of this type.
  Future<bool> create(Model? user) async => true;

  /// Determines if the user can update the given model.
  Future<bool> update(Model? user, T model) async => true;

  /// Determines if the user can delete the given model.
  Future<bool> delete(Model? user, T model) async => true;

  /// Determines if the user can restore a soft-deleted model.
  Future<bool> restore(Model? user, T model) async => true;

  /// Determines if the user can permanently delete the model.
  Future<bool> forceDelete(Model? user, T model) async => true;

  /// Authorizes a specific ability against a model.
  ///
  /// This method handles the `before` check and dispatches to the
  /// appropriate policy method based on the ability name.
  Future<bool> authorize(String ability, Model? user, [T? model]) async {
    // Check the before hook
    final beforeResult = await before(user, ability);
    if (beforeResult != null) {
      return beforeResult;
    }

    // Dispatch to the appropriate method
    switch (ability) {
      case 'viewAny':
        return viewAny(user);
      case 'view':
        return model != null ? view(user, model) : false;
      case 'create':
        return create(user);
      case 'update':
        return model != null ? update(user, model) : false;
      case 'delete':
        return model != null ? delete(user, model) : false;
      case 'restore':
        return model != null ? restore(user, model) : false;
      case 'forceDelete':
        return model != null ? forceDelete(user, model) : false;
      default:
        // Unknown ability, deny by default
        return false;
    }
  }
}

/// A default policy that allows all actions.
///
/// Used when no policy is registered for a model type and no
/// convention-based policy is found.
class AllowAllPolicy<T extends Model> extends Policy<T> {}

/// A default policy that denies all actions.
///
/// Useful for models that should be locked down by default.
class DenyAllPolicy<T extends Model> extends Policy<T> {
  @override
  Future<bool> viewAny(Model? user) async => false;

  @override
  Future<bool> view(Model? user, T model) async => false;

  @override
  Future<bool> create(Model? user) async => false;

  @override
  Future<bool> update(Model? user, T model) async => false;

  @override
  Future<bool> delete(Model? user, T model) async => false;

  @override
  Future<bool> restore(Model? user, T model) async => false;

  @override
  Future<bool> forceDelete(Model? user, T model) async => false;
}
