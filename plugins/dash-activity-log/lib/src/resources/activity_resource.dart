import 'package:dash_board/dash_board.dart';
import 'package:dash_activity_log/src/models/activity.dart';

/// Resource for managing activity log entries in the admin panel.
///
/// This resource provides a read-only view of all system activities
/// with search and filtering capabilities.
class ActivityResource extends Resource<Activity> {
  @override
  String get label => 'Activity Log';

  @override
  String get singularLabel => 'Activity';

  @override
  String get slug => 'activities';

  @override
  Activity get modelInstance => Activity();

  @override
  bool get shouldRegisterNavigation => false;

  @override
  Table<Activity> table(Table<Activity> table) {
    return table
        .columns([
          TextColumn.make('event').label('Event').searchable().sortable().state((record) => (record as Activity).event),
          TextColumn.make('subject_type').label('Subject').searchable().sortable().state((record) {
            final activity = record as Activity;
            return '${activity.subjectType} #${activity.subjectId ?? '-'}';
          }),
          TextColumn.make(
            'description',
          ).label('Description').searchable().state((record) => (record as Activity).getDescription()),
          TextColumn.make(
            'created_at',
          ).label('Time').sortable().state((record) => _formatTime((record as Activity).createdAt)),
        ])
        .actions([ViewAction.make<Activity>()])
        .defaultSort('created_at')
        .paginated(true)
        .recordsPerPage(25);
  }

  @override
  FormSchema<Activity> form(FormSchema<Activity> form) {
    // Activity log is read-only, but we need to define fields for viewing
    return form.fields([
      TextInput.make('event').label('Event').disabled(true),
      TextInput.make('subject_type').label('Subject Type').disabled(true),
      TextInput.make('subject_id').label('Subject ID').disabled(true),
      TextInput.make('causer_id').label('Caused By').disabled(true),
      Textarea.make('description').label('Description').disabled(true).rows(3),
      Textarea.make('properties').label('Properties (JSON)').disabled(true).rows(10),
      TextInput.make('created_at').label('Created At').disabled(true),
    ]);
  }

  @override
  List<Action<Activity>> indexHeaderActions() {
    // No create action for activity log - it's auto-populated
    return [];
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '-';
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    }
  }
}
