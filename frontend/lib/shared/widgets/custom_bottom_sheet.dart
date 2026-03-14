import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mylifepartner/core/app_colors.dart';
import 'package:mylifepartner/shared/widgets/custom_button.dart';

enum BottomSheetType { success, error, warning, info, confirmation }

class CustomBottomSheet {
  static Future<void> show({
    required BuildContext context,
    required BottomSheetType type,
    required String title,
    required String message,
    String? primaryButtonText,
    VoidCallback? onPrimaryPressed,
    String? secondaryButtonText,
    VoidCallback? onSecondaryPressed,
    bool isDismissible = true,
    bool isScrollControlled = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isDismissible: isDismissible,
      enableDrag: isDismissible,
      isScrollControlled: isScrollControlled,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildBottomSheet(
        context,
        type,
        title,
        message,
        primaryButtonText,
        onPrimaryPressed,
        secondaryButtonText,
        onSecondaryPressed,
      ),
    );
  }

  static Future<T?> showContent<T>({
    required BuildContext context,
    required Widget child,
    bool isDismissible = true,
    bool isScrollControlled = false,
    Color backgroundColor = Colors.white,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: isDismissible,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent, // Important for custom shapes
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: child,
      ),
    );
  }

  static Widget _buildBottomSheet(
    BuildContext context,
    BottomSheetType type,
    String title,
    String message,
    String? primaryButtonText,
    VoidCallback? onPrimaryPressed,
    String? secondaryButtonText,
    VoidCallback? onSecondaryPressed,
  ) {
    IconData icon;
    Color iconColor;
    String defaultPrimaryText;

    switch (type) {
      case BottomSheetType.success:
        icon = Icons.check_circle;
        iconColor = AppColors.success; // Assuming generic success color
        defaultPrimaryText = "Continue";
        break;
      case BottomSheetType.error:
        icon = Icons.error;
        iconColor = Colors.black;
        defaultPrimaryText = "Close";
        break;
      case BottomSheetType.warning:
        icon = Icons.warning_rounded;
        iconColor = Colors.black;
        defaultPrimaryText = "Okay";
        break;
      case BottomSheetType.info:
        icon = Icons.info;
        iconColor = Colors.black;
        defaultPrimaryText = "Okay";
        break;
      case BottomSheetType.confirmation:
        icon = Icons.help;
        iconColor = AppColors.primary;
        defaultPrimaryText = "Confirm";
        break;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 64),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          if (type == BottomSheetType.confirmation) ...[
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    onPressed:
                        onSecondaryPressed ?? () => Navigator.pop(context),
                    text: secondaryButtonText ?? "Cancel",
                    type: CustomButtonType.outline,
                    borderRadius: 16,
                    height: 50,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomButton(
                    onPressed: onPrimaryPressed,
                    text: primaryButtonText ?? defaultPrimaryText,
                    borderRadius: 16,
                    height: 50,
                  ),
                ),
              ],
            ),
          ] else if (type == BottomSheetType.info &&
              secondaryButtonText != null) ...[
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    onPressed:
                        onSecondaryPressed ?? () => Navigator.pop(context),
                    text: secondaryButtonText,
                    type: CustomButtonType.outline,
                    borderRadius: 16,
                    height: 50,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomButton(
                    onPressed: onPrimaryPressed,
                    text: primaryButtonText ?? defaultPrimaryText,
                    borderRadius: 16,
                    height: 50,
                  ),
                ),
              ],
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              height: 50,
              child: CustomButton(
                onPressed: onPrimaryPressed ?? () => Navigator.pop(context),
                text: primaryButtonText ?? defaultPrimaryText,
                borderRadius: 25,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
