import 'package:flutter/material.dart';
import 'package:life_partner_again/screens/onboarding/widgets/onboarding_ui_helpers.dart';

class OccupationPrefStep extends StatelessWidget {
  final List<String> selectedOccupation;
  final ValueChanged<String> onToggle;

  const OccupationPrefStep({
    super.key,
    required this.selectedOccupation,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    const options = [
      ('Technology / IT', 'Technology / IT'),
      ('Healthcare', 'Healthcare / Medical'),
      ('Education', 'Education / Academia'),
      ('Finance', 'Finance / Business'),
      ('Law / Legal', 'Law / Legal'),
      ('Arts / Creative', 'Arts / Entertainment'),
      ('Engineering', 'Engineering / Science'),
      ('Sales / Marketing', 'Sales / Marketing'),
      ('Government', 'Government / Public Service'),
      ('Trades', 'Manual Labor / Trades'),
      ('Entrepreneur', 'Self-Employed / Entrepreneur'),
      ('Other', 'Other'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const OnboardingStepTitle(title: "Any industry preference?"),
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
                    isSelected: selectedOccupation.contains(o.$2),
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
