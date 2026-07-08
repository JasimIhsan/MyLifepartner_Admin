import 'package:flutter/material.dart';
import 'package:life_partner_again/screens/onboarding/widgets/onboarding_ui_helpers.dart';

class EducationPrefStep extends StatelessWidget {
  final List<String> selectedEducation;
  final ValueChanged<String> onToggle;

  const EducationPrefStep({
    super.key,
    required this.selectedEducation,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    const options = [
      ('High School', 'HIGH_SCHOOL'),
      ('Vocational / Diploma', 'VOCATIONAL'),
      ("Bachelor's", 'BACHELORS'),
      ("Master's", 'MASTERS'),
      ('Doctorate / PhD', 'DOCTORATE'),
      ('Medical Degree', 'MEDICAL'),
      ('Law Degree', 'LAW'),
      ('Other', 'OTHER'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const OnboardingStepTitle(title: "What education level do you prefer?"),
        const Spacer(),
        Center(
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: options
                .map(
                  (o) => OnboardingLanguageChip(
                    label: o.$1,
                    isSelected: selectedEducation.contains(o.$2),
                    onTap: () => onToggle(o.$2),
                  ),
                )
                .toList(),
          ),
        ),
        const Spacer(),
      ],
    );
  }
}
