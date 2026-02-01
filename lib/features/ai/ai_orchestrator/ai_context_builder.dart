import '../../schdules/domain/repo/schedule_repository.dart';

class AiContextBuilder {
  final ScheduleRepository _scheduleRepository;

  AiContextBuilder(this._scheduleRepository);

  Future<String> buildContext() async {
    final now = DateTime.now();
    final todayTasksResult = await _scheduleRepository.getTasksByDate(now);

    final tasksSection = todayTasksResult.fold(
      (failure) => 'Error loading today\'s tasks.',
      (tasks) {
        if (tasks.isEmpty) return 'The user has no tasks for today.';
        final taskList = tasks
            .map(
              (t) =>
                  '- ${t.name} (Start: ${t.startTime ?? "N/A"}, End: ${t.endTime ?? "N/A"}, Desc: ${t.desc ?? ""}, ID: ${t.id})',
            )
            .join('\n');
        return 'Today\'s tasks:\n$taskList';
      },
    );

    return '''
Current Time: ${now.toIso8601String()}
User Context:
$tasksSection
''';
  }
}
