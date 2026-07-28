import 'package:flutter/material.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/screens/onboarding/widgets/onboarding_ui_helpers.dart';

class GenderStep extends StatelessWidget {
  final String? selectedGender;
  final ValueChanged<String> onGenderChanged;

  const GenderStep({
    super.key,
    required this.selectedGender,
    required this.onGenderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const OnboardingStepTitle(title: "What's your gender?"),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: _buildGenderCard(
                gender: 'MALE',
                imagePath: 'assets/images/onboarding/gender_male.png',
                label: 'Man',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildGenderCard(
                gender: 'FEMALE',
                imagePath: 'assets/images/onboarding/gender_female.png',
                label: 'Woman',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderCard({
    required String gender,
    required String imagePath,
    required String label,
  }) {
    final isSelected = selectedGender == gender;

    return GestureDetector(
      onTap: () => onGenderChanged(gender),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 190,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFF0E6E6),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.04 : 0.01),
              blurRadius: isSelected ? 10 : 4,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(child: Image.asset(imagePath, fit: BoxFit.contain)),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
