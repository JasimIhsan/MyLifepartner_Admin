import 'package:flutter/material.dart';
import 'package:life_partner_again/core/app_colors.dart';

class FollowUpSelector extends StatelessWidget {
  final bool hasCurrentCategory;
  final Function(String action) onSelectOption;
  final bool enabled;

  const FollowUpSelector({
    super.key,
    required this.hasCurrentCategory,
    required this.onSelectOption,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tileBg = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final chevronColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textLight;

    final List<Map<String, dynamic>> followUpOptions = [
      {
        'action': 'another_question',
        'text': hasCurrentCategory
            ? 'Ask another question'
            : 'Show all questions',
        'icon': Icons.chat_bubble_outline_rounded,
      },
      {
        'action': 'change_category',
        'text': 'Change category',
        'icon': Icons.grid_view_rounded,
      },
      {
        'action': 'contact_support',
        'text': 'Contact Support',
        'icon': Icons.mail_outline_rounded,
      },
    ];

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: followUpOptions.map((opt) {
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
                    ? () => onSelectOption(opt['action'] as String)
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        opt['icon'] as IconData,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          opt['text'] as String,
                          style: TextStyle(
                            fontSize: 13,
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
}
