// GENERATED CODE - Customize as needed
// Resource for Tag

import 'package:dash/dash.dart';
import 'package:dash_example/models/tag.dart';

/// Resource for managing Tags in the admin panel.
class TagResource extends Resource<Tag> {
  @override
  Heroicon get iconComponent => const Heroicon(HeroIcons.tag);

  @override
  String? get navigationGroup => 'Content';

  @override
  int get navigationSort => 3;

  @override
  Table<Tag> table(Table<Tag> table) {
    return table.columns([
      TextColumn.make('id').label('ID').sortable().width('80px'),
      TextColumn.make('name').label('Name').searchable().sortable(),
      TextColumn.make('slug').label('Slug').searchable().sortable(),
      TextColumn.make('description').label('Description').searchable().sortable(),
    ]);
  }

  @override
  FormSchema<Tag> form(FormSchema<Tag> form) {
    return form.fields([
      TextInput.make('name').label('Name').required(),
      TextInput.make('slug').label('Slug').required(),
      TextInput.make('description').label('Description'),
    ]);
  }
}
