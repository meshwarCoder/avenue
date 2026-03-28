import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/constants.dart';
import '../cubit/social_cubit.dart';
import '../cubit/social_state.dart';
import '../../domain/models/user_profile.dart';

class SocialSearchSection extends StatefulWidget {
  const SocialSearchSection({super.key});

  @override
  State<SocialSearchSection> createState() => _SocialSearchSectionState();
}

class _SocialSearchSectionState extends State<SocialSearchSection> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<SocialCubit>().searchUsers(query);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Column(
      children: [
        // Search Bar - ALWAYS VISIBLE
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: l10n.searchByUsername,
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        context.read<SocialCubit>().searchUsers('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).cardColor,
            ),
          ),
        ),

        Expanded(
          child: BlocListener<SocialCubit, SocialState>(
            listener: (context, state) {
              if (state.notificationType != SocialNotificationType.none) {
                String message = '';
                switch (state.notificationType) {
                  case SocialNotificationType.requestSent:
                    message = l10n.friendRequestSent;
                    break;
                  case SocialNotificationType.requestAccepted:
                    message = l10n.friendRequestAccepted;
                    break;
                  case SocialNotificationType.requestCancelled:
                    message = l10n.friendRequestCancelled;
                    break;
                  case SocialNotificationType.error:
                    if (state.lastNotification?.contains('send') ?? false) {
                      message = l10n.failedToSendRequest(state.lastNotification ?? '');
                    } else if (state.lastNotification?.contains('accept') ?? false) {
                      message = l10n.failedToAcceptRequest(state.lastNotification ?? '');
                    } else if (state.lastNotification?.contains('cancel') ?? false) {
                      message = l10n.failedToCancelRequest(state.lastNotification ?? '');
                    } else {
                      message = state.lastNotification ?? 'Something went wrong';
                    }
                    break;
                  default:
                    break;
                }

                if (message.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
                context.read<SocialCubit>().clearNotification();
              }
            },
            child: BlocBuilder<SocialCubit, SocialState>(
              builder: (context, state) {
                return Column(
                  children: [
                    if (state.searchError != null)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(state.searchError!,
                            style: const TextStyle(color: Colors.red)),
                      ),
                    Expanded(
                      child: Stack(
                        children: [
                          ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              _buildUserList(
                                context,
                                l10n.searchSocial,
                                state.searchResults,
                                isSearch: true,
                                friends: state.friends,
                                outgoing: state.outgoingRequests,
                                incoming: state.incomingRequests,
                              ),
                              const Divider(height: 32),
                              _buildUserList(
                                context,
                                l10n.upcomingRequests,
                                state.incomingRequests,
                                isIncoming: true,
                              ),
                              const SizedBox(height: 24),
                              _buildUserList(
                                context,
                                l10n.ongoingRequests,
                                state.outgoingRequests,
                                isIncoming: false,
                              ),
                            ],
                          ),
                          if (state.isLoadingSearch || state.isLoadingRequests)
                            Container(
                              color: Colors.black.withOpacity(0.1),
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserList(
    BuildContext context,
    String title,
    List<UserProfile> users, {
    bool isIncoming = false,
    bool isSearch = false,
    List<UserProfile>? friends,
    List<UserProfile>? outgoing,
    List<UserProfile>? incoming,
  }) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 12),
        if (users.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(l10n.noUsersFound),
          ),
        ...users.map((user) {
          final isFriend = friends?.any((f) => f.userId == user.userId) ?? false;
          final isOutgoing = outgoing?.any((f) => f.userId == user.userId) ?? false;
          final isIncomingReq = incoming?.any((f) => f.userId == user.userId) ?? false;

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
              leading: CircleAvatar(
                backgroundColor: AppColors.deepPurple.withOpacity(0.1),
                backgroundImage: user.profilePicture != null
                    ? NetworkImage(user.profilePicture!)
                    : null,
                child: user.profilePicture == null
                    ? Text(
                        user.initials,
                        style: const TextStyle(
                          color: AppColors.deepPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              title: Text(user.fullName),
              subtitle: Text('@${user.username}'),
              trailing: isSearch
                  ? _buildSearchAction(context, user, isFriend, isOutgoing, isIncomingReq)
                  : _buildRequestAction(context, user, isIncoming),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSearchAction(BuildContext context, UserProfile user, bool isFriend, bool isOutgoing, bool isIncoming) {
    final l10n = AppLocalizations.of(context)!;

    if (isFriend) return const Icon(Icons.check_circle_rounded, color: Colors.green);
    if (isOutgoing) return Text(l10n.pending, style: const TextStyle(color: Colors.orange));
    if (isIncoming) return Text(l10n.requestedYou, style: const TextStyle(color: Colors.blue));

    return IconButton(
      onPressed: () => context.read<SocialCubit>().sendFriendRequest(user.userId),
      icon: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.deepPurple),
    );
  }

  Widget _buildRequestAction(BuildContext context, UserProfile user, bool isIncoming) {
    if (isIncoming) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => context.read<SocialCubit>().acceptFriendRequest(user.userId),
            icon: const Icon(Icons.check_circle_rounded, color: Colors.green),
          ),
          IconButton(
            onPressed: () => context.read<SocialCubit>().cancelFriendRequest(user.userId),
            icon: const Icon(Icons.cancel_rounded, color: Colors.red),
          ),
        ],
      );
    } else {
      final l10n = AppLocalizations.of(context)!;
      return TextButton(
        onPressed: () => context.read<SocialCubit>().cancelFriendRequest(user.userId),
        child: Text(l10n.cancel, style: const TextStyle(color: Colors.red)),
      );
    }
  }
}
