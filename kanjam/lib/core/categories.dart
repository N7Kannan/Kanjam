import 'package:flutter/material.dart';

/// Category lists plus the icon and colour used to draw each one.
class Categories {
  Categories._();

  static const String overall = 'Overall';

  static const List<String> expense = <String>[
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Entertainment',
    'Health',
    'Education',
    'Other',
  ];

  static const List<String> income = <String>[
    'Salary',
    'Freelance',
    'Investment',
    'Gift',
    'Refund',
    'Other',
  ];

  /// Budgets can target one expense category or everything ("Overall").
  static const List<String> budget = <String>[overall, ...expense];

  static IconData iconFor(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant;
      case 'Transport':
        return Icons.directions_bus;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Bills':
        return Icons.receipt_long;
      case 'Entertainment':
        return Icons.movie;
      case 'Health':
        return Icons.favorite;
      case 'Education':
        return Icons.school;
      case 'Salary':
        return Icons.payments;
      case 'Freelance':
        return Icons.laptop_mac;
      case 'Investment':
        return Icons.trending_up;
      case 'Gift':
        return Icons.card_giftcard;
      case 'Refund':
        return Icons.replay;
      case overall:
        return Icons.account_balance_wallet;
      default:
        return Icons.category;
    }
  }

  static Color colorFor(String category) {
    switch (category) {
      case 'Food':
        return const Color(0xFFFF9800);
      case 'Transport':
        return const Color(0xFF29B6F6);
      case 'Shopping':
        return const Color(0xFFAB47BC);
      case 'Bills':
        return const Color(0xFFFFCA28);
      case 'Entertainment':
        return const Color(0xFFEC407A);
      case 'Health':
        return const Color(0xFFEF5350);
      case 'Education':
        return const Color(0xFF5C6BC0);
      case 'Salary':
        return const Color(0xFF00E676);
      case 'Freelance':
        return const Color(0xFF26C6DA);
      case 'Investment':
        return const Color(0xFF66BB6A);
      case 'Gift':
        return const Color(0xFFF06292);
      case 'Refund':
        return const Color(0xFF8D6E63);
      case overall:
        return const Color(0xFF00E676);
      default:
        return const Color(0xFF90A4AE);
    }
  }
}
