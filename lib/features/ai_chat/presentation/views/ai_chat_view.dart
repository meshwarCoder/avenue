import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../core/di/injection_container.dart';
import '../logic/chat_cubit.dart';
import '../logic/chat_state.dart';
import '../../../ai/ai_orchestrator/ai_action_models.dart';

class AiChatView extends StatelessWidget {
  const AiChatView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ChatCubit>(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('AI Assistant'),
          backgroundColor: const Color(0xFF004D61),
          foregroundColor: Colors.white,
        ),
        body: Column(
          children: [
            Expanded(
              child: BlocBuilder<ChatCubit, ChatState>(
                builder: (context, state) {
                  List<ChatMessage> messages = [];
                  if (state is ChatLoaded) {
                    messages = state.messages;
                  }

                  if (messages.isEmpty && state is! ChatError) {
                    return const Center(
                      child: Text(
                        'Hi! I can help you manage your tasks.\nTry "Add a meeting tomorrow at 10am"',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      return Align(
                        alignment: msg.isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: msg.isUser
                                ? const Color(0xFF004D61)
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.8,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              msg.isUser
                                  ? Text(
                                      msg.text,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    )
                                  : MarkdownBody(
                                      data: msg.text,
                                      styleSheet: MarkdownStyleSheet(
                                        p: const TextStyle(
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                              if (msg.suggestedActions != null &&
                                  !msg.isExecuted)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Wrap(
                                    spacing: 8,
                                    children: msg.suggestedActions!.map((
                                      action,
                                    ) {
                                      return ElevatedButton(
                                        onPressed: () => context
                                            .read<ChatCubit>()
                                            .confirmAction(index, action),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF004D61,
                                          ),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          textStyle: const TextStyle(
                                            fontSize: 12,
                                          ),
                                        ),
                                        child: Text(
                                          action.when(
                                            createTask:
                                                (
                                                  name,
                                                  date,
                                                  startTime,
                                                  endTime,
                                                  importance,
                                                  note,
                                                ) => 'Create "$name"',
                                            updateTask:
                                                (
                                                  id,
                                                  name,
                                                  date,
                                                  startTime,
                                                  endTime,
                                                  importance,
                                                  note,
                                                  isDone,
                                                ) => 'Update Task',
                                            deleteTask: (id) => 'Delete Task',
                                            reorderDay: (date, ids) =>
                                                'Reorder Day',
                                            updateSettings:
                                                (theme, lang, notify) =>
                                                    'Update Settings',
                                            unknown: (_) => 'Unknown',
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              if (msg.isExecuted)
                                const Padding(
                                  padding: EdgeInsets.only(top: 8),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 16,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Executed',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const _ChatInput(),
          ],
        ),
      ),
    );
  }
}

class _ChatInput extends StatefulWidget {
  const _ChatInput();

  @override
  State<_ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<_ChatInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Color(0xFF004D61)),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    context.read<ChatCubit>().sendMessage(text);
    _controller.clear();
    _focusNode.requestFocus();
  }
}
