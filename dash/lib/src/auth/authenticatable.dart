import 'package:bcrypt/bcrypt.dart';
import 'package:dash/src/model/model.dart';

/// Mixin that enables a [Model] to be used for authentication.
///
/// Models that implement this mixin can be used with [AuthService] for
/// user authentication, session management, and access control.
///
/// The mixin provides methods to:
/// - Get the unique identifier (e.g., email) for login
/// - Get the password hash for verification
/// - Get the display name for UI presentation
/// - Control panel access
///
/// Example usage in a generated model:
/// ```dart
/// class User extends Model with Authenticatable {
///   String email;
///   String password;
///   String name;
///
///   @override
///   String getAuthIdentifier() => email;
///
///   @override
///   String getAuthPassword() => password;
///
///   @override
///   String getDisplayName() => name;
/// }
/// ```
mixin Authenticatable on Model {
  /// Returns the unique identifier used for authentication (e.g., email).
  ///
  /// This value is used to look up the user during login.
  String getAuthIdentifier();

  /// Returns the name of the field used as the auth identifier.
  ///
  /// Used by [AuthService] to query the database for users.
  /// Defaults to 'email' but can be overridden for custom identifier fields.
  String getAuthIdentifierName() => 'email';

  /// Returns the hashed password for this user.
  ///
  /// The password should already be hashed using bcrypt.
  /// Use [setPassword] to hash and set a plain-text password.
  String getAuthPassword();

  /// Returns the display name for this user.
  ///
  /// Used in the UI to show the current user's name.
  String getDisplayName();

  /// Determines if this user can access the given panel.
  ///
  /// Override this method to implement custom access control logic,
  /// such as checking roles, permissions, or account status.
  ///
  /// Returns `true` by default, allowing access to all authenticated users.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// bool canAccessPanel(String panelId) {
  ///   return role == 'admin' || role == 'editor';
  /// }
  /// ```
  bool canAccessPanel(String panelId) => true;

  /// Hashes and sets the password for this user.
  ///
  /// This is a convenience method that hashes the plain-text password
  /// using bcrypt before storing it. Override [setAuthPassword] to
  /// set the actual field value.
  ///
  /// [plainPassword] - The plain text password to hash and store
  /// [rounds] - The bcrypt cost factor (default: 12)
  void setPassword(String plainPassword, {int rounds = 12}) {
    final hash = BCrypt.hashpw(plainPassword, BCrypt.gensalt(logRounds: rounds));
    setAuthPassword(hash);
  }

  /// Sets the hashed password value on the model.
  ///
  /// This method should be overridden to set the actual password field.
  /// It is called by [setPassword] after hashing.
  void setAuthPassword(String hash);
}
