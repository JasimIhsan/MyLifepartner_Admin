import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:life_partner_again/core/app_colors.dart';

Future<void> showDynamicLoadingUI(
  BuildContext context,
  ValueNotifier<bool> isCompleted,
) {
  if (kIsWeb) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: DynamicLoadingUI(isBottomSheet: false, isCompleted: isCompleted),
      ),
    );
  } else {
    return showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => PopScope(
        canPop: false,
        child: DynamicLoadingUI(isBottomSheet: true, isCompleted: isCompleted),
      ),
    );
  }
}

class DynamicLoadingUI extends StatefulWidget {
  final bool isBottomSheet;
  final ValueNotifier<bool> isCompleted;
  const DynamicLoadingUI({
    super.key,
    required this.isBottomSheet,
    required this.isCompleted,
  });

  @override
  State<DynamicLoadingUI> createState() => _DynamicLoadingUIState();
}

class _DynamicLoadingUIState extends State<DynamicLoadingUI> {
  final List<String> _messages = [
    "Preparing your premium experience...",
    "Unlocking new ways to connect...",
    "Gathering your exclusive perks...",
    "Setting up your spotlight...",
    "Sprinkling a little extra magic...",
    "Getting everything just right...",
    "Almost ready for your perfect match...",
  ];
  int _currentIndex = 0;
  Timer? _timer;

  double _progressTarget = 0.95;
  int _durationSeconds = 15;

  @override
  void initState() {
    super.initState();
    widget.isCompleted.addListener(_onCompletedChanged);

    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted && !widget.isCompleted.value) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _messages.length;
        });
      }
    });
  }

  void _onCompletedChanged() {
    if (widget.isCompleted.value && mounted) {
      setState(() {
        _progressTarget = 1.0;
        _durationSeconds = 1;
      });

      _timer?.cancel();

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  @override
  void dispose() {
    widget.isCompleted.removeListener(_onCompletedChanged);
    _timer?.cancel();
    super.dispose();
  }

  Widget _buildStepItem(IconData icon, String text) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool completed = widget.isCompleted.value;

    final content = Container(
      width: widget.isBottomSheet ? double.infinity : 400,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: widget.isBottomSheet
            ? const BorderRadius.vertical(top: Radius.circular(32))
            : BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 30,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isBottomSheet)
            Container(
              width: 48,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

          Image.asset(
            'assets/images/illustrations/gift.png',
            height: 180,
            fit: BoxFit.contain,
          ),

          const SizedBox(height: 24),

          const Text(
            'Unwrapping amazing\nbenefits for you...',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.2),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Text(
              completed
                  ? "All perks successfully unlocked!"
                  : _messages[_currentIndex],
              key: ValueKey<String>(
                completed ? "completed" : _currentIndex.toString(),
              ),
              style: TextStyle(
                fontSize: 16,
                fontWeight: completed ? FontWeight.w700 : FontWeight.w500,
                color: completed ? AppColors.primary : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 32),

          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: _progressTarget),
            duration: Duration(seconds: _durationSeconds),
            curve: Curves.easeOutQuint,
            builder: (context, value, child) {
              return Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: value,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                        minHeight: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${(value * 100).toInt()}%',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStepItem(Icons.favorite_rounded, "Fetching perks"),
              Container(width: 1, height: 24, color: Colors.grey.shade200),
              _buildStepItem(Icons.card_giftcard_rounded, "Almost there"),
              Container(width: 1, height: 24, color: Colors.grey.shade200),
              _buildStepItem(
                completed ? Icons.check_circle_rounded : Icons.star_rounded,
                completed ? "All done!" : "Preparing magic",
              ),
            ],
          ),

          const SizedBox(height: 32),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                const Text('💖', style: TextStyle(fontSize: 22)),
                const Spacer(),
                const Text(
                  'Thanks for being awesome!',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.favorite_rounded,
                  color: AppColors.primary.withValues(alpha: 0.8),
                  size: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (widget.isBottomSheet) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [content],
        ),
      );
    } else {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(child: content),
      );
    }
  }
}
