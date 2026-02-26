import 'package:uuid/uuid.dart';

class ProfileModel {
  final String id;
  final String userId;
  final int timezoneOffset;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProfileModel({
    String? id,
    required this.userId,
    required this.timezoneOffset,
    this.role = 'user',
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now().toUtc(),
       updatedAt = updatedAt ?? DateTime.now().toUtc();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'timezone_offset': timezoneOffset,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id: map['id'],
      userId: map['user_id'],
      timezoneOffset: map['timezone_offset'],
      role: map['role'] ?? 'user',
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  // Supabase specific methods
  Map<String, dynamic> toSupabaseJson() {
    return {
      'id': id,
      'user_id': userId,
      'timezone_offset': timezoneOffset,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ProfileModel.fromSupabaseJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'],
      userId: json['user_id'],
      timezoneOffset: json['timezone_offset'],
      role: json['role'] ?? 'user',
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
