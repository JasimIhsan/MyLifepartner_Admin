import 'package:flutter/material.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/screens/onboarding/widgets/onboarding_ui_helpers.dart';

class AgePrefStep extends StatelessWidget {
  final RangeValues ageRange;
  final ValueChanged<RangeValues> onAgeRangeChanged;

  const AgePrefStep({
    super.key,
    required this.ageRange,
    required this.onAgeRangeChanged,
  });

  Widget _labelWithSuffix(String label, int value, String suffix) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          '$value $suffix',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const OnboardingStepTitle(title: "What age range are you looking for?"),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _labelWithSuffix('Minimum', ageRange.start.round(), 'yrs'),
              _labelWithSuffix('Maximum', ageRange.end.round(), 'yrs'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.borderColor,
            thumbColor: AppColors.primary,
            rangeThumbShape: const RoundRangeSliderThumbShape(
              enabledThumbRadius: 10,
            ),
            overlayColor: AppColors.primary.withValues(alpha: 0.2),
          ),
          child: RangeSlider(
            values: ageRange,
            min: 18,
            max: 80,
            divisions: 62,
            onChanged: onAgeRangeChanged,
          ),
        ),
        const Spacer(),
      ],
    );
  }
}
