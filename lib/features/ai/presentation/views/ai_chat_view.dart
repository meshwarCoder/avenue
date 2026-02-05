import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avenue/core/utils/constants.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../core/di/injection_container.dart';
import '../logic/chat_cubit.dart';
import '../logic/chat_state.dart';
import '../logic/chat_session_cubit.dart';
import '../logic/chat_session_state.dart';
import '../../ai/ai_action_models.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart' as auth_state;

class AiChatView extends StatelessWidget {
  const AiChatView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, auth_state.AuthState>(
      builder: (context, authState) {
        if (authState is! auth_state.Authenticated) {
          return const Scaffold(body: Center(child: Text('Please log in')));
        }

        return MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) =>
                  ChatSessionCubit(repository: sl(), userId: authState.userId)
                    ..initialize(),
            ),
            BlocProvider(
              create: (context) => ChatCubit(
                aiOrchestrator: sl(),
                sessionCubit: context.read<ChatSessionCubit>(),
                taskCubit: sl(),
              ),
            ),
          ],
          child: const _ChatScreen(),
        );
      },
    );
  }
}

class _ChatScreen extends StatefulWidget {
  const _ChatScreen();

  @override
  State<_ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<_ChatScreen> {
  String? _lastChatId;
  bool _isSwitching = false;
  final Set<int> _notifiedMessageIndexes = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MultiBlocListener(
      listeners: [
        BlocListener<ChatSessionCubit, ChatSessionState>(
          listener: (context, sessionState) {
            if (sessionState is ChatSessionLoaded) {
              // If the chatId changed, we are transitioning to a different chat
              if (sessionState.currentChatId != _lastChatId) {
                final oldId = _lastChatId;
                _lastChatId = sessionState.currentChatId;
                _notifiedMessageIndexes.clear(); // Reset on switch

                // CRITICAL FIX: Only load messages if we are explicitly switching.
                if (oldId != null &&
                    oldId.isEmpty &&
                    sessionState.currentChatId.isNotEmpty &&
                    !_isSwitching) {
                  return;
                }

                // Normal switching (e.g. from Drawer) or loading first chat
                context.read<ChatCubit>().loadMessages(sessionState.messages);
                _isSwitching = false; // Reset flag
              }
            }
          },
        ),
        BlocListener<ChatCubit, ChatState>(
          listener: (context, state) {
            if (state is ChatLoaded) {
              final messages = state.messages;
              for (int i = 0; i < messages.length; i++) {
                final m = messages[i];
                if (!m.isUser &&
                    m.isExecuted &&
                    !_notifiedMessageIndexes.contains(i)) {
                  _notifiedMessageIndexes.add(i);

                  // Extract date for better feedback if available
                  String dateStr = "بنجاح";
                  if (m.suggestedActions != null &&
                      m.suggestedActions!.isNotEmpty) {
                    final firstAction = m.suggestedActions!.first;
                    if (firstAction is CreateTaskAction) {
                      final d = firstAction.date;
                      dateStr = "ليوم ${d.day}/${d.month}";
                    }
                  }

                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 8),
                          Text('تم التنفيذ $dateStr!'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('AI Assistant'),
          backgroundColor: Colors.transparent,
          foregroundColor: theme.colorScheme.onSurface,
          elevation: 0,
          actions: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  context.read<ChatSessionCubit>().loadChats();
                  Scaffold.of(context).openEndDrawer();
                },
              ),
            ),
          ],
        ),
        endDrawer: _ChatDrawer(
          onSwitch: () {
            _isSwitching = true;
          },
        ),
        body: Column(
          children: [
            Expanded(
              child: BlocBuilder<ChatCubit, ChatState>(
                builder: (context, state) {
                  List<ChatMessage> messages = [];
                  if (state is ChatLoaded) messages = state.messages;

                  if (messages.isEmpty && state is! ChatError) {
                    return _buildEmptyState(theme, isDark);
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 24,
                    ),
                    reverse: false,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      return TweenAnimationBuilder<double>(
                        key: ValueKey(
                          msg.text +
                              index.toString() +
                              msg.isExecuted.toString(),
                        ),
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: Opacity(
                              opacity: value,
                              child: _buildMessageBubble(
                                context,
                                msg,
                                index,
                                theme,
                                isDark,
                              ),
                            ),
                          );
                        },
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

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : AppColors.deepPurple.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 48,
              color: isDark ? Colors.white70 : AppColors.deepPurple,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'How can I help you today?',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.deepPurple,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Try "Plan my week" or "Add a gym session every Monday at 6pm"',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.slatePurple.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    ChatMessage msg,
    int index,
    ThemeData theme,
    bool isDark,
  ) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: msg.isUser ? AppColors.deepPurple : theme.cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(msg.isUser ? 20 : 4),
            bottomRight: Radius.circular(msg.isUser ? 4 : 20),
          ),
          boxShadow: [
            if (!msg.isUser)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (msg.isUser)
              Text(
                msg.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              )
            else
              MarkdownBody(
                data: msg.text,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 15,
                    height: 1.4,
                  ),
                  strong: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            if (msg.suggestedActions != null && !msg.isExecuted) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      context.read<ChatCubit>().confirmAllActions(index),
                  icon: const Icon(Icons.done_all_rounded, size: 18),
                  label: Text(
                    msg.suggestedActions!.length == 1
                        ? 'Confirm Action'
                        : 'Confirm All (${msg.suggestedActions!.length})',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.salmonPink,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ] else if (msg.isExecuted) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: Colors.green,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'تم التنفيذ بنجاح',
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
            ],
          ],
        ),
      ),
    );
  }
}

