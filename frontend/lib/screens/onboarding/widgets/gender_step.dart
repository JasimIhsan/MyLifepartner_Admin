import 'package:flutter/material.dart';
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
        const SizedBox(height: 20),
        OnboardingSelectionTile(
          label: 'Man',
          value: 'MALE',
          selectedValue: selectedGender,
          onTap: () => onGenderChanged('MALE'),
        ),
        OnboardingSelectionTile(
          label: 'Woman',
          value: 'FEMALE',
          selectedValue: selectedGender,
          onTap: () => onGenderChanged('FEMALE'),
        ),
      ],
    );
  }
}
