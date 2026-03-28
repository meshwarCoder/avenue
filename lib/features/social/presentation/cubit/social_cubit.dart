import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repo/social_repository.dart';
import 'social_state.dart';

class SocialCubit extends Cubit<SocialState> {
  final SocialRepository repository;

  SocialCubit({required this.repository}) : super(const SocialState());

  Future<void> loadSocialData() async {
    emit(state.copyWith(
      isLoadingFriends: true,
      isLoadingRequests: true,
      friendsError: null,
      requestsError: null,
    ));

    final results = await Future.wait([
      repository.fetchFriends(),
      repository.fetchIncomingRequests(),
      repository.fetchOutgoingRequests(),
    ]);

    final friendsResult = results[0];
    final incomingResult = results[1];
    final outgoingResult = results[2];

    var nextState = state.copyWith(
      isLoadingFriends: false,
      isLoadingRequests: false,
    );

    friendsResult.fold(
      (failure) {
        print('Social Load Error (Friends): ${failure.message}');
        nextState = nextState.copyWith(friendsError: failure.message);
      },
      (friends) => nextState = nextState.copyWith(friends: friends),
    );

    incomingResult.fold(
      (failure) {
        print('Social Load Error (Incoming): ${failure.message}');
        nextState = nextState.copyWith(requestsError: failure.message);
      },
      (incoming) => nextState = nextState.copyWith(incomingRequests: incoming),
    );

    outgoingResult.fold(
      (failure) {
        print('Social Load Error (Outgoing): ${failure.message}');
        nextState = nextState.copyWith(
            requestsError: nextState.requestsError ?? failure.message);
      },
      (outgoing) => nextState = nextState.copyWith(outgoingRequests: outgoing),
    );

    emit(nextState);
  }

  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      emit(state.copyWith(
        searchResults: [],
        searchError: null,
        isLoadingSearch: false,
      ));
      return;
    }

    emit(state.copyWith(isLoadingSearch: true, searchError: null));

    final result = await repository.searchUsers(query);
    result.fold(
      (failure) {
        print('Social Search Cubit Error: ${failure.message}');
        emit(state.copyWith(searchError: failure.message, isLoadingSearch: false));
      },
      (users) {
        print('Social Search Cubit Success: Emitting ${users.length} results.');
        emit(state.copyWith(
            searchResults: users, searchError: null, isLoadingSearch: false));
      },
    );
  }

  Future<void> sendFriendRequest(String receiverId) async {
    final result = await repository.sendFriendRequest(receiverId);
    result.fold(
      (failure) {
        print('Send Request Action Error: ${failure.message}');
        emit(state.copyWith(
          notificationType: SocialNotificationType.error,
          lastNotification: failure.message,
        ));
      },
      (_) {
        print('Send Request Action Success');
        emit(state.copyWith(notificationType: SocialNotificationType.requestSent));
        loadSocialData();
      },
    );
  }

  Future<void> acceptFriendRequest(String senderId) async {
    final result = await repository.acceptFriendRequest(senderId);
    result.fold(
      (failure) {
        print('Accept Request Action Error: ${failure.message}');
        emit(state.copyWith(
          notificationType: SocialNotificationType.error,
          lastNotification: failure.message,
        ));
      },
      (_) {
        print('Accept Request Action Success');
        emit(state.copyWith(notificationType: SocialNotificationType.requestAccepted));
        loadSocialData();
      },
    );
  }

  Future<void> cancelFriendRequest(String otherId) async {
    final result = await repository.cancelFriendRequest(otherId);
    result.fold(
      (failure) {
        print('Cancel Request Action Error: ${failure.message}');
        emit(state.copyWith(
          notificationType: SocialNotificationType.error,
          lastNotification: failure.message,
        ));
      },
      (_) {
        print('Cancel Request Action Success');
        emit(state.copyWith(notificationType: SocialNotificationType.requestCancelled));
        loadSocialData();
      },
    );
  }

  void clearNotification() {
    emit(state.copyWith(clearNotification: true));
  }
}
