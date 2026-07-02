import 'package:flutter/material.dart';
import 'package:life_partner_again/core/app_colors.dart';

class OnboardingStepTitle extends StatelessWidget {
  final String title;
  const OnboardingStepTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          height: 1.2,
        ),
      ),
    );
  }
}

class OnboardingSectionLabel extends StatelessWidget {
  final String text;
  const OnboardingSectionLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class OnboardingInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final TextCapitalization capitalization;
  final bool isReadonly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;

  const OnboardingInputField({
    super.key,
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.capitalization = TextCapitalization.words,
    this.isReadonly = false,
    this.onTap,
    this.suffixIcon,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0E6E6), width: 1),
      ),
      child: TextField(
        controller: controller,
        readOnly: isReadonly,
        onTap: onTap,
        keyboardType: keyboardType,
        textCapitalization: capitalization,
        onChanged: onChanged,
        style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          border: InputBorder.none,
          suffixIcon: suffixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: suffixIcon,
                )
              : null,
        ),
      ),
    );
  }
}

class OnboardingSelectionTile extends StatelessWidget {
  final String label;
  final String value;
  final String? selectedValue;
  final VoidCallback onTap;
  final String? emoji;

  const OnboardingSelectionTile({
    super.key,
    required this.label,
    required this.value,
    required this.selectedValue,
    required this.onTap,
    this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedValue == value;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFF0E6E6),
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 14),
              ),
          ],
        ),
      ),
    );
  }
}

class OnboardingLanguageChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const OnboardingLanguageChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        margin: const EdgeInsets.only(right: 10, bottom: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFF5F2F2),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              const Icon(Icons.check_circle, color: Colors.white, size: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class OnboardingContinueButton extends StatelessWidget {
  final bool canProceed;
  final bool isLoading;
  final bool isLastStep;
  final VoidCallback onNext;

  const OnboardingContinueButton({
    super.key,
    required this.canProceed,
    required this.isLoading,
    required this.isLastStep,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: ElevatedButton(
        onPressed: canProceed ? onNext : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                isLastStep ? 'Finish' : 'Continue',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}
