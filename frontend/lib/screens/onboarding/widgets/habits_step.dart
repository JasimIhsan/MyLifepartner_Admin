import 'package:flutter/material.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/screens/onboarding/widgets/onboarding_ui_helpers.dart';

class HabitsStep extends StatelessWidget {
  final String? drinkingHabit;
  final String? smokingHabit;
  final ValueChanged<String> onDrinkingChanged;
  final ValueChanged<String> onSmokingChanged;

  const HabitsStep({
    super.key,
    required this.drinkingHabit,
    required this.smokingHabit,
    required this.onDrinkingChanged,
    required this.onSmokingChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final drinkOptions = [
      {'title': 'Never', 'icon': Icons.no_drinks_outlined, 'value': 'NEVER'},
      {
        'title': 'Occasionally',
        'icon': Icons.calendar_month_outlined,
        'value': 'OCCASIONALLY',
      },
      {'title': 'Socially', 'icon': Icons.groups_outlined, 'value': 'SOCIALLY'},
      {
        'title': 'Regularly',
        'icon': Icons.local_bar_outlined,
        'value': 'REGULARLY',
      },
    ];

    final smokeOptions = [
      {'title': 'Never', 'icon': Icons.smoke_free_outlined, 'value': 'NEVER'},
      {
        'title': 'Occasionally',
        'icon': Icons.calendar_month_outlined,
        'value': 'OCCASIONALLY',
      },
      {'title': 'Socially', 'icon': Icons.groups_outlined, 'value': 'SOCIALLY'},
      {
        'title': 'Regularly',
        'icon': Icons.smoking_rooms_outlined,
        'value': 'REGULARLY',
      },
    ];

    return Column(
      children: [
        const OnboardingStepTitle(title: "A few more details"),
        const SizedBox(height: 4),
        Text(
          "Help us understand your lifestyle better.",
          style: TextStyle(
            fontSize: 15,
            color:
                Theme.of(context).textTheme.bodyMedium?.color ??
                AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        _buildSectionHeader(
          "Do you drink?",
          Icons.wine_bar_outlined,
          isDarkMode,
        ),
        const SizedBox(height: 16),
        _buildResponsiveGrid(
          selectedValue: drinkingHabit,
          onChanged: onDrinkingChanged,
          options: drinkOptions,
        ),
        const SizedBox(height: 32),
        _buildSectionHeader(
          "Do you smoke?",
          Icons.smoking_rooms_outlined,
          isDarkMode,
        ),
        const SizedBox(height: 16),
        _buildResponsiveGrid(
          selectedValue: smokingHabit,
          onChanged: onSmokingChanged,
          options: smokeOptions,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDarkMode) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildResponsiveGrid({
    required String? selectedValue,
    required ValueChanged<String> onChanged,
    required List<Map<String, dynamic>> options,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double spacing = 12.0;
        int crossAxisCount = 1;

        if (constraints.maxWidth >= 450) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 1;
        }

        final double itemWidth =
            (constraints.maxWidth - (spacing * (crossAxisCount - 1))) /
                crossAxisCount -
            0.1;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: options.map((opt) {
            return SizedBox(
              width: itemWidth,
              child: HabitSelectionCard(
                title: opt['title'] as String,
                icon: opt['icon'] as IconData,
                value: opt['value'] as String,
                selectedValue: selectedValue,
                onTap: () => onChanged(opt['value'] as String),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class HabitSelectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final String value;
  final String? selectedValue;
  final VoidCallback onTap;

  const HabitSelectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.value,
    required this.selectedValue,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedValue == value;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final activeColor = Theme.of(context).primaryColor;
    final inactiveBorderColor = isDarkMode
        ? theme.dividerColor
        : const Color(0xFFF0E6E6);
    final cardColor = isDarkMode
        ? (isSelected ? activeColor.withValues(alpha: 0.1) : theme.cardColor)
        : (isSelected ? activeColor.withValues(alpha: 0.05) : Colors.white);
    final iconColor = isSelected
        ? activeColor
        : (isDarkMode ? Colors.white70 : Colors.black87);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: cardColor,
          border: Border.all(
            color: isSelected ? activeColor : inactiveBorderColor,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: isDarkMode
                          ? Colors.white
                          : Theme.of(context).textTheme.bodyLarge?.color ??
                                AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            Theme.of(context).textTheme.bodyMedium?.color ??
                            AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: activeColor, width: 2),
                ),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: activeColor,
                    shape: BoxShape.circle,
                  ),
                ),
              )
            else
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade400, width: 1.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
