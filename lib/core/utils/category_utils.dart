import 'package:flutter/material.dart';
import 'constants.dart';

class CategoryUtils {
  static const List<String> categories = [
    'Work',
    'Meeting',
    'Important',
    'Personal',
    'Health',
    'Break',
    'Other',
  ];

  static Color getCategoryColor(String category) {
    switch (category) {
      case 'Meeting':
        return Colors.redAccent;
      case 'Work':
        return AppColors.slatePurple;
      case 'Important':
        return Colors.red;
      case 'Break':
        return Colors.green;
      case 'Personal':
        return Colors.blue;
      case 'Health':
        return Colors.purple;
      case 'Other':
        return AppColors.creamTan;
      default:
        return AppColors.slatePurple;
    }
  }
}
