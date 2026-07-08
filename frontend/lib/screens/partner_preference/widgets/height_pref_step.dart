import 'package:flutter/material.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/screens/onboarding/widgets/onboarding_ui_helpers.dart';

class HeightPrefStep extends StatelessWidget {
  final RangeValues heightRange;
  final ValueChanged<RangeValues> onHeightRangeChanged;

  const HeightPrefStep({
    super.key,
    required this.heightRange,
    required this.onHeightRangeChanged,
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
        const OnboardingStepTitle(title: "What height range do you prefer?"),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _labelWithSuffix('Min', heightRange.start.round(), 'cm'),
              _labelWithSuffix('Max', heightRange.end.round(), 'cm'),
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
            values: heightRange,
            min: 120,
            max: 220,
            divisions: 100,
            onChanged: onHeightRangeChanged,
          ),
        ),
        const Spacer(),
      ],
    );
  }
}
