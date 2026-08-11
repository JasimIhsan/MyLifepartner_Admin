import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/screens/onboarding/widgets/onboarding_ui_helpers.dart';

class AgePrefStep extends StatefulWidget {
  final RangeValues ageRange;
  final ValueChanged<RangeValues> onAgeRangeChanged;
  final int minAge;
  final int maxAge;

  const AgePrefStep({
    super.key,
    required this.ageRange,
    required this.onAgeRangeChanged,
    this.minAge = 18,
    this.maxAge = 100,
  });

  @override
  State<AgePrefStep> createState() => _AgePrefStepState();
}

class _AgePrefStepState extends State<AgePrefStep> {
  late RangeValues _currentRange;

  @override
  void initState() {
    super.initState();
    _currentRange = widget.ageRange;
  }

  @override
  void didUpdateWidget(covariant AgePrefStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ageRange != widget.ageRange) {
      _currentRange = widget.ageRange;
    }
  }

  void _handleChanged(RangeValues values) {
    int start = values.start.round();
    int end = values.end.round();

    if (start > end) {
      start = end;
    }

    final int oldStart = _currentRange.start.round();
    final int oldEnd = _currentRange.end.round();

    if (start != oldStart || end != oldEnd) {
      HapticFeedback.selectionClick();
    }

    final newRange = RangeValues(start.toDouble(), end.toDouble());
    setState(() {
      _currentRange = newRange;
    });
    widget.onAgeRangeChanged(newRange);
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).primaryColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.02),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Age range',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${_currentRange.start.round()} - ${_currentRange.end.round()}',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary,
                  height: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'years',
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderWithLabels(BuildContext context) {
    const double sliderPadding = 24.0;
    // The screen has 24 horizontal padding on each side (48 total)
    // The slider adds another sliderPadding on each side
    final double trackWidth =
        MediaQuery.of(context).size.width - 48 - (sliderPadding * 2);

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6,
            activeTrackColor: Theme.of(context).primaryColor,
            inactiveTrackColor: Theme.of(context).dividerColor,
            thumbColor: Theme.of(context).primaryColor,
            rangeThumbShape: const CustomRangeSliderThumbShape(
              enabledThumbRadius: 14,
              elevation: 2,
            ),
            overlayColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            overlayShape: const RoundSliderOverlayShape(
              overlayRadius: sliderPadding,
            ),
            tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 0),
          ),
          child: RangeSlider(
            values: _currentRange,
            min: widget.minAge.toDouble(),
            max: widget.maxAge.toDouble(),
            divisions: widget.maxAge - widget.minAge,
            onChanged: _handleChanged,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 20,
          child: Stack(
            clipBehavior: Clip.none,
            children: _buildDynamicLabels(trackWidth, sliderPadding),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildDynamicLabels(double trackWidth, double padding) {
    final List<Widget> labels = [];
    final int min = widget.minAge;
    final int max = widget.maxAge;
    final int start = _currentRange.start.round();
    final int end = _currentRange.end.round();

    double getPosition(int value) {
      if (max == min) return 0.0;
      return (value - min) / (max - min);
    }

    void addLabel(int value, bool isActive) {
      labels.add(
        Positioned(
          left: padding + (trackWidth * getPosition(value)) - 18,
          child: SizedBox(
            width: 36,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? Theme.of(context).primaryColor : Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    addLabel(start, true);
    if (start != end) {
      addLabel(end, true);
    }

    bool isFarEnough(int val) {
      return (val - start).abs() >= 10 && (val - end).abs() >= 10;
    }

    if (isFarEnough(min)) addLabel(min, false);
    if (isFarEnough(max)) addLabel(max, false);

    return labels;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const OnboardingStepTitle(title: "What age range are you looking for?"),
        const SizedBox(height: 15),
        Text(
          "Choose the preferred age range\nyou are open to.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const Spacer(flex: 1),
        _buildSummaryCard(),
        const Spacer(flex: 1),

        // _buildMinMaxLabels(),
        _buildSliderWithLabels(context),
        const Spacer(flex: 2),
      ],
    );
  }
}

class CustomRangeSliderThumbShape extends RangeSliderThumbShape {
  final double enabledThumbRadius;
  final double elevation;

  const CustomRangeSliderThumbShape({
    this.enabledThumbRadius = 14.0,
    this.elevation = 2.0,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(enabledThumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    bool isEnabled = false,
    bool? isOnTop,
    TextDirection? textDirection,
    required SliderThemeData sliderTheme,
    Thumb? thumb,
    bool? isPressed,
  }) {
    final Canvas canvas = context.canvas;
    final double radius = enabledThumbRadius;

    if (elevation > 0) {
      final Path path = Path()
        ..addOval(Rect.fromCircle(center: center, radius: radius));
      canvas.drawShadow(path, Colors.black, elevation, true);
    }

    final Paint fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, fillPaint);

    final Paint borderPaint = Paint()
      ..color = sliderTheme.thumbColor ?? AppColors.primary
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, borderPaint);
  }
}