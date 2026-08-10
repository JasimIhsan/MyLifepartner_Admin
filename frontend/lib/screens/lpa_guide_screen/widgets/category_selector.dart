import 'package:flutter/material.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/models/guide_category.dart';

class CategorySelector extends StatelessWidget {
  final List<GuideCategory> categories;
  final Function(int id, String name) onSelectCategory;
  final bool enabled;

  const CategorySelector({
    super.key,
    required this.categories,
    required this.onSelectCategory,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'No guide categories are available right now.',
          style: TextStyle(
            fontSize: 14,
            color:
                Theme.of(context).textTheme.bodyMedium?.color ??
                AppColors.textSecondary,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: categories.map((cat) {
          return Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: enabled ? () => onSelectCategory(cat.id, cat.name) : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      _iconForCategory(cat.name),
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        cat.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color:
                              Theme.of(context).textTheme.bodyLarge?.color ??
                              AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color:
                          Theme.of(context).textTheme.bodySmall?.color ??
                          AppColors.textLight,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _iconForCategory(String name) {
    final normalizedName = name.toLowerCase();

    if (normalizedName.contains('safety') ||
        normalizedName.contains('privacy')) {
      return Icons.security;
    }
    if (normalizedName.contains('account') ||
        normalizedName.contains('trust') ||
        normalizedName.contains('verify')) {
      return Icons.verified_user_outlined;
    }
    if (normalizedName.contains('member') ||
        normalizedName.contains('subscription') ||
        normalizedName.contains('plan')) {
      return Icons.card_membership_outlined;
    }
    if (normalizedName.contains('lpa') ||
        normalizedName.contains('about') ||
        normalizedName.contains('life')) {
      return Icons.favorite_outline;
    }

    return Icons.help_outline_rounded;
  }
}
