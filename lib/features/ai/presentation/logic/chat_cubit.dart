import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:avenue/features/schdules/data/models/task_model.dart';
import 'package:avenue/features/schdules/data/models/default_task_model.dart';
import 'package:avenue/features/ai/ai/ai_action_models.dart';
import '../../ai/ai_orchestrator.dart';
import 'chat_state.dart';
import 'chat_session_cubit.dart';

import 'package:avenue/features/schdules/presentation/cubit/task_cubit.dart';

class ChatCubit extends Cubit<ChatState> {
  final AiOrchestrator aiOrchestrator;
  final ChatSessionCubit? sessionCubit;
  final TaskCubit? taskCubit;

  ChatCubit({required this.aiOrchestrator, this.sessionCubit, this.taskCubit})
    : super(ChatInitial()) {
    // Ensure we start with a clean AI state when the Cubit is created
    aiOrchestrator.clearHistory();
  }

  List<ChatMessage> _messages = [];

  void sendMessage(String text) async {
    // Optimistic UI update
    _messages = List.from(_messages)
      ..add(ChatMessage(text: text, isUser: true));
    emit(ChatLoaded(_messages, updatedAt: DateTime.now()));

    // Create chat if this is the first message
    final isFirstMessage = _messages.length == 1;
    if (isFirstMessage) {
      await sessionCubit?.createChatOnFirstMessage();
    }

    // Save user message to Supabase
    await sessionCubit?.saveMessage('user', text);

    try {
      final (responseText, actions, suggestedTitle) = await aiOrchestrator
          .processUserMessage(text);

      _messages = List.from(_messages)
        ..add(
          ChatMessage(
            text: responseText,
            isUser: false,
            suggestedActions: actions.isEmpty ? null : actions,
          ),
        );
      emit(ChatLoaded(_messages, updatedAt: DateTime.now()));

      // [Fix: Double Truth]
      // If the AI performed actions, force the TaskCubit (Single Source of Truth) to reload.
      // This ensures the UI reflects the actual DB state, not just the AI's claim.
      if (actions.isNotEmpty) {
        print("ChatCubit: AI performed actions. Triggering TaskCubit reload.");
        taskCubit?.loadTasks(force: true);
        // Also trigger future tasks reload if we are potentially affecting them
        // taskCubit?.loadFutureTasks(); // Optimistically calling loadTasks handles local date usually
      }

      // Save AI response to Supabase
      await sessionCubit?.saveMessage('ai', responseText);

      // Update chat title if this is the first AI response and we have a suggested title
      if (isFirstMessage &&
          suggestedTitle != null &&
          suggestedTitle.isNotEmpty) {
        await sessionCubit?.updateTitleFromAi(suggestedTitle);
      }

      // Update session state with new messages
      sessionCubit?.updateMessages(_messages);
    } catch (e) {
      print('Cubit Error: $e');
      _messages = List.from(_messages)
        ..add(ChatMessage(text: "[Error] $e", isUser: false));
      emit(ChatLoaded(_messages, updatedAt: DateTime.now()));
    }
  }

  // Execute actions when user confirms
  void confirmAllActions(int messageIndex) async {
    if (messageIndex < 0 || messageIndex >= _messages.length) return;

    final msg = _messages[messageIndex];
    if (msg.suggestedActions == null || msg.isExecuted || taskCubit == null)
      return;

    // 1. OPTIMISTIC UPDATE: Mark as executed immediately to provide instant UI feedback
    final updatedMsg = msg.copyWith(isExecuted: true);
    _messages[messageIndex] = updatedMsg;
    emit(ChatLoaded(List.from(_messages), updatedAt: DateTime.now()));

    // Update session state immediately so the "isExecuted" state persists locally
    sessionCubit?.updateMessages(_messages);

    print(
      'ChatCubit: Starting execution for message $messageIndex. TaskCubit: ${taskCubit.hashCode}',
    );

    // 2. Execute each action
    for (final action in msg.suggestedActions!) {
      await _executeAction(action);
    }

    // 3. Force Global UI Reload
    // Ensure the TaskCubit (shared singleton) refreshes its data for the relevant date.
    DateTime? reloadDate;
    if (msg.suggestedActions != null && msg.suggestedActions!.isNotEmpty) {
      final first = msg.suggestedActions!.first;
      if (first is CreateTaskAction) {
        reloadDate = first.date;
      } else if (first is UpdateTaskAction) {
        reloadDate = first.date;
      }
    }

    print(
      'ChatCubit: Execution finished. Triggering TaskCubit reload for date: $reloadDate',
    );
    await taskCubit?.loadTasks(date: reloadDate, force: true);
  }

