import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/constants.dart';
import '../cubit/social_cubit.dart';
import '../cubit/social_state.dart';

class FriendsListSection extends StatelessWidget {
  const FriendsListSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return BlocBuilder<SocialCubit, SocialState>(
      builder: (context, state) {
        if (state.isLoadingFriends && state.friends.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final friends = state.friends;

        if (friends.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (state.friendsError != null) ...[
                    const Icon(Icons.error_outline_rounded,
                        color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(state.friendsError!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          context.read<SocialCubit>().loadSocialData(),
                      child: const Text('Try Again'),
                    ),
                  ] else ...[
                    const Icon(Icons.people_outline_rounded,
                        color: Colors.grey, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      l10n.noUsersFound, // Using noUsersFound as a generic empty state for now
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
          );
        }


        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friend = friends[index];
            final hasProfilePic = friend.profilePicture != null;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: AppColors.deepPurple.withOpacity(0.2),
                  backgroundImage: hasProfilePic
                      ? NetworkImage(friend.profilePicture!)
                      : null,
                  child: !hasProfilePic
                      ? Text(
                          friend.initials,
                          style: const TextStyle(
                            color: AppColors.deepPurple,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                title: Text(
                  friend.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  '@${friend.username}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                trailing: IconButton(
                  onPressed: () {
                    // Logic for starting a chat or viewing profile
                  },
                  icon:
                      const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
