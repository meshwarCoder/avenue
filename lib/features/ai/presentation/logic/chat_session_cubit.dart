import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/chat_repository.dart';
import 'chat_session_state.dart';
import 'chat_state.dart';
import '../../../../core/utils/observability.dart';

class ChatSessionCubit extends Cubit<ChatSessionState> {
  final ChatRepository _repository;
  final String _userId;

  ChatSessionCubit({required ChatRepository repository, required String userId})
    : _repository = repository,
      _userId = userId,
      super(ChatSessionInitial());

  // Initialize: Create a new chat automatically
  Future<void> initialize() async {
    try {
      AvenueLogger.log(
        event: 'CHAT_SESSION_INIT',
        layer: LoggerLayer.UI,
        payload: {'userId': _userId},
      );

      emit(ChatSessionLoading());

      // Load user's chats (don't create a new one)
      final chats = await _repository.getUserChats(_userId);
      if (isClosed) return;
      AvenueLogger.log(
        event: 'CHAT_SESSION_LOADED',
        layer: LoggerLayer.UI,
        payload: {'count': chats.length},
      );

      // Start with no active chat (will be created on first message)

      emit(ChatSessionLoaded(currentChatId: '', messages: [], chatList: chats));
    } catch (e) {
      if (isClosed) return;
      AvenueLogger.log(
        event: 'CHAT_SESSION_ERROR',
        level: LoggerLevel.ERROR,
        layer: LoggerLayer.UI,
        payload: e.toString(),
      );
      emit(ChatSessionError('Failed to initialize: $e'));
    }
  }

  // Create chat only when first message is sent
  Future<void> createChatOnFirstMessage() async {
    if (state is! ChatSessionLoaded) return;

    final currentState = state as ChatSessionLoaded;

    // Only create if we don't have a chat yet
    if (currentState.currentChatId.isEmpty) {
      try {
        AvenueLogger.log(event: 'CHAT_CREATE_START', layer: LoggerLayer.UI);
        final chatId = await _repository.createChat(_userId);
        if (isClosed) return;
        AvenueLogger.log(
          event: 'CHAT_CREATE_SUCCESS',
          layer: LoggerLayer.UI,
          payload: {'chatId': chatId},
        );

        final chats = await _repository.getUserChats(_userId);
        if (isClosed) return;
        emit(currentState.copyWith(currentChatId: chatId, chatList: chats));
      } catch (e) {
        if (isClosed) return;
        AvenueLogger.log(
          event: 'CHAT_CREATE_ERROR',
          level: LoggerLevel.ERROR,
          layer: LoggerLayer.UI,
          payload: e.toString(),
        );
      }
    }
  }

  // Load user's chats (for drawer)
  Future<void> loadChats() async {
    // Note: We don't check state type here mainly to allow initial load
    // but typically we want to be in Loaded state.

    try {
      final chats = await _repository.getUserChats(_userId);
      if (isClosed) return;

      if (state is ChatSessionLoaded) {
        final currentState = state as ChatSessionLoaded;
        emit(currentState.copyWith(chatList: chats));
      } else {
        // Fallback if not loaded yet (should rarely happen in this flow)
        emit(
          ChatSessionLoaded(currentChatId: '', messages: [], chatList: chats),
        );
      }
    } catch (e) {
      // Handle error gracefully
    }
  }

