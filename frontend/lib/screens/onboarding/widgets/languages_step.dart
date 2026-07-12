import 'package:flutter/material.dart';
import 'package:life_partner_again/screens/onboarding/widgets/onboarding_ui_helpers.dart';

class LanguagesStep extends StatelessWidget {
  final List<String> selectedLanguages;
  final ValueChanged<String> onLanguageToggled;

  const LanguagesStep({
    super.key,
    required this.selectedLanguages,
    required this.onLanguageToggled,
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
      children: [
        const OnboardingStepTitle(
          title: "What languages are you comfortable with?",
        ),
        const SizedBox(height: 20),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: langs
              .map(
                (l) => OnboardingLanguageChip(
                  label: l,
                  isSelected: selectedLanguages.contains(l),
                  onTap: () => onLanguageToggled(l),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
