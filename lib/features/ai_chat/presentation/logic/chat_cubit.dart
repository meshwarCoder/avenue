import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../ai/ai_orchestrator/ai_orchestrator.dart';
import 'chat_state.dart';
import 'chat_session_cubit.dart';

class ChatCubit extends Cubit<ChatState> {
  final AiOrchestrator aiOrchestrator;
  final ChatSessionCubit? sessionCubit;

  ChatCubit({required this.aiOrchestrator, this.sessionCubit})
    : super(ChatInitial()) {
    // Ensure we start with a clean AI state when the Cubit is created
    aiOrchestrator.clearHistory();
  }

  List<ChatMessage> _messages = [];

  void sendMessage(String text) async {
    // Optimistic UI update
    _messages = List.from(_messages)
      ..add(ChatMessage(text: text, isUser: true));
    emit(ChatLoaded(_messages));

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
      emit(ChatLoaded(_messages));

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
      emit(ChatLoaded(_messages));
    }
  }

  void confirmAllActions(int messageIndex) async {
    try {
      // 1. Optimistic UI update: Mark as executed immediately so buttons disappear
      final message = _messages[messageIndex];
      final actions = message.suggestedActions ?? [];

      if (actions.isEmpty) return;

      final updatedMessages = List<ChatMessage>.from(_messages);
      updatedMessages[messageIndex] = message.copyWith(isExecuted: true);
      _messages = updatedMessages;
      emit(ChatLoaded(List.from(_messages)));

      // 2. Perform the actual execution for all actions
      for (final action in actions) {
        await aiOrchestrator.confirmAndExecute(action);
      }

      // 3. Add success message
      final successText = actions.length == 1
          ? "Action executed successfully!"
          : "${actions.length} actions executed successfully!";

      _messages = List.from(_messages)
        ..add(ChatMessage(text: successText, isUser: false));
      emit(ChatLoaded(_messages));

      // Save success message to Supabase
      await sessionCubit?.saveMessage('ai', successText);

      // Update session state
      sessionCubit?.updateMessages(_messages);
    } catch (e) {
      print('Execution Error: $e');
      _messages = List.from(_messages)
        ..add(ChatMessage(text: "Error executing action: $e", isUser: false));
      emit(ChatLoaded(_messages));
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
    final history = contextMessages.map((msg) {
      return {
        'role': msg.isUser ? 'user' : 'model',
        'parts': [
          {'text': msg.text},
        ],
      };
    }).toList();

    aiOrchestrator.loadHistory(history);
    emit(ChatLoaded(_messages));
  }

  // Reset for new chat
  void reset() {
    _messages = [];
    aiOrchestrator.clearHistory();
    emit(ChatLoaded(_messages));
  }
}
