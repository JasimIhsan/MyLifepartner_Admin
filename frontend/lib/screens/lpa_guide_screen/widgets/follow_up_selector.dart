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
          return Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(vertical: 4),
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
                      color: Theme.of(context).primaryColor,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        opt['text'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Theme.of(context).textTheme.bodySmall?.color ?? AppColors.textLight,
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
}