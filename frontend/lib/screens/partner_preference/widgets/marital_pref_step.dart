import 'package:flutter/material.dart';
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
      ('Divorced', 'DIVORCED'),
      ('Widowed', 'WIDOWED'),
      ('Annulled', 'ANNULLED'),
      ('Legally Separated', 'LEGALLY_SEPARATED'),
      ('Awaiting Divorce', 'AWATING_DIVORCE'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const OnboardingStepTitle(title: "Which background are you open to?"),
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
