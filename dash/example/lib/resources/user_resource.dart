import 'package:dash/dash.dart';
import 'package:dash_example/actions/deactivate_user_handler.dart';
import 'package:dash_example/models/user.dart';

/// Resource for managing users in the admin panel.
///
/// This resource demonstrates various Action capabilities:
/// - Basic actions (View, Edit, Delete)
/// - Custom action handlers for server-side logic
/// - Actions with confirmation modals
/// - Actions with form fields
/// - Conditional visibility based on record state
/// - Custom modal icons and colors
class UserResource extends Resource<User> {
  @override
  Heroicon get iconComponent => const Heroicon(HeroIcons.userGroup);

  @override
  String? get navigationGroup => 'Administration';

  @override
  int get navigationSort => 1;

  @override
  Table<User> table(Table<User> table) {
    return table
        .columns([
          TextColumn.make('id') //
              .label('ID')
              .sortable()
              .width('80px'),

          ImageColumn.make('avatar') //
              .label('')
              .circular()
              .size(40)
              .disk('public')
              .width('60px'),

          TextColumn.make('name') //
              .searchable()
              .sortable()
              .grow()
              .toggleable(),

          TextColumn.make('email') //
              .searchable()
              .sortable()
              .grow()
              .toggleable(),

          TextColumn.make('role') //
              .label('Role')
              .sortable()
              .toggleable(),

          BooleanColumn.make('is_active') //
              .label('Active')
              .sortable()
              .clickable()
              .toggleable(),

          TextColumn.make('created_at') //
              .dateTime()
              .label('Joined')
              .sortable()
              .toggleable(isToggledHiddenByDefault: true),
        ])
        .defaultSort('name')
        .searchPlaceholder('Search users...')
        // Row actions - showcasing various action capabilities
        .actions([
          // Standard navigation actions
          ViewAction.make<User>(),
          EditAction.make<User>(),

          // Action with custom handler and conditional visibility
          // Only shown when user is active - demonstrates .visible() and custom handlers
          Action.make<User>('deactivate')
              .label('Deactivate')
              .icon(HeroIcons.noSymbol)
              .color(ActionColor.warning)
              .handler(DeactivateUserHandler())
              .requiresConfirmation()
              .confirmationHeading('Deactivate User?')
              .confirmationDescription('This will prevent the user from logging in. You can reactivate them later.')
              .confirmationButtonLabel('Deactivate')
              .modalIcon(HeroIcons.noSymbol)
              .modalIconColor(ActionColor.warning)
              .visible((user) => user.isActive == true),

          // Activate action - only shown when user is inactive
          // Demonstrates opposite conditional visibility
          Action.make<User>('activate')
              .label('Activate')
              .icon(HeroIcons.checkCircle)
              .color(ActionColor.success)
              .handler(ActivateUserHandler())
              .visible((user) => user.isActive != true),

          // Action with form fields - opens a modal with form inputs
          // Demonstrates .schema() for adding form fields to action modals
          Action.make<User>('changeRole')
              .label('Role')
              .icon(HeroIcons.userCircle)
              .color(ActionColor.info)
              .handler(ChangeRoleHandler())
              .schema([
                Select.make('role')
                    .label('New Role')
                    .options([
                      const SelectOption('admin', 'Admin'),
                      const SelectOption('user', 'User'),
                      const SelectOption('guest', 'Guest'),
                    ])
                    .required()
                    .helperText('Select the new role for this user'),
              ])
              .fillForm((user) => {'role': user.role})
              .confirmationHeading('Change User Role')
              .confirmationButtonLabel('Change Role')
              .modalSize(ModalSize.sm),

          // Action that sends notification
          // Demonstrates info-style modal with custom icon
          Action.make<User>('resetPassword')
              .label('')
              .hiddenLabel()
              .icon(HeroIcons.key)
              .tooltip('Reset Password')
              .color(ActionColor.secondary)
              .handler(ResetPasswordHandler())
              .requiresConfirmation()
              .confirmationHeading('Send Password Reset?')
              .confirmationDescription('A password reset email will be sent to the user.')
              .confirmationButtonLabel('Send Email')
              .modalIcon(HeroIcons.envelopeOpen)
              .modalIconColor(ActionColor.info),

          // Standard delete action with confirmation
          DeleteAction.make<User>('user'),
        ]);
  }

  // Header actions for the index page - override to customize
  @override
  List<Action<User>> indexHeaderActions() => [
    CreateAction.make(singularLabel),
    // You can add more header actions here, e.g.:
    // Action.make<User>('export')
    //   .label('Export')
    //   .icon(HeroIcons.arrowDownTray)
    //   .color(ActionColor.secondary),
  ];

  // Form actions - override to customize the submit/cancel buttons
  @override
  List<Action<User>> formActions(FormOperation operation) => [
    SaveAction.make(operation: operation),
    CancelAction.make(),
    // You can add more form actions here, e.g.:
    // if (operation == FormOperation.edit)
    //   Action.make<User>('preview')
    //     .label('Preview')
    //     .color(ActionColor.info),
  ];

  @override
  FormSchema<User> form(FormSchema<User> form) {
    return form.columns(2).fields([
      FileUpload.make('avatar') //
          .label('Avatar')
          .avatar()
          .disk('public')
          .directory('avatars')
          .maxSize(2048) // 2MB
          .columnSpanFull(),

      TextInput.make('name') //
          .label('Full Name')
          .placeholder('Enter full name')
          .minLength(2)
          .maxLength(255)
          .required()
          .columnSpanFull(),
      TextInput.make('email') //
          .email()
          .placeholder('user@example.com')
          .required(),

      TextInput.make('password') //
          .password()
          .label('Password')
          .placeholder('Enter password')
          .minLength(8)
          .required(),

      Select.make('role') //
          .label('User Role')
          .options([
            const SelectOption('admin', 'Admin'),
            const SelectOption('user', 'User'),
            const SelectOption('guest', 'Guest'),
          ])
          .required(),

      Toggle.make('is_active') //
          .label('Active')
          .helperText('Whether this user can access the system')
          .defaultValue(true),
    ]);
  }
}
