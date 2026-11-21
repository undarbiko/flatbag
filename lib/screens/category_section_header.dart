import 'package:flutter/material.dart';

/// Displays a category section heading with its item count and a subtle divider.
class CategorySectionHeader extends StatelessWidget {
  final String category;
  final int count;

  const CategorySectionHeader({super.key, required this.category, required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$category ($count)',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Divider(height: 1, color: theme.dividerColor),
        ],
      ),
    );
  }
}
