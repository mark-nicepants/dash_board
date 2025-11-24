import 'package:dash/dash.dart';

import '../models/post.dart';

/// Resource for managing blog posts in the admin panel.
class PostResource extends Resource<Post> {
  @override
  Type get model => Post;

  @override
  String? get navigationGroup => 'Content';

  @override
  Post newModelInstance() => Post();

  @override
  Table<Post> table(Table<Post> table) {
    return table
        .columns([
          TextColumn.make('id') //
              .label('ID')
              .sortable()
              .width('80px'),

          TextColumn.make('title') //
              .searchable()
              .sortable()
              .grow(),

          TextColumn.make('user_id') //
              .label('Author ID')
              .sortable()
              .width('100px'),

          TextColumn.make('created_at') //
              .dateTime()
              .sortable()
              .label('Created')
              .toggleable<TextColumn>(isToggledHiddenByDefault: true),
        ])
        .defaultSort('created_at', 'desc')
        .searchPlaceholder('Search posts...');
  }
}
