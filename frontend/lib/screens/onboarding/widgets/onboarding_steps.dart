import 'package:flutter/material.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/screens/onboarding/widgets/onboarding_ui_helpers.dart';
import 'package:life_partner_again/screens/onboarding/widgets/country_picker_sheet.dart';
import 'package:country_flags/country_flags.dart';

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
    return Column(
      children: [
        const OnboardingStepTitle(title: "Hey! Let's talk little about you"),
        const SizedBox(height: 20),
        const OnboardingSectionLabel(text: "First Name"),
        OnboardingInputField(
          controller: firstNameCtrl,
          hint: 'First Name',
          onChanged: onFirstNameChanged,
        ),
        const SizedBox(height: 10),
        const OnboardingSectionLabel(text: "Last Name"),
        OnboardingInputField(
          controller: lastNameCtrl,
          hint: 'Last Name',
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

class MaritalStatusStep extends StatelessWidget {
  final String? selectedMaritalStatus;
  final ValueChanged<String> onMaritalStatusChanged;

  const MaritalStatusStep({
    super.key,
    required this.selectedMaritalStatus,
    required this.onMaritalStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    const options = [
      ('Divorced', 'DIVORCED'),
      ('Widowed', 'WIDOWED'),
      ('Legally Separated', 'LEGALLY_SEPARATED'),
    ];
    return Column(
      children: [
        const OnboardingStepTitle(title: "What's your marital status?"),
        const SizedBox(height: 10),
        for (final (label, value) in options)
          OnboardingSelectionTile(
            label: label,
            value: value,
            selectedValue: selectedMaritalStatus,
            onTap: () => onMaritalStatusChanged(value),
          ),
      ],
    );
  }
}

class LocationStep extends StatelessWidget {
  final String? country;
  final TextEditingController cityCtrl;
  final ValueChanged<String> onCountryChanged;
  final ValueChanged<String> onCityChanged;

  const LocationStep({
    super.key,
    required this.country,
    required this.cityCtrl,
    required this.onCountryChanged,
    required this.onCityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const OnboardingStepTitle(title: "Where do you live?"),
        const SizedBox(height: 10),
        const OnboardingSectionLabel(text: "Country"),
        GestureDetector(
          onTap: () async {
            final selected = await showModalBottomSheet<String>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (_) => CountryPickerSheet(selected: country),
            );
            if (selected != null) {
              onCountryChanged(selected);
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF0E6E6), width: 1),
            ),
            child: Row(
              children: [
                if (country != null)
                  CountryFlag.fromCountryCode(
                    kCountries.firstWhere((c) => c.name == country).code,
                    height: 18,
                    width: 26,
                  ),
                if (country != null) const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    country ?? 'Select your country',
                    style: TextStyle(
                      fontSize: 16,
                      color: country != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSecondary,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        const OnboardingSectionLabel(text: "City"),
        OnboardingInputField(
          controller: cityCtrl,
          hint: 'Enter your city',
          onChanged: onCityChanged,
        ),
      ],
    );
  }
}

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
        const OnboardingStepTitle(title: "Are you ready for a serious relationship?"),
        const SizedBox(height: 20),
        OnboardingSelectionTile(
          label: "Yes, I'm ready",
          value: 'YES',
          selectedValue: selectedReadiness,
          emoji: '🥰',
          onTap: () => onReadinessChanged('YES'),
        ),
        OnboardingSelectionTile(
          label: "I think so",
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
      'English', 'French', 'Spanish', 'German', 'Italian', 'Portuguese',
      'Dutch', 'Russian', 'Polish', 'Ukrainian', 'Romanian', 'Greek',
      'Turkish', 'Arabic', 'Punjabi', 'Mandarin Chinese', 'Cantonese',
      'Tagalog', 'Persian', 'Urdu',
    ];
    return Column(
      children: [
        const OnboardingStepTitle(title: "What languages are you comfortable with?"),
        const SizedBox(height: 20),
        Wrap(
          alignment: WrapAlignment.center,
          children: langs.map((l) => OnboardingLanguageChip(
            label: l,
            isSelected: selectedLanguages.contains(l),
            onTap: () => onLanguageToggled(l),
          )).toList(),
        ),
      ],
    );
  }
}

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
        const SizedBox(height: 32),
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

class HeightStep extends StatelessWidget {
  final int? heightCm;
  final ValueChanged<int> onHeightChanged;

  const HeightStep({
    super.key,
    required this.heightCm,
    required this.onHeightChanged,
  });

  @override
  Widget build(BuildContext context) {
    const minHeight = 140;
    const maxHeight = 220;
    final heights = List.generate(
      maxHeight - minHeight + 1,
      (i) => minHeight + i,
    );

    String formatImperial(int cm) {
      double totalInches = cm / 2.54;
      int feet = (totalInches / 12).floor();
      int inches = (totalInches % 12).round();
      if (inches == 12) {
        feet++;
        inches = 0;
      }
      return "$feet'$inches\"";
    }

    final currentHeight = heightCm ?? 170;

    return Column(
      children: [
        const OnboardingStepTitle(title: "What is your height?"),
        const SizedBox(height: 20),
        SizedBox(
          height: 220,
          child: ListWheelScrollView.useDelegate(
            itemExtent: 55,
            perspective: 0.005,
            diameterRatio: 1.5,
            physics: const FixedExtentScrollPhysics(),
            controller: FixedExtentScrollController(
              initialItem: currentHeight - minHeight,
            ),
            onSelectedItemChanged: (index) {
              onHeightChanged(minHeight + index);
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: heights.length,
              builder: (context, index) {
                final cm = heights[index];
                final isSelected = currentHeight == cm;
                return Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isSelected ? 220 : 180,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.black : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "${formatImperial(cm)} ($cm cm)",
                      style: TextStyle(
                        fontSize: isSelected ? 20 : 17,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.grey[400],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

class LookingForStep extends StatelessWidget {
  final String? selectedLookingFor;
  final ValueChanged<String> onLookingForChanged;

  const LookingForStep({
    super.key,
    required this.selectedLookingFor,
    required this.onLookingForChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const OnboardingStepTitle(title: "What are you looking for?"),
        const SizedBox(height: 20),
        OnboardingSelectionTile(
          label: 'Marriage',
          value: 'MARRIAGE',
          selectedValue: selectedLookingFor,
          onTap: () => onLookingForChanged('MARRIAGE'),
        ),
        OnboardingSelectionTile(
          label: 'Long-term commitment',
          value: 'LONG_TERM_RELATIONSHIP',
          selectedValue: selectedLookingFor,
          onTap: () => onLookingForChanged('LONG_TERM_RELATIONSHIP'),
        ),
        OnboardingSelectionTile(
          label: 'Serious companionship',
          value: 'SERIOUS_COMPANIONSHIP',
          selectedValue: selectedLookingFor,
          onTap: () => onLookingForChanged('SERIOUS_COMPANIONSHIP'),
        ),
      ],
    );
  }
}

class EducationStep extends StatelessWidget {
  final String? selectedEducation;
  final ValueChanged<String> onEducationChanged;

  const EducationStep({
    super.key,
    required this.selectedEducation,
    required this.onEducationChanged,
  });

  @override
  Widget build(BuildContext context) {
    const options = [
      ('High School', 'HIGH_SCHOOL'),
      ("Bachelor's Degree", 'BACHELORS'),
      ("Master's Degree", 'MASTERS'),
      ('Doctorate / PhD', 'DOCTORATE'),
      ('Other', 'OTHER'),
    ];
    return Column(
      children: [
        const OnboardingStepTitle(title: "What's your highest education?"),
        const SizedBox(height: 20),
        for (final (label, value) in options)
          OnboardingSelectionTile(
            label: label,
            value: value,
            selectedValue: selectedEducation,
            onTap: () => onEducationChanged(value),
          ),
      ],
    );
  }
}

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
    return Column(
      children: [
        const OnboardingStepTitle(title: "What do you do for work?"),
        const SizedBox(height: 20),
        OnboardingInputField(
          controller: professionCtrl,
          hint: 'e.g. Software Developer, Doctor…',
          capitalization: TextCapitalization.sentences,
          onChanged: onProfessionChanged,
        ),
      ],
    );
  }
}

class HabitsStep extends StatelessWidget {
  final String? drinkingHabit;
  final String? smokingHabit;
  final ValueChanged<String> onDrinkingChanged;
  final ValueChanged<String> onSmokingChanged;

  const HabitsStep({
    super.key,
    required this.drinkingHabit,
    required this.smokingHabit,
    required this.onDrinkingChanged,
    required this.onSmokingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const OnboardingStepTitle(title: "A few more details"),
        const SizedBox(height: 30),
        const OnboardingSectionLabel(text: "Do you drink?"),
        Row(
          children: [
            Expanded(
              child: OnboardingSelectionTile(
                label: 'Yes',
                value: 'YES',
                selectedValue: drinkingHabit,
                onTap: () => onDrinkingChanged('YES'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OnboardingSelectionTile(
                label: 'No',
                value: 'NO',
                selectedValue: drinkingHabit,
                onTap: () => onDrinkingChanged('NO'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const OnboardingSectionLabel(text: "Do you smoke?"),
        Row(
          children: [
            Expanded(
              child: OnboardingSelectionTile(
                label: 'Yes',
                value: 'YES',
                selectedValue: smokingHabit,
                onTap: () => onSmokingChanged('YES'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OnboardingSelectionTile(
                label: 'No',
                value: 'NO',
                selectedValue: smokingHabit,
                onTap: () => onSmokingChanged('NO'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