  // Switch to a different chat
  Future<void> switchToChat(String chatId) async {
    try {
      emit(ChatSessionLoading());

      // Load messages for this chat
      final messageModels = await _repository.getChatMessages(chatId);
      if (isClosed) return;

      // Convert to ChatMessage
      final messages = messageModels.map((m) {
        return ChatMessage(text: m.content, isUser: m.role == 'user');
      }).toList();

      // Load chats
      final chats = await _repository.getUserChats(_userId);
      if (isClosed) return;

      emit(
        ChatSessionLoaded(
          currentChatId: chatId,
          messages: messages,
          chatList: chats,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(ChatSessionError('Failed to switch chat: $e'));
    }
  }

  // Create a new empty chat (lazy creation)
  void createNewChat() {
    if (state is! ChatSessionLoaded) return;
    final currentState = state as ChatSessionLoaded;

    emit(currentState.copyWith(currentChatId: '', messages: []));
  }

  // Rename a chat
  Future<void> renameChat(String chatId, String newTitle) async {
    if (state is! ChatSessionLoaded) return;

    try {
      // 1. Persist to Supabase first
      await _repository.updateChatTitle(chatId, newTitle);
      if (isClosed) return;

      // 2. Refetch entire list from Supabase
      await loadChats();
    } catch (e) {
      if (isClosed) return;
      // Ensure we have latest data on error too
      await loadChats();
    }
  }

  // Delete a chat
  Future<void> deleteChat(String chatId) async {
    if (state is! ChatSessionLoaded) return;

    try {
      // 1. Persist to Supabase first
      await _repository.deleteChat(chatId);
      if (isClosed) return;
      AvenueLogger.log(event: 'CHAT_DELETE_SUCCESS', layer: LoggerLayer.UI);

      // 2. Refetch and handle current chat state
      final chats = await _repository.getUserChats(_userId);
      if (isClosed) return;
      final currentState = state as ChatSessionLoaded;

      if (currentState.currentChatId == chatId) {
        emit(
          currentState.copyWith(
            currentChatId: '',
            messages: [],
            chatList: chats,
          ),
        );
      } else {
        emit(currentState.copyWith(chatList: chats));
      }
    } catch (e) {
      if (isClosed) return;
      AvenueLogger.log(
        event: 'CHAT_DELETE_ERROR',
        level: LoggerLevel.ERROR,
        layer: LoggerLayer.UI,
        payload: e.toString(),
      );
      await loadChats();
    }
  }

  // Update chat title from AI suggestion
  Future<void> updateTitleFromAi(String suggestedTitle) async {
    if (state is! ChatSessionLoaded) return;
    final currentState = state as ChatSessionLoaded;

    // Source of Truth: Find the chat from the list we just fetched
    final currentChat = currentState.chatList.firstWhere(
      (chat) => chat.id == currentState.currentChatId,
      orElse: () => throw Exception('Current chat not found in list'),
    );

    // Only update if it's currently a default title
    if (currentChat.title == 'New Chat' ||
        currentChat.title == 'AI Assistant') {
      try {
        AvenueLogger.log(
          event: 'CHAT_RENAME_AI',
          layer: LoggerLayer.UI,
          payload: suggestedTitle,
        );
        // This will call renameChat which handles persistence + refetch
        await renameChat(currentState.currentChatId, suggestedTitle);
      } catch (e) {
        AvenueLogger.log(
          event: 'CHAT_RENAME_ERROR',
          level: LoggerLevel.WARN,
          layer: LoggerLayer.UI,
          payload: e.toString(),
        );
      }
    }
  }

  // Save a message to current chat
  Future<void> saveMessage(String role, String content) async {
    if (state is! ChatSessionLoaded) {
      AvenueLogger.log(
        event: 'CHAT_SAVE_SKIPPED',
        level: LoggerLevel.WARN,
        layer: LoggerLayer.UI,
        payload: 'State not Loaded',
      );
      return;
    }

    final currentState = state as ChatSessionLoaded;
    AvenueLogger.log(
      event: 'CHAT_SAVE_START',
      layer: LoggerLayer.UI,
      payload: {'role': role, 'chatId': currentState.currentChatId},
    );

    try {
      await _repository.saveMessage(
        chatId: currentState.currentChatId,
        role: role,
        content: content,
      );
      if (isClosed) return;
      AvenueLogger.log(event: 'CHAT_SAVE_SUCCESS', layer: LoggerLayer.UI);
    } catch (e) {
      if (isClosed) return;
      AvenueLogger.log(
        event: 'CHAT_SAVE_ERROR',
        level: LoggerLevel.ERROR,
        layer: LoggerLayer.UI,
        payload: e.toString(),
      );
    }
  }

  // Get AI history for current chat (for AiOrchestrator)
  List<Map<String, dynamic>> getAiHistory() {
    if (state is! ChatSessionLoaded) return [];

    final currentState = state as ChatSessionLoaded;
    final history = <Map<String, dynamic>>[];

    for (final message in currentState.messages) {
      history.add({
        'role': message.isUser ? 'user' : 'model',
        'parts': [
          {'text': message.text},
        ],
      });
    }

    return history;
  }

  // Update messages in state (called by ChatCubit)
  void updateMessages(List<ChatMessage> messages) {
    if (state is! ChatSessionLoaded) return;

    final currentState = state as ChatSessionLoaded;
    emit(currentState.copyWith(messages: messages));
  }

  String? get currentChatId {
    if (state is ChatSessionLoaded) {
      return (state as ChatSessionLoaded).currentChatId;
    }
    return null;
  }
}