// TODO: This drawer will be connected to Supabase chat tables later
class _ChatDrawer extends StatelessWidget {
  final VoidCallback onSwitch;
  const _ChatDrawer({required this.onSwitch});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      child: BlocBuilder<ChatSessionCubit, ChatSessionState>(
        builder: (context, state) {
          final chatList = state is ChatSessionLoaded ? state.chatList : [];
          final currentChatId = state is ChatSessionLoaded
              ? state.currentChatId
              : null;

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: AppColors.deepPurple),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'AI Assistant',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Your personal task manager',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('New Chat'),
                onTap: () {
                  onSwitch();
                  context.read<ChatSessionCubit>().createNewChat();
                  context.read<ChatCubit>().reset();
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              ...chatList.map((chat) {
                final isActive = chat.id == currentChatId;
                return ListTile(
                  leading: Icon(
                    Icons.chat,
                    color: isActive ? theme.colorScheme.primary : null,
                  ),
                  title: Text(
                    chat.title,
                    style: TextStyle(
                      fontWeight: isActive
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isActive ? theme.colorScheme.primary : null,
                    ),
                  ),
                  subtitle: Text(_formatDate(chat.createdAt)),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'rename') {
                        _showRenameDialog(context, chat.id, chat.title);
                      } else if (value == 'delete') {
                        _showDeleteDialog(context, chat.id);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'rename',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Rename'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  selected: isActive,
                  onTap: () {
                    if (!isActive) {
                      onSwitch();
                      context.read<ChatSessionCubit>().switchToChat(chat.id);
                    }
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          );
        },
      ),
    );
  }

  void _showRenameDialog(
    BuildContext context,
    String chatId,
    String currentTitle,
  ) {
    final controller = TextEditingController(text: currentTitle);
    final sessionCubit = context.read<ChatSessionCubit>();

    showDialog(
      context: context,
      builder: (context) => BlocProvider.value(
        value: sessionCubit,
        child: Builder(
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Rename Chat'),
              content: TextField(
                controller: controller,
                decoration: const InputDecoration(hintText: 'Enter new title'),
                autofocus: true,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final newTitle = controller.text.trim();
                    if (newTitle.isNotEmpty) {
                      sessionCubit.renameChat(chatId, newTitle);
                    }
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String chatId) {
    final sessionCubit = context.read<ChatSessionCubit>();

    showDialog(
      context: context,
      builder: (context) => BlocProvider.value(
        value: sessionCubit,
        child: Builder(
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Delete Chat'),
              content: const Text(
                'Are you sure you want to delete this chat? This action cannot be undone.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    sessionCubit.deleteChat(chatId);
                    Navigator.pop(dialogContext);
                  },
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
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
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(28),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                decoration: const InputDecoration(
                  hintText: 'Message Assistant...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(fontSize: 15),
                ),
                style: const TextStyle(fontSize: 15),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.deepPurple,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_upward_rounded,
                color: Colors.white,
              ),
            ),
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
