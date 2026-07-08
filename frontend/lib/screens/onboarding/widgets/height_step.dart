import 'package:flutter/material.dart';
import 'package:life_partner_again/screens/onboarding/widgets/onboarding_ui_helpers.dart';

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

    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallDevice = screenHeight < 700;

    final pickerHeight = isSmallDevice ? 240.0 : 320.0;
    final itemHeight = isSmallDevice ? 55.0 : 65.0;
    final spacing = isSmallDevice ? 20.0 : 60.0;

    final boxWidth = isSmallDevice ? 220.0 : 260.0;
    final boxHeight = isSmallDevice ? 48.0 : 56.0;

    final selectedFontSize = isSmallDevice ? 20.0 : 24.0;
    final unselectedFontSize = isSmallDevice ? 17.0 : 19.0;

    return Column(
      children: [
        const OnboardingStepTitle(title: "What is your height?"),
        SizedBox(height: spacing),
        SizedBox(
          height: pickerHeight,
          child: ListWheelScrollView.useDelegate(
            itemExtent: itemHeight,
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
                    width: isSelected ? boxWidth : boxWidth - 60,
                    height: boxHeight,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.black : Colors.transparent,
                      borderRadius: BorderRadius.circular(isSmallDevice ? 12 : 16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "${formatImperial(cm)} ($cm cm)",
                      style: TextStyle(
                        fontSize: isSelected ? selectedFontSize : unselectedFontSize,
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
        SizedBox(height: spacing),
      ],
    );
  }
}
