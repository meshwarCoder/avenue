import 'package:equatable/equatable.dart';
import '../../domain/models/user_profile.dart';

enum SocialNotificationType {
  none,
  requestSent,
  requestAccepted,
  requestCancelled,
  error,
}

class SocialState extends Equatable {

  final List<UserProfile> friends;
  final List<UserProfile> incomingRequests;
  final List<UserProfile> outgoingRequests;
  final List<UserProfile> searchResults;
  final bool isLoadingFriends;
  final bool isLoadingSearch;
  final bool isLoadingRequests;
  final String? friendsError;
  final String? searchError;
  final String? requestsError;
  final SocialNotificationType notificationType;
  final String? lastNotification; // Success/Failure message for snackbars


  const SocialState({
    this.friends = const [],
    this.incomingRequests = const [],
    this.outgoingRequests = const [],
    this.searchResults = const [],
    this.isLoadingFriends = false,
    this.isLoadingSearch = false,
    this.isLoadingRequests = false,
    this.friendsError,
    this.searchError,
    this.requestsError,
    this.notificationType = SocialNotificationType.none,
    this.lastNotification,
  });


  SocialState copyWith({
    List<UserProfile>? friends,
    List<UserProfile>? incomingRequests,
    List<UserProfile>? outgoingRequests,
    List<UserProfile>? searchResults,
    bool? isLoadingFriends,
    bool? isLoadingSearch,
    bool? isLoadingRequests,
    String? friendsError,
    String? searchError,
    String? requestsError,
    SocialNotificationType? notificationType,
    String? lastNotification,
    bool clearNotification = false,
  }) {
    return SocialState(
      friends: friends ?? this.friends,
      incomingRequests: incomingRequests ?? this.incomingRequests,
      outgoingRequests: outgoingRequests ?? this.outgoingRequests,
      searchResults: searchResults ?? this.searchResults,
      isLoadingFriends: isLoadingFriends ?? this.isLoadingFriends,
      isLoadingSearch: isLoadingSearch ?? this.isLoadingSearch,
      isLoadingRequests: isLoadingRequests ?? this.isLoadingRequests,
      friendsError: friendsError ?? this.friendsError,
      searchError: searchError ?? this.searchError,
      requestsError: requestsError ?? this.requestsError,
      notificationType: clearNotification ? SocialNotificationType.none : (notificationType ?? this.notificationType),
      lastNotification: clearNotification ? null : (lastNotification ?? this.lastNotification),
    );
  }


  @override
  List<Object?> get props => [
        friends,
        incomingRequests,
        outgoingRequests,
        searchResults,
        isLoadingFriends,
        isLoadingSearch,
        isLoadingRequests,
        friendsError,
        searchError,
        requestsError,
        notificationType,
        lastNotification,
      ];
}

