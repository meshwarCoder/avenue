import 'package:flutter/material.dart';

// Error Messages
class ErrorMessages {
  static const String cacheFailure = 'Failed to cache data';
  static const String taskNotFound = 'Task not found';
  static const String addTaskFailed = 'Failed to add task';
  static const String updateTaskFailed = 'Failed to update task';
  static const String deleteTaskFailed = 'Failed to delete task';
  static const String loadTasksFailed = 'Failed to load tasks';
}

class AppColors {
  // Primary Palette
  static const Color deepPurple = Color(0xFF312C51);
  static const Color slatePurple = Color(0xFF48426D);
  static const Color creamTan = Color(0xFFF0C38E);
  static const Color salmonPink = Color(0xFFF1AA9B);

  // Backgrounds
  static const Color lightBg = Color(0xFFF5F5F7);
  static const Color darkBg = Color(0xFF121212);

  // Text
  static const Color lightText = Color(0xFF1A1A2E);
  static const Color darkText = Color(0xFFF5F7FA);
}
