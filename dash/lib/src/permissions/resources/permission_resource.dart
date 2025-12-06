// Resource for Permission

import 'package:dash/dash.dart';

/// Resource for managing Permissions in the admin panel.
class PermissionResource extends Resource<Permission> {
  @override
  String get label => 'Permissions';

  @override
  String get singularLabel => 'Permission';

  @override
  Heroicon get iconComponent => const Heroicon(HeroIcons.key);

  @override
  Table<Permission> table(Table<Permission> table) {
    return table.columns([
      TextColumn.make('id').label('ID').sortable().width('80px'),
      TextColumn.make('name').label('Name').searchable().sortable(),
      TextColumn.make('slug').label('Slug').searchable().sortable(),
      TextColumn.make('description').label('Description').searchable(),
    ]);
  }

  @override
  FormSchema<Permission> form(FormSchema<Permission> form) {
    return form.fields([
      TextInput.make('name').label('Name').placeholder('e.g., Create Posts').required(),
      TextInput.make(
        'slug',
      ).label('Slug').placeholder('e.g., create_posts').helperText('Unique identifier used in code').required(),
      Textarea.make('description').label('Description').placeholder('Describe what this permission allows...'),
    ]);
  }
}
