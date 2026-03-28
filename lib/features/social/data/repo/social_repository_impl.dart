import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/request_executor.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/repo/social_repository.dart';

class SocialRepositoryImpl implements SocialRepository {
  final SupabaseClient supabase;
  final RequestExecutor _requestExecutor;

  SocialRepositoryImpl({
    required this.supabase,
    required RequestExecutor requestExecutor,
  }) : _requestExecutor = requestExecutor;

  String? get _currentUserId => supabase.auth.currentUser?.id;

  @override
  Future<Either<Failure, List<UserProfile>>> fetchFriends() async {
    return _requestExecutor.execute(
      operation: () async {
        final userId = _currentUserId;
        if (userId == null) throw Exception('User not logged in');

        print('--- DEBUG FETCH FRIENDS ---');
        print('User ID: $userId');

        try {
          final response = await supabase
              .from('friendships')
              .select('user_a, user_b')
              .eq('status', 'accepted')
              .or('user_a.eq.$userId,user_b.eq.$userId');

          print('FetchFriends response: $response');

          if ((response as List).isEmpty) return [];

          final List<String> friendIds = (response as List).map((f) {
            final a = f['user_a'] as String?;
            final b = f['user_b'] as String?;
            return a == userId ? (b ?? '') : (a ?? '');
          }).where((id) => id.isNotEmpty).toList();

          print('Friend IDs extracted: $friendIds');

          if (friendIds.isEmpty) return [];

          final profilesResponse = await supabase
              .from('profiles')
              .select('*')
              .inFilter('user_id', friendIds);

          print('Friends Profiles response: $profilesResponse');

          return (profilesResponse as List)
              .map((p) => UserProfile.fromJson(p))
              .toList();
        } catch (e, stack) {
          print('Error in fetchFriends: $e');
          print(stack);
          rethrow;
        }
      },
    );
  }

  @override
  Future<Either<Failure, List<UserProfile>>> searchUsers(String query) async {
    return _requestExecutor.execute(
      operation: () async {
        if (query.isEmpty) return [];

        try {
          print('--- DEBUG SEARCH ---');
          print('Current User ID: $_currentUserId');
          print('Search Query: "$query"');
          
          final response = await supabase
              .from('profiles')
              .select('*')
              .ilike('username', '%$query%')
              .neq('user_id', _currentUserId ?? '')
              .limit(10);

          print('Search response raw: $response');

          final results = (response as List).map((p) => UserProfile.fromJson(p)).toList();
          print('Search Success: Found ${results.length} results.');
          
          return results;
        } catch (e, stack) {
          print('Search Error: $e');
          print(stack);
          rethrow;
        }
      },
    );
  }

  @override
  Future<Either<Failure, void>> sendFriendRequest(String receiverId) async {
    return _requestExecutor.execute(
      operation: () async {
        final senderId = _currentUserId;
        if (senderId == null) throw Exception('User not logged in');

        print('--- DEBUG SEND REQUEST ---');
        print('Sender ID: $senderId');
        print('Receiver ID: $receiverId');

        try {
          // Note: receiver_id is the corrected column name
          await supabase.from('friendships').insert({
            'sender_id': senderId,
            'receiver_id': receiverId,
            'status': 'pending',
          });
          print('Send Request: Insert completed successfully');
        } catch (e, stack) {
          print('Send Request: Insert failed');
          print('Error: $e');
          print(stack);
          rethrow;
        }
      },
    );
  }

  @override
  Future<Either<Failure, void>> acceptFriendRequest(String senderId) async {
    return _requestExecutor.execute(
      operation: () async {
        final receiverId = _currentUserId;
        if (receiverId == null) throw Exception('User not logged in');

        print('--- DEBUG ACCEPT REQUEST ---');
        print('Accepting request from Sender: $senderId, Receiver: $receiverId');

        try {
          await supabase
              .from('friendships')
              .update({
                'status': 'accepted',
                'accepted_at': DateTime.now().toIso8601String(),
              })
              .eq('sender_id', senderId)
              .eq('receiver_id', receiverId);
          print('Accept Request: Update completed successfully');
        } catch (e, stack) {
          print('Accept Request: Update failed');
          print('Error: $e');
          print(stack);
          rethrow;
        }
      },
    );
  }

  @override
  Future<Either<Failure, void>> cancelFriendRequest(String otherId) async {
    return _requestExecutor.execute(
      operation: () async {
        final currentUserId = _currentUserId;
        if (currentUserId == null) throw Exception('User not logged in');

        print('--- DEBUG CANCEL/DECLINE REQUEST ---');
        print('Current User: $currentUserId, Other User: $otherId');

        try {
          // Deletes the friendship record regardless of who sent it
          // This covers both canceling a sent request and declining an incoming one
          await supabase
              .from('friendships')
              .delete()
              .or('and(sender_id.eq.$currentUserId,receiver_id.eq.$otherId),and(sender_id.eq.$otherId,receiver_id.eq.$currentUserId)');
          
          print('Cancel/Decline Request: Delete completed successfully');
        } catch (e, stack) {
          print('Cancel/Decline Request: Delete failed');
          print('Error: $e');
          print(stack);
          rethrow;
        }
      },
    );
  }

  @override
  Future<Either<Failure, List<UserProfile>>> fetchIncomingRequests() async {
    return _requestExecutor.execute(
      operation: () async {
        final userId = _currentUserId;
        if (userId == null) throw Exception('User not logged in');

        print('--- DEBUG FETCH INCOMING ---');
        print('User ID: $userId');

        try {
          final response = await supabase
              .from('friendships')
              .select('sender_id')
              .eq('receiver_id', userId)
              .eq('status', 'pending');

          print('Incoming response: $response');

          if ((response as List).isEmpty) return [];

          final List<String> senderIds = (response as List)
              .map((f) => f['sender_id'] as String)
              .toList();

          final profilesResponse = await supabase
              .from('profiles')
              .select('*')
              .inFilter('user_id', senderIds);

          print('Incoming Profiles: $profilesResponse');

          return (profilesResponse as List)
              .map((p) => UserProfile.fromJson(p))
              .toList();
        } catch (e, stack) {
          print('Error in fetchIncomingRequests: $e');
          print(stack);
          rethrow;
        }
      },
    );
  }

  @override
  Future<Either<Failure, List<UserProfile>>> fetchOutgoingRequests() async {
    return _requestExecutor.execute(
      operation: () async {
        final userId = _currentUserId;
        if (userId == null) throw Exception('User not logged in');

        print('--- DEBUG FETCH OUTGOING ---');
        print('User ID: $userId');

        try {
          final response = await supabase
              .from('friendships')
              .select('receiver_id')
              .eq('sender_id', userId)
              .eq('status', 'pending');

          print('Outgoing response: $response');

          if ((response as List).isEmpty) return [];

          final List<String> receiverIds = (response as List)
              .map((f) => f['receiver_id'] as String)
              .toList();

          final profilesResponse = await supabase
              .from('profiles')
              .select('*')
              .inFilter('user_id', receiverIds);

          print('Outgoing Profiles: $profilesResponse');

          return (profilesResponse as List)
              .map((p) => UserProfile.fromJson(p))
              .toList();
        } catch (e, stack) {
          print('Error in fetchOutgoingRequests: $e');
          print(stack);
          rethrow;
        }
      },
    );
  }
}
