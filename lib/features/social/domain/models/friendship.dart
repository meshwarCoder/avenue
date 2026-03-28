enum FriendshipStatus { pending, accepted, blocked }

class Friendship {
  final String id;
  final String senderId;
  final String receiverId;
  final FriendshipStatus status;
  final DateTime createdAt;
  final String userA;
  final String userB;
  final DateTime? acceptedAt;
  final DateTime? blockedAt;

  Friendship({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
    required this.userA,
    required this.userB,
    this.acceptedAt,
    this.blockedAt,
  });

  factory Friendship.fromJson(Map<String, dynamic> json) {
    return Friendship(
      id: json['id'] as String,
      senderId: json['sender_id'] as String,
      receiverId: json['receiver_id'] as String,
      status: FriendshipStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => FriendshipStatus.pending,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      userA: json['user_a'] as String,
      userB: json['user_b'] as String,
      acceptedAt: json['accepted_at'] != null ? DateTime.parse(json['accepted_at'] as String) : null,
      blockedAt: json['blocked_at'] != null ? DateTime.parse(json['blocked_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'user_a': userA,
      'user_b': userB,
      'accepted_at': acceptedAt?.toIso8601String(),
      'blocked_at': blockedAt?.toIso8601String(),
    };
  }
}
