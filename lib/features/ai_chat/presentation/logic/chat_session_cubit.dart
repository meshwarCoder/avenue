import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repository/chat_repository.dart';
import 'chat_session_state.dart';
import 'chat_state.dart';

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
      print('ChatSessionCubit: Starting initialization...');
      print('User ID: $_userId');

      emit(ChatSessionLoading());

      // Load user's chats (don't create a new one)
      print('Loading user chats...');
      final chats = await _repository.getUserChats(_userId);
      print('Loaded ${chats.length} chats');

      // Start with no active chat (will be created on first message)

      emit(ChatSessionLoaded(currentChatId: '', messages: [], chatList: chats));
      print('ChatSessionCubit initialized successfully!');
    } catch (e, stackTrace) {
      print('ChatSessionCubit initialization failed!');
      print('Error: $e');
      print('Stack trace: $stackTrace');
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
        print('Creating new chat on first message...');
        final chatId = await _repository.createChat(_userId);
        print('Chat created with ID: $chatId');

        final chats = await _repository.getUserChats(_userId);
        emit(currentState.copyWith(currentChatId: chatId, chatList: chats));
      } catch (e) {
        print('Error creating chat: $e');
      }
    }
  }

  // Load user's chats (for drawer)
  Future<void> loadChats() async {
    // Note: We don't check state type here mainly to allow initial load
    // but typically we want to be in Loaded state.

    try {
      final chats = await _repository.getUserChats(_userId);

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

      // Convert to ChatMessage
      final messages = messageModels.map((m) {
        return ChatMessage(text: m.content, isUser: m.role == 'user');
      }).toList();

      // Load chats
      final chats = await _repository.getUserChats(_userId);

      emit(
        ChatSessionLoaded(
          currentChatId: chatId,
          messages: messages,
          chatList: chats,
        ),
      );
    } catch (e) {
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

      // 2. Refetch entire list from Supabase
      await loadChats();
    } catch (e) {
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
      print('ChatSessionCubit: Chat deleted from Supabase');

      // 2. Refetch and handle current chat state
      final chats = await _repository.getUserChats(_userId);
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
      print('Error deleting chat: $e');
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
        print('Updating chat title from AI to: $suggestedTitle');
        // This will call renameChat which handles persistence + refetch
        await renameChat(currentState.currentChatId, suggestedTitle);
      } catch (e) {
        print('Error updating title from AI: $e');
      }
    }
  }

  // Save a message to current chat
  Future<void> saveMessage(String role, String content) async {
    if (state is! ChatSessionLoaded) {
      print('⚠️ Cannot save message: state is not ChatSessionLoaded');
      return;
    }

    final currentState = state as ChatSessionLoaded;
    print('🔵 Saving message to Supabase...');
    print('🔵 Chat ID: ${currentState.currentChatId}');
    print('🔵 Role: $role');
    print(
      '🔵 Content: ${content.substring(0, content.length > 50 ? 50 : content.length)}...',
    );

    try {
      await _repository.saveMessage(
        chatId: currentState.currentChatId,
        role: role,
        content: content,
      );
      print('✅ Message saved successfully!');
    } catch (e, stackTrace) {
      print('❌ Error saving message: $e');
      print('❌ Stack trace: $stackTrace');
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
