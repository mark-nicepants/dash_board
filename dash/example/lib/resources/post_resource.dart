import 'package:dash/dash.dart';
import 'package:dash_example/models/post.dart';

/// Resource for managing blog posts in the admin panel.
class PostResource extends Resource<Post> {
  @override
  String? get navigationGroup => 'Content';

  @override
  int get navigationSort => 2;

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

          TextColumn.make('slug') //
              .label('Slug')
              .searchable()
              .toggleable(isToggledHiddenByDefault: true),

          TextColumn.make('author.name') //
              .label('Author')
              .sortable()
              .width('100px'),

          BooleanColumn.make('is_published') //
              .label('Published')
              .sortable()
              .toggleable(),

          TextColumn.make('published_at') //
              .dateTime()
              .label('Published At')
              .sortable()
              .toggleable(isToggledHiddenByDefault: true),

          TextColumn.make('created_at') //
              .dateTime()
              .sortable()
              .label('Created')
              .toggleable(isToggledHiddenByDefault: true),
        ])
        .bulkActions([DeleteAction<Post>('posts')])
        .defaultSort('created_at', 'desc')
        .searchPlaceholder('Search posts...');
  }

  @override
  FormSchema<Post> form(FormSchema<Post> form) {
    return form.fields([
      Section.make('Post Details') //
          .description('Basic information about the blog post')
          .icon('document-text')
          .collapsible()
          .columns(2)
          .schema([
            TextInput.make('title') //
                .minLength(1)
                .maxLength(255)
                .label('Post Title')
                .placeholder('Enter post title')
                .required()
                .columnSpanFull(),

            TextInput.make('slug') //
                .label('Slug')
                .placeholder('post-url-slug')
                .helperText('URL-friendly identifier (lowercase letters, numbers, and hyphens only)')
                .required()
                .columnSpanFull(),

            Textarea.make('content') //
                .rows(8)
                .label('Content')
                .placeholder('Write your post content here...')
                .columnSpanFull(),
          ]),

      Section.make(
        'Publishing Options',
      ).description('Control when and how your post is published').icon('calendar').collapsible().columns(2).schema([
        Toggle.make('is_published') //
            .label('Published')
            .helperText('When enabled, this post will be visible to the public')
            .defaultValue(false),

        DatePicker.make('published_at') //
            .withTime()
            .label('Publish Date'),
      ]),
    ]);
  }
}
