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
      ('Separated', 'SEPARATED'),
      ('Divorced', 'DIVORCED'),
      ('Widowed', 'WIDOWED'),
      ('Awaiting Divorce', 'AWAITING_DIVORCE'),
    ];

    return Column(
      children: [
        const OnboardingStepTitle(title: "What's your marital status?"),
        const SizedBox(height: 10),
        SizedBox(
          height: 150,
          child: Image.asset(
            'assets/images/onboarding/marital_status.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 20),
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
