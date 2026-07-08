import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/screens/onboarding/widgets/onboarding_ui_helpers.dart';

class BasicInfoStep extends StatelessWidget {
  final TextEditingController firstNameCtrl;
  final TextEditingController lastNameCtrl;
  final DateTime? dateOfBirth;
  final ValueChanged<String> onFirstNameChanged;
  final ValueChanged<String> onLastNameChanged;
  final ValueChanged<DateTime> onDateOfBirthChanged;

  const BasicInfoStep({
    super.key,
    required this.firstNameCtrl,
    required this.lastNameCtrl,
    required this.dateOfBirth,
    required this.onFirstNameChanged,
    required this.onLastNameChanged,
    required this.onDateOfBirthChanged,
  });

  @override
  Widget build(BuildContext context) {
    final nameRegex = RegExp(r"^[a-zA-Z\s\-\']+$");

    String? getFirstNameError() {
      if (firstNameCtrl.text.isNotEmpty && !nameRegex.hasMatch(firstNameCtrl.text)) {
        return "Only letters, spaces, hyphens, and apostrophes allowed";
      }
      return null;
    }

    String? getLastNameError() {
      if (lastNameCtrl.text.isNotEmpty && !nameRegex.hasMatch(lastNameCtrl.text)) {
        return "Only letters, spaces, hyphens, and apostrophes allowed";
      }
      return null;
    }

    return Column(
      children: [
        const OnboardingStepTitle(title: "Hey! Let's talk little about you"),
        const SizedBox(height: 20),
        const OnboardingSectionLabel(text: "First Name"),
        OnboardingInputField(
          controller: firstNameCtrl,
          hint: 'First Name',
          errorText: getFirstNameError(),
          inputFormatters: [LengthLimitingTextInputFormatter(50)],
          onChanged: onFirstNameChanged,
        ),
        const SizedBox(height: 10),
        const OnboardingSectionLabel(text: "Last Name"),
        OnboardingInputField(
          controller: lastNameCtrl,
          hint: 'Last Name',
          errorText: getLastNameError(),
          inputFormatters: [LengthLimitingTextInputFormatter(50)],
          onChanged: onLastNameChanged,
        ),
        const SizedBox(height: 10),
        const OnboardingSectionLabel(text: "When is your date of birth?"),
        OnboardingInputField(
          controller: TextEditingController(
            text: dateOfBirth == null
                ? ''
                : '${dateOfBirth!.day}/${dateOfBirth!.month}/${dateOfBirth!.year}',
          ),
          hint: 'DD/MM/YYYY',
          isReadonly: true,
          suffixIcon: const Icon(
            Icons.calendar_today_rounded,
            color: AppColors.primary,
            size: 20,
          ),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: dateOfBirth ??
                  DateTime.now().subtract(const Duration(days: 365 * 25)),
              firstDate: DateTime(1920),
              lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
            );
            if (picked != null) {
              onDateOfBirthChanged(picked);
            }
          },
        ),
      ],
    );
  }
}
