import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/schdules/data/models/task_model.dart';
import '../../../../features/schdules/domain/repo/schedule_repository.dart';
import '../../data/ai_repository.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final AiRepository aiRepository;
  final ScheduleRepository scheduleRepository;

  ChatCubit({required this.aiRepository, required this.scheduleRepository})
    : super(ChatInitial());

  List<ChatMessage> _messages = [];

  void sendMessage(String text) async {
    // Optimistic UI update
    _messages = List.from(_messages)
      ..add(ChatMessage(text: text, isUser: true));
    emit(ChatLoaded(_messages)); // Show user message immediately

    // We don't want to show loading spinner over the whole chat, ideally just a "typing..." indicator.
    // But for MVP, let's keep it simple. If we emit ChatLoading it might wipe the list if not handled in UI.
    // So we'll just emit the new list with user message, and maybe append a loading placeholder if needed.
    // For now, let's just wait for the response.

    try {
      // 1. Fetch current tasks for context
      // We grab all tasks for today + future to give context?
      // Or just today? Let's try getting today's tasks.
      final tasksResult = await scheduleRepository.getFutureTasks(
        DateTime.now().subtract(const Duration(days: 1)),
      );
      // Using getFutureTasks from yesterday to include today.
      // Ideally we need getTasksByDate for specific dates, but "context" usually implies upcoming stuff.

      List<TaskModel> tasks = [];
      tasksResult.fold(
        (failure) => print('Failed to fetch context: ${failure.message}'),
        (t) => tasks = t,
      );

      // 2. Send to AI
      final aiResponse = await aiRepository.sendMessage(text, tasks);

      // 3. Process Actions
      for (final action in aiResponse.actions) {
        await _processAction(action);
      }

      // 4. Add AI Response
      _messages = List.from(_messages)
        ..add(ChatMessage(text: aiResponse.message, isUser: false));
      emit(ChatLoaded(_messages));
    } catch (e) {
      _messages = List.from(_messages)
        ..add(ChatMessage(text: "Error: $e", isUser: false));
      emit(ChatLoaded(_messages));
    }
  }

  Future<void> _processAction(AiAction action) async {
    try {
      if (action.type == 'add' && action.data != null) {
        // We need to parse the data into a TaskModel
        // Since TaskModel.fromSupabaseJson expects specific keys, we might need to adapt.
        // Or create a new factory.
        // Let's use the fromSupabaseJson map structure since our prompt output mimics it close enough?
        // Actually, let's just map manually to be safe.

        // AI returns "task_date" as string, TaskModel expects DateTime object relative to now?
        // TaskModel.fromMap/SupabaseJson handles string parsing.

        final task = TaskModel.fromMap(
          action.data!,
        ); // relying on fromMap to handle the keys
        await scheduleRepository.addTask(task);
      } else if (action.type == 'update' && action.data != null) {
        final task = TaskModel.fromMap(action.data!);
        await scheduleRepository.updateTask(task);
      } else if (action.type == 'delete' && action.id != null) {
        await scheduleRepository.deleteTask(action.id!);
      }
    } catch (e) {
      print('Failed to execute action ${action.type}: $e');
      _messages.add(
        ChatMessage(
          text: "[System] Failed to execute ${action.type}: $e",
          isUser: false,
        ),
      );
    }
  }
}
