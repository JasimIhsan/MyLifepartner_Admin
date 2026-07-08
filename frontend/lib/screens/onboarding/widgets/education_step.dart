import 'package:flutter/material.dart';
import 'package:life_partner_again/screens/onboarding/widgets/onboarding_ui_helpers.dart';

class EducationStep extends StatelessWidget {
  final String? selectedEducation;
  final ValueChanged<String> onEducationChanged;

  const EducationStep({
    super.key,
    required this.selectedEducation,
    required this.onEducationChanged,
  });

  @override
  Widget build(BuildContext context) {
    const options = [
      ('High School', 'HIGH_SCHOOL'),
      ("Bachelor's Degree", 'BACHELORS'),
      ("Master's Degree", 'MASTERS'),
      ('Doctorate / PhD', 'DOCTORATE'),
      ('Other', 'OTHER'),
    ];
    return Column(
      children: [
        const OnboardingStepTitle(title: "What's your highest education?"),
        const SizedBox(height: 20),
        for (final (label, value) in options)
          OnboardingSelectionTile(
            label: label,
            value: value,
            selectedValue: selectedEducation,
            onTap: () => onEducationChanged(value),
          ),
      ],
    );
  }
}
