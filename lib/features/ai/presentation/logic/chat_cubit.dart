import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:avenue/features/schdules/data/models/task_model.dart';
import 'package:avenue/features/schdules/data/models/default_task_model.dart';
import 'package:avenue/features/ai/ai/ai_action_models.dart';
import '../../ai/ai_orchestrator.dart';
import '../logic/chat_state.dart';
import '../logic/chat_session_cubit.dart';
import '../../data/repositories/chat_repository.dart';

import 'package:avenue/features/schdules/presentation/cubit/task_cubit.dart';
import '../../../../core/utils/observability.dart';

class ChatCubit extends Cubit<ChatState> {
  final AiOrchestrator aiOrchestrator;
  final ChatRepository chatRepository;
  final ChatSessionCubit? sessionCubit;
  final TaskCubit? taskCubit;

  ChatCubit({
    required this.aiOrchestrator,
    required this.chatRepository,
    this.sessionCubit,
    this.taskCubit,
  }) : super(ChatInitial()) {
    // Ensure we start with a clean AI state when the Cubit is created
    aiOrchestrator.clearHistory();
  }

  List<ChatMessage> _messages = [];

  void _logState(ChatState state, {String? traceId}) {
    if (isClosed) return;
    AvenueLogger.log(
      event: 'STATE_CHAT_UPDATED',
      layer: LoggerLayer.STATE,
      traceId: traceId,
      payload: {'state': state.runtimeType.toString()},
    );
    emit(state);
  }

