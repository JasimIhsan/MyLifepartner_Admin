import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
          color:
              Theme.of(context).textTheme.bodyLarge?.color ??
              AppColors.textPrimary,
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
          color:
              Theme.of(context).textTheme.bodyLarge?.color ??
              AppColors.textPrimary,
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
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final String? errorText;

  final int? minLines;
  final int? maxLines;

  const OnboardingInputField({
    super.key,
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.capitalization = TextCapitalization.words,
    this.isReadonly = false,
    this.onTap,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.inputFormatters,
    this.errorText,
    this.minLines = 1,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: controller,
          readOnly: isReadonly,
          onTap: onTap,
          keyboardType: keyboardType,
          textCapitalization: capitalization,
          onChanged: onChanged,
          inputFormatters: inputFormatters,
          minLines: minLines,
          maxLines: maxLines,
          style: TextStyle(
            fontSize: 16,
            color:
                Theme.of(context).textTheme.bodyLarge?.color ??
                AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color:
                  Theme.of(context).textTheme.bodyMedium?.color ??
                  AppColors.textSecondary,
              fontSize: 16,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
            filled: true,
            fillColor: Theme.of(context).cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: errorText != null
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).dividerColor,
                width: errorText != null ? 1.5 : 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: errorText != null
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).dividerColor,
                width: errorText != null ? 1.5 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: errorText != null
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).primaryColor,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
                width: 1.5,
              ),
            ),
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: suffixIcon,
                  )
                : null,
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 6),
            child: Text(
              errorText!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class OnboardingSelectionTile extends StatelessWidget {
  final String label;
  final String value;
  final String? selectedValue;
  final VoidCallback onTap;
  final String? emoji;
  final IconData? icon;

  const OnboardingSelectionTile({
    super.key,
    required this.label,
    required this.value,
    required this.selectedValue,
    required this.onTap,
    this.emoji,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedValue == value;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final borderColor = isDarkMode ? theme.dividerColor : theme.dividerColor;
    final cardColor = theme.cardColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        decoration: BoxDecoration(
          color: cardColor,
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : borderColor,
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: theme.textTheme.bodyLarge?.color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: theme.colorScheme.onPrimary,
                  size: 14,
                ),
              )
            else
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.dividerColor, width: 1.5),
                ),
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
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Theme.of(context).dividerColor,
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).textTheme.bodyLarge?.color ??
                          AppColors.textPrimary,
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.check_circle_rounded,
                color: Theme.of(context).primaryColor,
                size: 16,
              ),
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
  final String? label;
  final VoidCallback onNext;

  const OnboardingContinueButton({
    super.key,
    required this.canProceed,
    required this.isLoading,
    required this.isLastStep,
    this.label,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: ElevatedButton(
        onPressed: (canProceed && !isLoading) ? onNext : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          disabledBackgroundColor: Theme.of(
            context,
          ).primaryColor.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.onPrimary,
                  strokeWidth: 2,
                ),
              )
            : Text(
                label ?? (isLastStep ? 'Finish' : 'Continue'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