  Future<void> _executeAction(AiAction action) async {
    try {
      if (action is CreateTaskAction) {
        final date = action.date;
        final startTime = _parseRelativeTime(date, action.startTime);
        final endTime = _parseRelativeTime(
          date,
          action.endTime,
          isEndTime: true,
          startTime: startTime,
        );

        final task = TaskModel(
          id: const Uuid().v4(), // Generate real ID here
          name: action.name,
          taskDate: date,
          startTime: startTime,
          endTime: endTime,
          importanceType: action.importance,
          desc: action.note ?? '',
          completed: false,
          category: 'General',
          isDeleted: false,
          serverUpdatedAt: DateTime.now(),
        );
        print(
          'ChatCubit: Executing addTask for ${task.name} at ${task.startTime} - ${task.endTime}',
        );
        await taskCubit!.addTask(task);
      } else if (action is UpdateTaskAction) {
        // For update, we need the existing task ideally to merge,
        // but TaskCubit.updateTask might handle merge or we send what we have.
        // TaskCubit.updateTask takes a TaskModel. We can't partial update easily without fetching.
        // Strategy: We can't easily fetch here without being async and complex.
        // Assuming AI provides critical fields.
        // Better Strategy: TaskCubit doesn't expose 'partialUpdate'.
        // We really should fetch the task first.
        // However, generic 'UpdateTaskAction' from AI usually has the ID.
        // Let's rely on TaskCubit to handle it or fetching it via repository if possible.
        // Since we injected TaskCubit, we don't have direct repo access easily unless we expose it.
        // Let's SKIP update for now or implement "Fetch-Update-Save".
        // Actually, let's try to fetch via TaskCubit if possible? No.

        // WORKAROUND: We assume the user creates tasks mostly.
        // For updates, we might need a distinct method in TaskCubit or expose repo.
        // Let's leave Update as TODO or Try Best Effort if we had full model.
        // Given constraint: "User wants AI to execute on confirm".
        // If I skip Update, it's broken.
        // I'll try to implement a basic fetch using the repository from Orchestrator logic?
        // ChatCubit has aiOrchestrator -> DefaultScheduleRepository.
        // We can use aiOrchestrator._repository (private).
        // Let's use `taskCubit.repository`. Check if TaskCubit exposes repository.
        // It does! `final ScheduleRepository repository;` in TaskCubit.

        final repo = taskCubit!.repository;
        final result = await repo.getTaskById(action.id);
        result.fold((l) => print('Task not found'), (existing) async {
          if (existing == null) return;
          final updated = existing.copyWith(
            name: action.name,
            completed: action.isDone,
            // Partial updates for time/date logic
            taskDate: action.date ?? existing.taskDate,
            startTime: action.startTime != null
                ? _parseRelativeTime(
                    action.date ?? existing.taskDate,
                    action.startTime,
                  )
                : existing.startTime,
            endTime: action.endTime != null
                ? _parseRelativeTime(
                    action.date ?? existing.taskDate,
                    action.endTime,
                  )
                : existing.endTime,
            importanceType: action.importance ?? existing.importanceType,
            desc: action.note ?? existing.desc,
            serverUpdatedAt: DateTime.now(),
          );
          await taskCubit!.updateTask(updated);
        });
      } else if (action is DeleteTaskAction) {
        await taskCubit!.deleteTask(action.id);
      } else if (action is CreateDefaultTaskAction) {
        final task = DefaultTaskModel(
          id: const Uuid().v4(),
          name: action.name,
          startTime: _parseTimeOfDay(action.startTime),
          endTime: _parseTimeOfDay(action.endTime),
          category: 'General',
          weekdays: action.weekdays,
          importanceType: action.importance,
          desc: action.note ?? '',
          serverUpdatedAt: DateTime.now(),
        );
        await taskCubit!.addDefaultTask(task);
      } else if (action is UpdateDefaultTaskAction) {
        final repo = taskCubit!.repository;
        final result = await repo.getDefaultTaskById(action.id);
        result.fold((l) => print('Default Task not found'), (existing) async {
          if (existing == null) return;
          final updated = existing.copyWith(
            name: action.name ?? existing.name,
            startTime: action.startTime != null
                ? _parseTimeOfDay(action.startTime!)
                : existing.startTime,
            endTime: action.endTime != null
                ? _parseTimeOfDay(action.endTime!)
                : existing.endTime,
            weekdays: action.weekdays ?? existing.weekdays,
            importanceType: action.importance ?? existing.importanceType,
            desc: action.note ?? existing.desc,
            serverUpdatedAt: DateTime.now(),
          );
          await taskCubit!.updateDefaultTask(updated);
        });
      } else if (action is DeleteDefaultTaskAction) {
        await taskCubit!.deleteDefaultTask(action.id);
      } else if (action is UnknownAction) {
        print('ChatCubit: Skipping unknown action: ${action.rawResponse}');
      }
    } catch (e) {
      print('Error executing confirmed action: $e');
    }
  }

