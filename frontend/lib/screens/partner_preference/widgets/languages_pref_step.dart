import 'package:flutter/material.dart';
import 'package:life_partner_again/screens/onboarding/widgets/onboarding_ui_helpers.dart';

class LanguagesPrefStep extends StatelessWidget {
  final List<String> selectedLanguages;
  final ValueChanged<String> onToggle;

  const LanguagesPrefStep({
    super.key,
    required this.selectedLanguages,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    const langs = [
      'English',
      'French',
      'Spanish',
      'German',
      'Italian',
      'Portuguese',
      'Dutch',
      'Russian',
      'Polish',
      'Ukrainian',
      'Romanian',
      'Greek',
      'Turkish',
      'Arabic',
      'Punjabi',
      'Mandarin Chinese',
      'Cantonese',
      'Tagalog',
      'Persian',
      'Urdu',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const OnboardingStepTitle(title: "Any language preference?"),
        const Spacer(),
        Center(
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: langs
                .map(
                  (l) => OnboardingLanguageChip(
                    label: l,
                    isSelected: selectedLanguages.contains(l),
                    onTap: () => onToggle(l),
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
