import 'package:dash/dash.dart';
import 'package:dash_example/models/post.dart';

/// Resource for managing blog posts in the admin panel.
class PostResource extends Resource<Post> {
  @override
  String? get navigationGroup => 'Content';

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
              .toggleable(isToggledHiddenByDefault: true),
        ])
        .defaultSort('created_at', 'desc')
        .searchPlaceholder('Search posts...');
  }

  @override
  FormSchema<Post> form(FormSchema<Post> form) {
    return form.fields([
      Section.make(
        'Post Details',
      ).description('Basic information about the blog post').icon('document-text').collapsible().columns(2).schema([
        TextInput.make('title') //
            .minLength(3)
            .maxLength(200)
            .label('Post Title')
            .placeholder('Enter post title')
            .required()
            .columnSpanFull(),

        Textarea.make('content') //
            .rows(8)
            .label('Content')
            .placeholder('Write your post content here...')
            .required()
            .columnSpanFull(),
      ]),

      Section.make(
        'Publishing Options',
      ).description('Control when and how your post is published').icon('calendar').collapsible().columns(2).schema([
        Select.make('status') //
            .options([
              const SelectOption('draft', 'Draft'),
              const SelectOption('published', 'Published'),
              const SelectOption('archived', 'Archived'),
            ])
            .label('Status')
            .required(),

        DatePicker.make('published_at') //
            .withTime()
            .label('Publish Date'),
      ]),
    ]);
  }
}
