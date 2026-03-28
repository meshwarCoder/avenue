import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../models/user_profile.dart';

abstract class SocialRepository {
  Future<Either<Failure, List<UserProfile>>> fetchFriends();
  Future<Either<Failure, List<UserProfile>>> searchUsers(String query);
  Future<Either<Failure, void>> sendFriendRequest(String receiverId);
  Future<Either<Failure, void>> acceptFriendRequest(String senderId);
  Future<Either<Failure, void>> cancelFriendRequest(String receiverId);
  Future<Either<Failure, List<UserProfile>>> fetchIncomingRequests();
  Future<Either<Failure, List<UserProfile>>> fetchOutgoingRequests();
}
