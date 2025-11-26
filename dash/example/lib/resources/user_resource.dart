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
          TextColumn.make('name') //
              .searchable()
              .sortable()
              .grow(),

          TextColumn.make('email') //
              .searchable()
              .sortable()
              .grow(),

          TextColumn.make('created_at') //
              .dateTime()
              .label('Joined')
              .sortable()
              .toggleable(isToggledHiddenByDefault: true),
        ])
        .defaultSort('name')
        .searchPlaceholder('Search users...');
  }

  @override
  FormSchema<User> form(FormSchema<User> form) {
    return form.columns(2).fields([
      TextInput.make('name') //
          .label<TextInput>('Full Name')
          .placeholder<TextInput>('Enter full name')
          .minLength(2)
          .required<TextInput>()
          .columnSpanFull<TextInput>(),
      TextInput.make('email') //
          .email()
          .placeholder<TextInput>('user@example.com')
          .required<TextInput>(),

      Select.make('role') //
          .label<Select>('User Role')
          .options([
            const SelectOption('user', 'User'),
            const SelectOption('admin', 'Administrator'),
            const SelectOption('moderator', 'Moderator'),
          ])
          .required<Select>(),
    ]);
  }
}
