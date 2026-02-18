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

  // Category Colors
  static const Color categoryWork = Color(0xFF00796B); // Deep Teal
  static const Color categoryMeeting = Color(0xFF1976D2); // Rich Blue
  static const Color categoryPersonal = Color(0xFF3F51B5); // Indigo
  static const Color categoryHealth = Color(0xFFE64A19); // Vibrant Orange
  static const Color categoryStudy = Color(0xFF673AB7); // Deep Purple
  static const Color categoryFinance = Color(0xFF2E7D32); // Success Green
  static const Color categorySocial = Color(0xFFC2185B); // Pink
  static const Color categoryOther = Color(0xFF546E7A); // Slate Grey

  static const List<String> taskCategories = [
    'Work',
    'Meeting',
    'Personal',
    'Health',
    'Study',
    'Finance',
    'Social',
    'Other',
  ];

  // Backgrounds
  static const Color lightBg = Color(0xFFF5F5F7);
  static const Color darkBg = Color(0xFF121212);

  // Text
  static const Color lightText = Color(0xFF1A1A2E);
  static const Color darkText = Color(0xFFF5F7FA);

  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'work':
        return categoryWork;
      case 'personal':
        return categoryPersonal;
      case 'health':
        return categoryHealth;
      case 'meeting':
        return categoryMeeting;
      case 'study':
        return categoryStudy;
      case 'finance':
        return categoryFinance;
      case 'social':
        return categorySocial;
      case 'other':
      default:
        return categoryOther;
    }
  }
}
