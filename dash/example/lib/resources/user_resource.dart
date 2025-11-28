import 'package:dash/dash.dart';
import 'package:dash_example/models/user.dart';

/// Resource for managing users in the admin panel.
class UserResource extends Resource<User> {
  @override
  Heroicon get iconComponent => const Heroicon(HeroIcons.userGroup);

  @override
  String? get navigationGroup => 'Administration';

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
              .toggleable(),

          TextColumn.make('created_at') //
              .dateTime()
              .label('Joined')
              .sortable()
              .toggleable(isToggledHiddenByDefault: true),
        ])
        .defaultSort('name')
        .searchPlaceholder('Search users...')
        // Row actions - defaults shown for demonstration
        .actions([
          ViewAction.make(), //
          EditAction.make(),
          DeleteAction.make('user'),
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
