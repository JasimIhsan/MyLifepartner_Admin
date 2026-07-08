import 'package:flutter/material.dart';
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
    return Column(
      children: [
        const OnboardingStepTitle(title: "A few more details"),
        const SizedBox(height: 30),
        const OnboardingSectionLabel(text: "Do you drink?"),
        Row(
          children: [
            Expanded(
              child: OnboardingSelectionTile(
                label: 'Yes',
                value: 'YES',
                selectedValue: drinkingHabit,
                onTap: () => onDrinkingChanged('YES'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OnboardingSelectionTile(
                label: 'No',
                value: 'NO',
                selectedValue: drinkingHabit,
                onTap: () => onDrinkingChanged('NO'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const OnboardingSectionLabel(text: "Do you smoke?"),
        Row(
          children: [
            Expanded(
              child: OnboardingSelectionTile(
                label: 'Yes',
                value: 'YES',
                selectedValue: smokingHabit,
                onTap: () => onSmokingChanged('YES'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OnboardingSelectionTile(
                label: 'No',
                value: 'NO',
                selectedValue: smokingHabit,
                onTap: () => onSmokingChanged('NO'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
