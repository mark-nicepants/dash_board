import 'package:dash_board/dash_board.dart';
import 'package:dash_example/models/user.dart';

/// Handler for deactivating a user account.
///
/// This demonstrates how to create a custom ActionHandler
/// that executes server-side logic when triggered.
class DeactivateUserHandler extends ActionHandler {
  @override
  String get name => 'deactivate';

  @override
  String? get description => 'Deactivates a user account, preventing them from logging in.';

  @override
  Future<ActionResult> handle(ActionContext context) async {
    final user = context.record as User;

    // Check if trying to deactivate the currently logged-in user
    final currentUser = RequestContext.user as User?;
    if (currentUser != null && currentUser.id == user.id) {
      return ActionResult.failure('You cannot deactivate your own account');
    }

    // Already deactivated?
    if (user.isActive != true) {
      return ActionResult.failure('User is already deactivated');
    }

    // Update the user's active status
    user.isActive = false;
    await user.save();

    return ActionResult.success('User "${user.name}" has been deactivated');
  }
}

/// Handler for activating a user account.
class ActivateUserHandler extends ActionHandler {
  @override
  String get name => 'activate';

  @override
  String? get description => 'Activates a user account, allowing them to log in.';

  @override
  Future<ActionResult> handle(ActionContext context) async {
    final user = context.record as User;

    // Already active?
    if (user.isActive == true) {
      return ActionResult.failure('User is already active');
    }

    // Update the user's active status
    user.isActive = true;
    await user.save();

    return ActionResult.success('User "${user.name}" has been activated');
  }
}

/// Handler for changing a user's role.
///
/// This demonstrates an action handler that uses form data
/// submitted by the user.
class ChangeRoleHandler extends ActionHandler {
  @override
  String get name => 'change-role';

  @override
  String? get description => 'Changes the role of a user.';

  @override
  Future<String?> validate(ActionContext context) async {
    final newRole = context.getString('role');
    if (newRole == null || newRole.isEmpty) {
      return 'Please select a role';
    }
    if (!['admin', 'user', 'guest'].contains(newRole)) {
      return 'Invalid role selected';
    }
    return null;
  }

  @override
  Future<ActionResult> handle(ActionContext context) async {
    final user = context.record as User;
    final newRole = context.getString('role')!;
    final oldRole = user.role;

    // Update the user's role
    user.role = newRole;
    await user.save();

    return ActionResult.success('Changed role from "$oldRole" to "$newRole" for "${user.name}"');
  }
}

/// Handler for resetting a user's password.
///
/// This demonstrates a handler that doesn't modify the record directly
/// but performs some other action.
class ResetPasswordHandler extends ActionHandler {
  @override
  String get name => 'reset-password';

  @override
  String? get description => 'Sends a password reset email to the user.';

  @override
  Future<ActionResult> handle(ActionContext context) async {
    final user = context.record as User;

    // In a real application, this would send an email
    // For demo purposes, we just return success
    // await emailService.sendPasswordResetEmail(user.email);

    return ActionResult.success('Password reset email sent to ${user.email}');
  }
}