  void sendMessage(String text) async {
    final tid = const Uuid().v4().substring(0, 8);
    AvenueLogger.log(
      event: 'UI_SEND_MESSAGE_CLICKED',
      layer: LoggerLayer.UI,
      traceId: tid,
      payload: {'text': text},
    );

    // Optimistic UI update
    _messages = List.from(_messages)
      ..add(ChatMessage(text: text, isUser: true));
    _logState(
      ChatLoaded(_messages, updatedAt: DateTime.now(), isTyping: true),
      traceId: tid,
    );

    // Create chat if this is the first message
    final isFirstMessage = _messages.length == 1;
    if (isFirstMessage) {
      await sessionCubit?.createChatOnFirstMessage();
    }

    // Save user message to Supabase
    await sessionCubit?.saveMessage('user', text);

    try {
      final (responseText, actions, suggestedTitle) = await aiOrchestrator
          .processUserMessage(text, traceId: tid);

      _messages = List.from(_messages)
        ..add(
          ChatMessage(
            text: responseText,
            isUser: false,
            suggestedActions: actions.isEmpty ? null : actions,
          ),
        );

      // Save pending actions locally so they persist across sessions
      if (actions.isNotEmpty && sessionCubit?.currentChatId != null) {
        await chatRepository.savePendingActions(
          sessionCubit!.currentChatId!,
          responseText,
          actions,
        );
      }

      _logState(
        ChatLoaded(_messages, updatedAt: DateTime.now(), isTyping: false),
        traceId: tid,
      );

      // [Fix: Double Truth]
      // If the AI performed actions, force the TaskCubit (Single Source of Truth) to reload.
      // This ensures the UI reflects the actual DB state, not just the AI's claim.
      if (actions.isNotEmpty) {
        AvenueLogger.log(
          event: 'CHAT_RELOAD_TRIGGERED',
          layer: LoggerLayer.UI,
          traceId: tid,
        );
        taskCubit?.loadTasks(force: true);
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
      AvenueLogger.log(
        event: 'CHAT_ERROR',
        level: LoggerLevel.ERROR,
        layer: LoggerLayer.UI,
        traceId: tid,
        payload: e.toString(),
      );
      _messages = List.from(_messages)
        ..add(ChatMessage(text: "[Error] $e", isUser: false));
      _logState(
        ChatLoaded(_messages, updatedAt: DateTime.now(), isTyping: false),
        traceId: tid,
      );
    }
  }

  // Execute actions when user confirms
  void confirmAllActions(int messageIndex) async {
    final tid = const Uuid().v4().substring(0, 8);
    AvenueLogger.log(
      event: 'UI_CONFIRM_CLICKED',
      layer: LoggerLayer.UI,
      traceId: tid,
      payload: {'messageIndex': messageIndex},
    );
    if (messageIndex < 0 || messageIndex >= _messages.length) return;

    final msg = _messages[messageIndex];
    if (msg.suggestedActions == null || msg.isExecuted || taskCubit == null)
      return;

    // 1. OPTIMISTIC UPDATE: Mark as executed immediately to provide instant UI feedback
    final updatedMsg = msg.copyWith(isExecuted: true);
    _messages[messageIndex] = updatedMsg;
    _logState(
      ChatLoaded(List.from(_messages), updatedAt: DateTime.now()),
      traceId: tid,
    );

    // Update session state immediately so the "isExecuted" state persists locally
    sessionCubit?.updateMessages(_messages);

    AvenueLogger.log(
      event: 'CHAT_EXECUTION_STARTED',
      layer: LoggerLayer.UI,
      traceId: tid,
      payload: {'messageIndex': messageIndex},
    );

    // 2. Execute each action
    final actionSummaries = <String>[];
    for (final action in msg.suggestedActions!) {
      await _executeAction(action, traceId: tid);
      if (action is TaskAction) {
        actionSummaries.add(
          "${action.action == 'create' ? 'Created' : 'Updated'} task '${action.name}'",
        );
      } else if (action is HabitAction) {
        actionSummaries.add(
          "${action.action == 'create' ? 'Created' : 'Updated'} habit '${action.name}'",
        );
      } else if (action is SkipHabitInstanceAction) {
        actionSummaries.add("Skipped habit instance");
      }
    }

    // 3. Cleanup local pending actions
    if (sessionCubit?.currentChatId != null) {
      await chatRepository.deletePendingActions(
        sessionCubit!.currentChatId!,
        msg.text,
      );
    }

    // 4. Record confirmation in history (Supabase + local)
    final summaryText = "✅ Actions confirmed: ${actionSummaries.join(', ')}";
    if (sessionCubit?.currentChatId != null) {
      await sessionCubit!.saveMessage('ai', summaryText);

      // Update local state by adding the "audit" message
      _messages = List.from(_messages)
        ..add(ChatMessage(text: summaryText, isUser: false));
      _logState(ChatLoaded(_messages, updatedAt: DateTime.now()));
      sessionCubit!.updateMessages(_messages);
    }

    // 5. Force Global UI Reload
    // Capture original date to restore it after action reload
    final originalDate = taskCubit?.selectedDate;

    // Ensure the TaskCubit (shared singleton) refreshes its data for the relevant date.
    DateTime? reloadDate;
    if (msg.suggestedActions != null && msg.suggestedActions!.isNotEmpty) {
      final first = msg.suggestedActions!.first;
      if (first is TaskAction) {
        reloadDate = first.date;
      } else if (first is SkipHabitInstanceAction) {
        reloadDate = first.date;
      }
    }

    AvenueLogger.log(
      event: 'CHAT_EXECUTION_FINISHED',
      layer: LoggerLayer.UI,
      traceId: tid,
      payload: {
        'reloadDate': reloadDate.toString(),
        'restoringOriginalDate': originalDate.toString(),
      },
    );

    // First reload the date affected by the action (ensures DB is in sync)
    await taskCubit?.loadTasks(date: reloadDate, force: true);

    // Then RESTORE the original viewing date so the background UI doesn't glitch/shift
    if (originalDate != null && originalDate != reloadDate) {
      await taskCubit?.loadTasks(date: originalDate, force: true);
    }
  }

  Future<void> _executeAction(AiAction action, {String? traceId}) async {
    try {
      if (action is TaskAction) {
        if (action.action == 'create') {
          final date = action.date ?? DateTime.now();
          final startTime = _parseRelativeTime(date, action.startTime);
          final endTime = _parseRelativeTime(
            date,
            action.endTime,
            isEndTime: true,
            startTime: startTime,
          );

          final task = TaskModel(
            id: const Uuid().v4(),
            name: action.name ?? 'Untitled Task',
            taskDate: date,
            startTime: startTime,
            endTime: endTime,
            importanceType: action.importance ?? 'Medium',
            desc: action.note ?? '',
            completed: false,
            category: action.category ?? 'Other',
            isDeleted: false,
            defaultTaskId: action.defaultTaskId,
          );
          await taskCubit!.addTask(task, traceId: traceId);
        } else if (action.action == 'update' && action.id != null) {
          final repo = taskCubit!.repository;
          final result = await repo.getTaskById(action.id!);
          result.fold((l) => null, (existing) async {
            if (existing == null) return;
            final updated = existing.copyWith(
              name: action.name ?? existing.name,
              completed: action.isDone ?? existing.completed,
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
              category: action.category ?? existing.category,
              isDeleted: action.isDeleted ?? existing.isDeleted,
            );
            await taskCubit!.updateTask(updated, traceId: traceId);
          });
        }
      } else if (action is HabitAction) {
        if (action.action == 'create') {
          final task = DefaultTaskModel(
            id: const Uuid().v4(),
            name: action.name ?? 'Untitled Habit',
            startTime: _parseTimeOfDay(action.startTime ?? "09:00"),
            endTime: _parseTimeOfDay(action.endTime ?? "10:00"),
            category: action.category ?? 'Other',
            weekdays: action.weekdays ?? [1, 2, 3, 4, 5],
            importanceType: action.importance ?? 'Medium',
            desc: action.note ?? '',
          );
          await taskCubit!.addDefaultTask(task, traceId: traceId);
        } else if (action.action == 'update' && action.id != null) {
          final repo = taskCubit!.repository;
          final result = await repo.getDefaultTaskById(action.id!);
          result.fold((l) => null, (existing) async {
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
              category: action.category ?? existing.category,
              isDeleted: action.isDeleted ?? existing.isDeleted,
            );
            await taskCubit!.updateDefaultTask(updated);
          });
        }
      } else if (action is SkipHabitInstanceAction) {
        final repo = taskCubit!.repository;
        final result = await repo.getDefaultTaskById(action.id);
        result.fold((l) => null, (existing) async {
          if (existing == null) return;
          final normalizedDate = DateTime(
            action.date.year,
            action.date.month,
            action.date.day,
          );
          if (!existing.hideOn.any(
            (d) =>
                d.year == normalizedDate.year &&
                d.month == normalizedDate.month &&
                d.day == normalizedDate.day,
          )) {
            final updated = existing.copyWith(
              hideOn: [...existing.hideOn, normalizedDate],
            );
            await taskCubit!.updateDefaultTask(updated);
          }
        });
      }
    } catch (e) {
      AvenueLogger.log(
        event: 'CHAT_EXECUTE_ERROR',
        level: LoggerLevel.ERROR,
        layer: LoggerLayer.UI,
        traceId: traceId,
        payload: e.toString(),
      );
    }
  }

