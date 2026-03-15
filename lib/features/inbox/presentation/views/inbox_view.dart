import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/inbox_cubit.dart';
import '../cubit/inbox_state.dart';
import '../widgets/inbox_item_card.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/avenue_action_sheet.dart';

class InboxView extends StatelessWidget {
  const InboxView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Inbox',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: const InboxViewBody(),
    );
  }
}

class InboxViewBody extends StatelessWidget {
  const InboxViewBody({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<InboxCubit, InboxState>(
      builder: (context, state) {
        if (state is InboxLoading || state is InboxInitial) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is InboxError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
              ),
            ),
          );
        } else if (state is InboxLoaded) {
          final items = state.items;
          if (items.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.inbox_outlined,
              title: "Inbox is empty",
              subtitle: "Capture ideas, tasks or notes",
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(
              bottom: 100,
              top: 8,
              left: 15,
              right: 15,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return InboxItemCard(
                item: item,
                onTap: () => _showItemActions(context, item),
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _showItemActions(BuildContext context, dynamic item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return AvenueActionSheet(
          title: item.title,
          subtitle: "Inbox Item • ${item.type.displayName.toUpperCase()}",
          actions: [
            AvenueAction(
              icon: Icons.edit_outlined,
              title: "Edit",
              onTap: () {
                // TODO: Implement edit
              },
            ),
            AvenueAction(
              icon: Icons.task_alt_outlined,
              title: "Convert to Task",
              onTap: () {
                // TODO: Implement convert
              },
            ),
            AvenueAction(
              icon: Icons.delete_outline_rounded,
              title: "Delete",
              isDestructive: true,
              onTap: () {
                context.read<InboxCubit>().deleteInboxItem(item.id);
              },
            ),
          ],
        );
      },
    );
  }
}
