import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:life_partner_again/screens/onboarding/widgets/onboarding_ui_helpers.dart';

class BioStep extends StatelessWidget {
  final TextEditingController bioCtrl;
  final ValueChanged<String> onBioChanged;

  const BioStep({
    super.key,
    required this.bioCtrl,
    required this.onBioChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const OnboardingStepTitle(title: "Tell us about yourself"),
        const SizedBox(height: 20),
        const OnboardingSectionLabel(text: "Write a short bio (min 50 characters)"),
        OnboardingInputField(
          controller: bioCtrl,
          hint: "Describe your personality, interests, and what you are looking for in a partner...",
          keyboardType: TextInputType.multiline,
          capitalization: TextCapitalization.sentences,
          inputFormatters: [LengthLimitingTextInputFormatter(1000)],
          onChanged: onBioChanged,
          minLines: 4,
          maxLines: 8,
          errorText: bioCtrl.text.isNotEmpty && bioCtrl.text.trim().length < 50
              ? "Bio must be at least 50 characters (current: ${bioCtrl.text.trim().length})"
              : null,
        ),
      ],
    );
  }
}
