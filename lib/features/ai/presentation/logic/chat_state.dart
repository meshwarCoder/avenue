import 'package:equatable/equatable.dart';
import '../../ai/ai_action_models.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final List<ChatMessage> messages;
  final DateTime? updatedAt;

  const ChatLoaded(this.messages, {this.updatedAt});

  @override
  List<Object?> get props => [messages, updatedAt];
}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
}

class ChatMessage extends Equatable {
  final String text;
  final bool isUser;
  final List<AiAction>? suggestedActions;
  final bool isExecuted;

  const ChatMessage({
    required this.text,
    required this.isUser,
    this.suggestedActions,
    this.isExecuted = false,
  });

  ChatMessage copyWith({
    String? text,
    bool? isUser,
    List<AiAction>? suggestedActions,
    bool? isExecuted,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      suggestedActions: suggestedActions ?? this.suggestedActions,
      isExecuted: isExecuted ?? this.isExecuted,
    );
  }

  @override
  List<Object?> get props => [text, isUser, suggestedActions, isExecuted];
}
