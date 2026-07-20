import 'package:flutter/material.dart';
import 'package:life_partner_again/screens/onboarding/widgets/onboarding_ui_helpers.dart';

class ChildrenStep extends StatelessWidget {
  final String? selectedChildrenStatus;
  final ValueChanged<String> onChildrenStatusChanged;

  const ChildrenStep({
    super.key,
    required this.selectedChildrenStatus,
    required this.onChildrenStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const OnboardingStepTitle(title: "Do you have children?"),
        const SizedBox(height: 10),
        SizedBox(
          height: 150,
          child: Image.asset(
            'assets/images/onboarding/children.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 20),
        OnboardingSelectionTile(
          label: 'Yes, living with me',
          value: 'LIVING_WITH_ME',
          selectedValue: selectedChildrenStatus,
          onTap: () => onChildrenStatusChanged('LIVING_WITH_ME'),
        ),
        OnboardingSelectionTile(
          label: 'Yes, not living with me',
          value: 'NOT_LIVING_WITH_ME',
          selectedValue: selectedChildrenStatus,
          onTap: () => onChildrenStatusChanged('NOT_LIVING_WITH_ME'),
        ),
        OnboardingSelectionTile(
          label: 'No',
          value: 'NO_CHILDREN',
          selectedValue: selectedChildrenStatus,
          onTap: () => onChildrenStatusChanged('NO_CHILDREN'),
        ),
      ],
    );
  }
}
