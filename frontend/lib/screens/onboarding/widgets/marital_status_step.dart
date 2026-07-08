import 'package:flutter/material.dart';
import 'package:life_partner_again/screens/onboarding/widgets/onboarding_ui_helpers.dart';

class MaritalStatusStep extends StatelessWidget {
  final String? selectedMaritalStatus;
  final ValueChanged<String> onMaritalStatusChanged;

  const MaritalStatusStep({
    super.key,
    required this.selectedMaritalStatus,
    required this.onMaritalStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    const options = [
      ('Divorced', 'DIVORCED'),
      ('Widowed', 'WIDOWED'),
      ('Legally Separated', 'LEGALLY_SEPARATED'),
    ];
    return Column(
      children: [
        const OnboardingStepTitle(title: "What's your marital status?"),
        const SizedBox(height: 10),
        for (final (label, value) in options)
          OnboardingSelectionTile(
            label: label,
            value: value,
            selectedValue: selectedMaritalStatus,
            onTap: () => onMaritalStatusChanged(value),
          ),
      ],
    );
  }
}
