import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/ai_repository.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final AiRepository aiRepository;

  ChatCubit({
    required this.aiRepository,
    // scheduleRepository is now used internally by AiRepository, not needed here explicitly
    // unless we want to listen to changes, but typically we just send messages.
  }) : super(ChatInitial());

  List<ChatMessage> _messages = [];

  void sendMessage(String text) async {
    // Optimistic UI update
    _messages = List.from(_messages)
      ..add(ChatMessage(text: text, isUser: true));
    emit(ChatLoaded(_messages));

    try {
      // The AiRepository now handles the context and tool execution loop internally.
      // It returns the final natural language response.
      final responseText = await aiRepository.sendMessage(text);

      _messages = List.from(_messages)
        ..add(ChatMessage(text: responseText, isUser: false));
      emit(ChatLoaded(_messages));
    } catch (e, stack) {
      print('Cubit Error: $e');
      print(stack);
      _messages = List.from(_messages)
        ..add(ChatMessage(text: "[Error] $e", isUser: false));
      emit(ChatLoaded(_messages));
    }
  }
}
