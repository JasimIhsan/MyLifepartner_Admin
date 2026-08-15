import 'package:flutter/material.dart';

import 'package:life_partner_again/core/app_colors.dart';

enum CustomButtonType { primary, secondary, outline }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final CustomButtonType type;
  final double? width;
  final double height;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;
  final FontWeight? fontWeight;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.type = CustomButtonType.primary,
    this.width = double.infinity,
    this.height = 56.0,
    this.borderRadius = 16.0,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: _getStyle(),
        child: isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: _getLoadingColor(),
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                text,
                style: TextStyle(
                  fontSize: fontSize ?? 18,
                  fontWeight: fontWeight ?? FontWeight.w600,
                  color: _getTextColor(),
                ),
              ),
      ),
    );
  }

  ButtonStyle _getStyle() {
    final Color effectiveBackgroundColor = backgroundColor ?? AppColors.primary;
    final Color effectiveForegroundColor = textColor ?? AppColors.onPrimary;

    switch (type) {
      case CustomButtonType.primary:
        return ElevatedButton.styleFrom(
          backgroundColor: effectiveBackgroundColor,
          foregroundColor: effectiveForegroundColor,
          surfaceTintColor:
              Colors.transparent, // Disable Material 3 surface tint overlay
          disabledBackgroundColor: effectiveBackgroundColor.withValues(
            alpha: 0.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          elevation: 2,
        );
      case CustomButtonType.secondary:
        return ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.primaryLight,
          foregroundColor: textColor ?? AppColors.primary,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        );
      case CustomButtonType.outline:
        return ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: textColor ?? AppColors.primary,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          side: BorderSide(color: backgroundColor ?? AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        );
    }
  }

  Color _getTextColor() {
    if (textColor != null) return textColor!;

    switch (type) {
      case CustomButtonType.primary:
        return Colors.white; // Assuming onPrimary is usually white/light
      case CustomButtonType.secondary:
      case CustomButtonType.outline:
        return AppColors.primary;
    }
  }

  Color _getLoadingColor() {
    switch (type) {
      case CustomButtonType.primary:
        return Colors.white;
      case CustomButtonType.secondary:
      case CustomButtonType.outline:
        return AppColors.primary;
    }
  }
}
