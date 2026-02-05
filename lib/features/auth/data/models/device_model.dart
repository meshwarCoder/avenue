import 'package:uuid/uuid.dart';

class DeviceModel {
  final String id;
  final String userId;
  final String deviceId;
  final DateTime serverUpdatedAt;
  final DateTime createdAt;

  DeviceModel({
    String? id,
    required this.userId,
    required this.deviceId,
    DateTime? serverUpdatedAt,
    DateTime? createdAt,
  }) : id = id ?? const Uuid().v4(),
       serverUpdatedAt = serverUpdatedAt ?? DateTime.now().toUtc(),
       createdAt = createdAt ?? DateTime.now().toUtc();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'device_id': deviceId,
      'server_updated_at': serverUpdatedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory DeviceModel.fromMap(Map<String, dynamic> map) {
    return DeviceModel(
      id: map['id'],
      userId: map['user_id'],
      deviceId: map['device_id'],
      serverUpdatedAt: DateTime.parse(map['server_updated_at']),
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  // Supabase specific methods
  Map<String, dynamic> toSupabaseJson() {
    return {
      'id': id,
      'user_id': userId,
      'device_id': deviceId,
      'server_updated_at': serverUpdatedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory DeviceModel.fromSupabaseJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'],
      userId: json['user_id'],
      deviceId: json['device_id'],
      serverUpdatedAt: DateTime.parse(
        json['server_updated_at'] ?? DateTime.now().toIso8601String(),
      ),
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