  // Helpers copied/adapted from AiToolExecutor
  DateTime? _parseRelativeTime(
    DateTime date,
    String? timeStr, {
    bool isEndTime = false,
    DateTime? startTime,
  }) {
    if (timeStr == null || timeStr.isEmpty) return null;
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      var targetDate = date;
      // If end time is 00:00 and start time was late (e.g. 23:00), it likely means next day
      if (isEndTime &&
          hour == 0 &&
          minute == 0 &&
          startTime != null &&
          startTime.hour >= 18) {
        targetDate = date.add(const Duration(days: 1));
      }

      return DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
        hour,
        minute,
      );
    } catch (e) {
      return null;
    }
  }

  // Need TimeOfDay for DefaultTasks
  TimeOfDay _parseTimeOfDay(String timeStr) {
    try {
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return const TimeOfDay(hour: 9, minute: 0); // Fallback
    }
  }

  // Constant for AI context window
  static const int MAX_AI_HISTORY_MESSAGES = 12;

  // Load messages from session (when switching chats) and restore AI context
  void loadMessages(List<ChatMessage> messages) {
    _messages = messages; // Keep full history for UI

    // 1. Context Window Strategy: Take only the last N messages
    final int startIndex = (messages.length > MAX_AI_HISTORY_MESSAGES)
        ? (messages.length - MAX_AI_HISTORY_MESSAGES)
        : 0;

    final contextMessages = messages.sublist(startIndex);

    // 2. Restore AI History context from the window only
    // 2. Restore AI History context from the window only
    final history = contextMessages.expand((msg) {
      // 2a. Reconstruct User Message
      if (msg.isUser) {
        return [
          {
            'role': 'user',
            'parts': [
              {'text': msg.text},
            ],
          },
        ];
      }

      // 2b. Reconstruct Model Message (potentially with Tool Execution history)
      final List<Map<String, dynamic>> reconstructedSteps = [];

      // If the message has actions that were executed/suggested, we can hint at them.
      // Note: We don't have the original functionCall args or functionResponse here
      // because they weren't saved to DB.
      // However, we can inject the FINAL text response which is usuallly sufficient
      // if it describes the action.

      // "Lobotomized Restore" Fix Strategy:
      // Since we lack the raw function data, we rely on the text content being
      // descriptive enough for the model to "remember" what it did.
      // To strictly fix "discards functionCall", we would need DB schema changes.
      // For now, we ensure the text is labeled as 'model'.

      // IMPROVEMENT: If we had a mechanism to store 'tool' metadata in ChatMessage,
      // we would use it here. Current best effort:
      reconstructedSteps.add({
        'role': 'model',
        'parts': [
          {'text': msg.text},
        ],
      });

      return reconstructedSteps;
    }).toList();

    aiOrchestrator.loadHistory(history);
    emit(ChatLoaded(_messages, updatedAt: DateTime.now()));
  }

  // Reset for new chat
  void reset() {
    _messages = [];
    aiOrchestrator.clearHistory();
    emit(ChatLoaded(_messages, updatedAt: DateTime.now()));
  }
}
