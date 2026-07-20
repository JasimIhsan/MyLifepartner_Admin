import 'package:flutter/material.dart';
import 'package:life_partner_again/screens/onboarding/widgets/onboarding_ui_helpers.dart';

class GenderStep extends StatelessWidget {
  final String? selectedGender;
  final ValueChanged<String> onGenderChanged;

  const GenderStep({
    super.key,
    required this.selectedGender,
    required this.onGenderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const OnboardingStepTitle(title: "What's your gender?"),
        const SizedBox(height: 10),
        SizedBox(
          height: 160,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: selectedGender == 'MALE'
                ? Image.asset(
                    'assets/images/onboarding/gender_male.png',
                    key: const ValueKey('male'),
                    fit: BoxFit.contain,
                  )
                : selectedGender == 'FEMALE'
                    ? Image.asset(
                        'assets/images/onboarding/gender_female.png',
                        key: const ValueKey('female'),
                        fit: BoxFit.contain,
                      )
                    : Row(
                        key: const ValueKey('both'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/onboarding/gender_male.png',
                            height: 120,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 20),
                          Image.asset(
                            'assets/images/onboarding/gender_female.png',
                            height: 120,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
          ),
        ),
        const SizedBox(height: 20),
        OnboardingSelectionTile(
          label: 'Man',
          value: 'MALE',
          selectedValue: selectedGender,
          onTap: () => onGenderChanged('MALE'),
        ),
        OnboardingSelectionTile(
          label: 'Woman',
          value: 'FEMALE',
          selectedValue: selectedGender,
          onTap: () => onGenderChanged('FEMALE'),
        ),
      ],
    );
  }
}
