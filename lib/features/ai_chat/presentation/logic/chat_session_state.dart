import 'package:equatable/equatable.dart';
import '../../data/models/chat_model.dart';
import '../../../ai_chat/presentation/logic/chat_state.dart';

abstract class ChatSessionState extends Equatable {
  const ChatSessionState();

  @override
  List<Object?> get props => [];
}

class ChatSessionInitial extends ChatSessionState {}

class ChatSessionLoading extends ChatSessionState {}

class ChatSessionLoaded extends ChatSessionState {
  final String currentChatId;
  final List<ChatMessage> messages;
  final List<ChatModel> chatList;

  const ChatSessionLoaded({
    required this.currentChatId,
    required this.messages,
    required this.chatList,
  });

  @override
  List<Object?> get props => [currentChatId, messages, chatList];

  ChatSessionLoaded copyWith({
    String? currentChatId,
    List<ChatMessage>? messages,
    List<ChatModel>? chatList,
  }) {
    return ChatSessionLoaded(
      currentChatId: currentChatId ?? this.currentChatId,
      messages: messages ?? this.messages,
      chatList: chatList ?? this.chatList,
    );
  }
}

class ChatSessionError extends ChatSessionState {
  final String message;

  const ChatSessionError(this.message);

  @override
  List<Object?> get props => [message];
}
