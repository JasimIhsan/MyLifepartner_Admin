import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/screens/onboarding/widgets/onboarding_ui_helpers.dart';
import 'package:life_partner_again/screens/onboarding/widgets/country_picker_sheet.dart';
import 'package:country_flags/country_flags.dart';

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
    final cityRegex = RegExp(r"^[a-zA-Z\s\-\'\.]+$");

    String? getCityError() {
      if (cityCtrl.text.isNotEmpty && !cityRegex.hasMatch(cityCtrl.text)) {
        return "Only letters, spaces, hyphens, periods, and apostrophes allowed";
      }
      return null;
    }

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
                if (country != null && kCountries.any((c) => c.name == country)) ...[
                  CountryFlag.fromCountryCode(
                    kCountries.firstWhere((c) => c.name == country).code,
                    height: 18,
                    width: 26,
                  ),
                  const SizedBox(width: 8),
                ],
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
          errorText: getCityError(),
          inputFormatters: [LengthLimitingTextInputFormatter(50)],
          onChanged: onCityChanged,
        ),
      ],
    );
  }
}
