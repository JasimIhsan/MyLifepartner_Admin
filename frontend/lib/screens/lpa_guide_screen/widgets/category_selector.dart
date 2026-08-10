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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // In dark mode: a slightly elevated surface. In light: crisp white.
    final tileBg = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final chevronColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textLight;

    if (categories.isEmpty) {
      return Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: tileBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'No guide categories are available right now.',
          style: TextStyle(fontSize: 14, color: chevronColor),
        ),
      );
    }

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: categories.map((cat) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: tileBg,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: enabled
                    ? () => onSelectCategory(cat.id, cat.name)
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _iconForCategory(cat.name),
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          cat.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: chevronColor,
                        size: 20,
                      ),
                    ],
                  ),
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