  // Helpers
  DateTime? _parseRelativeTime(
    DateTime date,
    String? timeStr, {
    bool isEndTime = false,
    DateTime? startTime,
  }) {
    try {
      if (isEndTime &&
          (timeStr == null || timeStr.isEmpty) &&
          startTime != null) {
        return startTime.add(const Duration(hours: 1));
      }
      if (timeStr == null || timeStr.isEmpty) return null;
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      var targetDate = date;
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

  TimeOfDay _parseTimeOfDay(String timeStr) {
    try {
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  static const int MAX_AI_HISTORY_MESSAGES = 12;

  void loadMessages(List<ChatMessage> messages) {
    _messages = messages;
    final int startIndex = (messages.length > MAX_AI_HISTORY_MESSAGES)
        ? (messages.length - MAX_AI_HISTORY_MESSAGES)
        : 0;
    final contextMessages = messages.sublist(startIndex);
    final history = contextMessages.expand((msg) {
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
      return [
        {
          'role': 'model',
          'parts': [
            {'text': msg.text},
          ],
        },
      ];
    }).toList();
    aiOrchestrator.loadHistory(history);
    _logState(ChatLoaded(_messages, updatedAt: DateTime.now()));
  }

  void reset() {
    _messages = [];
    aiOrchestrator.clearHistory();
    _logState(ChatLoaded(_messages, updatedAt: DateTime.now()));
  }
}
