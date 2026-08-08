import 'package:flutter/material.dart';
import 'package:life_partner_again/screens/onboarding/widgets/onboarding_ui_helpers.dart';

class LookingForStep extends StatelessWidget {
  final String? selectedLookingFor;
  final ValueChanged<String> onLookingForChanged;

  const LookingForStep({
    super.key,
    required this.selectedLookingFor,
    required this.onLookingForChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const OnboardingStepTitle(title: "What is your relationship goal?"),
        const SizedBox(height: 10),
        SizedBox(
          height: 200,
          child: Image.asset(
            'assets/images/onboarding/relationship.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 20),
        OnboardingSelectionTile(
          label: 'Long-term relationship',
          value: 'LONG_TERM_RELATIONSHIP',
          selectedValue: selectedLookingFor,
          onTap: () => onLookingForChanged('LONG_TERM_RELATIONSHIP'),
        ),
        OnboardingSelectionTile(
          label: 'Marriage',
          value: 'MARRIAGE',
          selectedValue: selectedLookingFor,
          onTap: () => onLookingForChanged('MARRIAGE'),
        ),

        // OnboardingSelectionTile(
        //   label: 'Serious companionship',
        //   value: 'SERIOUS_COMPANIONSHIP',
        //   selectedValue: selectedLookingFor,
        //   onTap: () => onLookingForChanged('SERIOUS_COMPANIONSHIP'),
        // ),
      ],
    );
  }
}
