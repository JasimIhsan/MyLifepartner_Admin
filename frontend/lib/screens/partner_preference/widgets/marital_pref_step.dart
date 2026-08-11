import 'package:flutter/material.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/screens/onboarding/widgets/onboarding_ui_helpers.dart';

class MaritalPrefStep extends StatelessWidget {
  final List<String> selectedMaritalStatus;
  final ValueChanged<String> onToggle;

  const MaritalPrefStep({
    super.key,
    required this.selectedMaritalStatus,
    required this.onToggle,
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const OnboardingStepTitle(
          title: "Who would you consider matching with?",
        ),
        const SizedBox(height: 15),
        Text(
          "You can select more than one",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color:
                Theme.of(context).textTheme.bodyMedium?.color ??
                AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 200,
          child: Image.asset(
            'assets/images/onboarding/emotional_readiness.png',
            fit: BoxFit.contain,
          ),
        ),
        // const Spacer(),
        const SizedBox(height: 40),

        Center(
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: options
                .map(
                  (o) => OnboardingLanguageChip(
                    label: o.$1,
                    isSelected: selectedMaritalStatus.contains(o.$2),
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
