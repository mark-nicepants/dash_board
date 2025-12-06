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

          // Standard delete action with confirmation
          DeleteAction.make<User>('user'),
        ]);
  }

  // Header actions for the index page - override to customize
  @override
  List<Action<User>> indexHeaderActions() => [
    CreateAction.make(singularLabel),
    // You can add more header actions here, e.g.:
    Action.make<User>('export').label('Export').icon(HeroIcons.arrowDownTray).color(ActionColor.secondary),
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
      Grid.make(2).schema([
        Grid.make(1).schema([
          Section.make() //
              .heading('General')
              .description('Information about the user')
              .schema([
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
              ]),

          Section.make() //
              .heading('Avatar')
              .description('Upload an avatar for the user')
              .collapsed()
              .schema([
                FileUpload.make('avatar') //
                    .label('Avatar')
                    .avatar()
                    .disk('public')
                    .directory('avatars')
                    .maxSize(2048) // 2MB
                    .columnSpanFull(),
              ]),
        ]),

        Grid.make(1).schema([
          Section.make() //
              .heading('Permissions')
              .description('Permissions for the user')
              .schema([
                Toggle.make('is_active') //
                    .label('Active')
                    .helperText('Whether this user can access the system')
                    .defaultValue(true),

                HasManySelect('roles') //
                    .label('Roles')
                    .helperText('Roles for the user'),

                HasManySelect('permissions') //
                    .label('Permissions')
                    .helperText('Permissions for the user'),
              ]),
        ]),
      ]),
    ]);
  }
}
