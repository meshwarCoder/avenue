import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/logic/app_connectivity_cubit.dart';
import '../../../../core/logic/app_connectivity_state.dart';
import '../../../../core/utils/constants.dart';
import '../logic/chat_cubit.dart';

/// Custom input widget for AI Chat that handles offline state.
///
/// Responsibilities:
/// - Listen to AppConnectivityCubit for connectivity changes
/// - Enable/disable input based on connection state
/// - Apply proper styling for offline state
/// - Handle message sending with validation
/// - Provide shake animation feedback on offline tap
class AiInputWidget extends StatefulWidget {
  const AiInputWidget({super.key});

  @override
  State<AiInputWidget> createState() => _AiInputWidgetState();
}

class _AiInputWidgetState extends State<AiInputWidget>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  /// Trigger shake animation when user tries to send while offline
  void _triggerShake() {
    _shakeController.forward().then((_) {
      _shakeController.reverse();
    });
  }

  /// Handle send button tap
  void _handleSendTap(bool isOnline) {
    if (!isOnline) {
      _triggerShake();
      return;
    }

    _sendMessage();
  }

  /// Send the message
  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    context.read<ChatCubit>().sendMessage(text, AppLocalizations.of(context)!);
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<AppConnectivityCubit, AppConnectivityState>(
      builder: (context, connectivityState) {
        final isOnline = !connectivityState.isOffline;

        return _buildInputArea(context, theme, isOnline);
      },
    );
  }

  /// Build the input area with proper styling based on connection state
  Widget _buildInputArea(BuildContext context, ThemeData theme, bool isOnline) {
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
          top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isOnline
                    ? theme.cardColor
                    : theme.disabledColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(28),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                readOnly: !isOnline,
                decoration: InputDecoration(
                  hintText: isOnline
                      ? AppLocalizations.of(context)!.messageAssistant
                      : AppLocalizations.of(context)!.connectionRequired,
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    fontSize: 15,
                    color: isOnline
                        ? null
                        : theme.disabledColor.withValues(alpha: 0.6),
                  ),
                ),
                style: TextStyle(
                  fontSize: 15,
                  color: isOnline
                      ? null
                      : theme.disabledColor.withValues(alpha: 0.6),
                ),
                onSubmitted: (_) => _handleSendTap(isOnline),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _buildSendButton(isOnline),
        ],
      ),
    );
  }

  /// Build the send button with shake animation and connectivity awareness
  Widget _buildSendButton(bool isOnline) {
    return SlideTransition(
      position: Tween<Offset>(begin: Offset.zero, end: const Offset(0.1, 0))
          .animate(
            CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
          ),
      child: GestureDetector(
        onTap: () => _handleSendTap(isOnline),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isOnline ? AppColors.deepPurple : Colors.grey,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
        ),
      ),
    );
  }
}
