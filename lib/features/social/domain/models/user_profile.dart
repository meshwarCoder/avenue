class UserProfile {
  final String userId;
  final String username;
  final String firstName;
  final String? lastName;
  final String? profilePicture;
  final String? role;

  UserProfile({
    required this.userId,
    required this.username,
    required this.firstName,
    this.lastName,
    this.profilePicture,
    this.role,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    try {
      return UserProfile(
        userId: json['user_id'] as String? ?? json['id'] as String? ?? '',
        username: json['username'] as String? ?? 'unknown',
        firstName: json['first_name'] as String? ?? '',
        lastName: json['last_name'] as String?,
        profilePicture: json['profile_picture'] as String?,
        role: json['role'] as String?,
      );
    } catch (e) {
      print('Error parsing UserProfile: $e, JSON: $json');
      rethrow;
    }
  }



  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'profile_picture': profilePicture,
      'role': role,
    };
  }

  String get fullName => lastName != null ? '$firstName $lastName' : firstName;

  String get initials {
    if (firstName.isEmpty) return '??';
    final firstInitial = firstName.substring(0, 1).toUpperCase();
    final lastInitial = (lastName != null && lastName!.isNotEmpty)
        ? lastName!.substring(0, 1).toUpperCase()
        : '';
    return '$firstInitial$lastInitial';
  }
}
