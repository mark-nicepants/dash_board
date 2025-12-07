import 'package:dash_board/dash_board.dart';
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
              .clickable()
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
      Grid.make(3).schema([
        Section.make('Post Details') //
            .description('Basic information about the blog post')
            .icon('document-text')
            .collapsible()
            .columnSpan(2) // Takes 2 of 3 columns (larger)
            .columns(1)
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

        Section.make('Publishing Options') //
            .description('Control when and how your post is published')
            .icon('calendar')
            .collapsible()
            .columnSpan(1) // Takes 1 of 3 columns (smaller)
            .columns(1)
            .schema([
              RelationshipSelect.make(
                'author',
              ).label('Author').displayColumn('name').searchColumns(['name', 'email']).preload(limit: 10).required(),

              HasManySelect.make(
                'tags',
              ).label('Tags').displayColumn('name').preload(limit: 20).helperText('Select tags for this post'),

              Toggle.make('is_published') //
                  .label('Published')
                  .live()
                  .helperText('When enabled, this post will be visible to the public')
                  .defaultValue(false),

              DatePicker.make('published_at') //
                  .withTime()
                  .visibleWhen('is_published', equals: '1')
                  .label('Publish Date'),
            ]),
      ]),
    ]);
  }
}
