import 'package:dash/dash.dart';

import '../models/user.dart';

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
              .sortable<TextColumn>()
              .toggleable<TextColumn>(isToggledHiddenByDefault: true),
        ])
        .defaultSort('name')
        .searchPlaceholder('Search users...');
  }
}
