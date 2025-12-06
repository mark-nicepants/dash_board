// Resource for Role

import 'package:dash/dash.dart';

/// Resource for managing Roles in the admin panel.
class RoleResource extends Resource<Role> {
  @override
  String get label => 'Roles';

  @override
  String get singularLabel => 'Role';

  @override
  Heroicon get iconComponent => const Heroicon(HeroIcons.userGroup);

  @override
  Table<Role> table(Table<Role> table) {
    return table.columns([
      TextColumn.make('id').label('ID').sortable().width('80px'),
      TextColumn.make('name').label('Name').searchable().sortable(),
      TextColumn.make('slug').label('Slug').searchable().sortable(),
      TextColumn.make('description').label('Description').searchable(),
      BooleanColumn.make('is_default').label('Default').sortable(),
    ]);
  }

  @override
  FormSchema<Role> form(FormSchema<Role> form) {
    return form.fields([
      TextInput.make('name').label('Name').placeholder('e.g., Administrator').required(),
      TextInput.make(
        'slug',
      ).label('Slug').placeholder('e.g., admin').helperText('Unique identifier used in code').required(),
      Textarea.make('description').label('Description').placeholder('Describe the purpose of this role...'),
      Toggle.make('is_default').label('Default Role').helperText('New users will be assigned this role automatically'),
      HasManySelect.make('permissions')
          .relationship('permissions', 'Permission')
          .label('Permissions')
          .displayColumn('name')
          .valueColumn('id')
          .searchable()
          .preload(limit: 100)
          .helperText('Select the permissions granted to this role'),
    ]);
  }
}
