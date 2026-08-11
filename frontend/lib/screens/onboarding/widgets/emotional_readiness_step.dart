import 'package:flutter/material.dart';
import 'package:life_partner_again/screens/onboarding/widgets/onboarding_ui_helpers.dart';

class EmotionalReadinessStep extends StatelessWidget {
  final String? selectedReadiness;
  final ValueChanged<String> onReadinessChanged;

  const EmotionalReadinessStep({
    super.key,
    required this.selectedReadiness,
    required this.onReadinessChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const OnboardingStepTitle(
          title: "Are you ready to find your life partner again?",
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 200,
          child: Image.asset(
            'assets/images/onboarding/emotional_readiness.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 20),
        OnboardingSelectionTile(
          label: "Yes, I'm ready",
          value: 'YES',
          selectedValue: selectedReadiness,
          emoji: '🥰',
          onTap: () => onReadinessChanged('YES'),
        ),
        OnboardingSelectionTile(
          label: "I'm open to it",
          value: 'MOSTLY',
          selectedValue: selectedReadiness,
          emoji: '😊',
          onTap: () => onReadinessChanged('MOSTLY'),
        ),
        OnboardingSelectionTile(
          label: "Not sure yet",
          value: 'NOT_SURE',
          selectedValue: selectedReadiness,
          emoji: '🤔',
          onTap: () => onReadinessChanged('NOT_SURE'),
        ),
      ],
    );
  }
}
