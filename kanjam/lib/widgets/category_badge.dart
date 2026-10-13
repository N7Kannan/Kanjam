import 'package:flutter/material.dart';

import '../core/categories.dart';

/// Round coloured icon for a category.
class CategoryBadge extends StatelessWidget {
  const CategoryBadge({super.key, required this.category, this.size = 44});

  final String category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = Categories.colorFor(category);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(Categories.iconFor(category), size: size * 0.5, color: color),
    );
  }
}
