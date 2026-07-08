import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:life_partner_again/screens/onboarding/widgets/onboarding_ui_helpers.dart';

class ProfessionStep extends StatelessWidget {
  final TextEditingController professionCtrl;
  final ValueChanged<String> onProfessionChanged;

  const ProfessionStep({
    super.key,
    required this.professionCtrl,
    required this.onProfessionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final professionRegex = RegExp(r"^[a-zA-Z0-9\s\-\'\.\,]+$");

    String? getProfessionError() {
      if (professionCtrl.text.isNotEmpty && !professionRegex.hasMatch(professionCtrl.text)) {
        return "Only letters, numbers, spaces, and basic punctuation allowed";
      }
      return null;
    }

    return Column(
      children: [
        const OnboardingStepTitle(title: "What do you do for work?"),
        const SizedBox(height: 20),
        OnboardingInputField(
          controller: professionCtrl,
          hint: 'e.g. Software Developer, Doctor…',
          capitalization: TextCapitalization.sentences,
          errorText: getProfessionError(),
          inputFormatters: [LengthLimitingTextInputFormatter(100)],
          onChanged: onProfessionChanged,
        ),
      ],
    );
  }
}
