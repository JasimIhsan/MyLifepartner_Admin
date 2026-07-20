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
      ('High School', 'HIGH_SCHOOL', Icons.account_balance_outlined),
      (
        'Diploma / Certificate',
        'DIPLOMA_CERTIFICATE',
        Icons.workspace_premium_outlined,
      ),
      ("Bachelor's Degree", 'BACHELORS', Icons.school_outlined),
      ("Master's Degree", 'MASTERS', Icons.history_edu_outlined),
      ('Doctorate / PhD', 'DOCTORATE', Icons.military_tech_outlined),
      ('Other', 'OTHER', Icons.more_horiz_outlined),
    ];
    return Column(
      children: [
        const OnboardingStepTitle(title: "What's your\nhighest education?"),
        const SizedBox(height: 10),
        SizedBox(
          height: 140,
          child: Image.asset(
            'assets/images/onboarding/education.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 20),
        for (final (label, value, icon) in options)
          OnboardingSelectionTile(
            label: label,
            value: value,
            selectedValue: selectedEducation,
            icon: icon,
            onTap: () => onEducationChanged(value),
          ),
        const SizedBox(height: 20),
      ],
    );
  }
}
