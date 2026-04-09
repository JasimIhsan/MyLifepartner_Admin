import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => _BottomSheetContent(
        type: type,
        title: title,
        message: message,
        primaryButtonText: primaryButtonText,
        onPrimaryPressed: onPrimaryPressed,
        secondaryButtonText: secondaryButtonText,
        onSecondaryPressed: onSecondaryPressed,
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
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: child,
      ),
    );
  }
}

// ─── Internal stateful widget for animation ────────────────────────────────

class _BottomSheetContent extends StatefulWidget {
  final BottomSheetType type;
  final String title;
  final String message;
  final String? primaryButtonText;
  final VoidCallback? onPrimaryPressed;
  final String? secondaryButtonText;
  final VoidCallback? onSecondaryPressed;

  const _BottomSheetContent({
    required this.type,
    required this.title,
    required this.message,
    this.primaryButtonText,
    this.onPrimaryPressed,
    this.secondaryButtonText,
    this.onSecondaryPressed,
  });

  @override
  State<_BottomSheetContent> createState() => _BottomSheetContentState();
}

class _BottomSheetContentState extends State<_BottomSheetContent> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: widget.type == BottomSheetType.info
          ? _buildProfileCompleteSheet(context)
          : _buildGenericSheet(context),
    );
  }

  // ─── PREMIUM Profile Completion Sheet ─────────────────────────────────────

  Widget _buildProfileCompleteSheet(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Drag handle
        _DragHandle(),
        const SizedBox(height: 8),

        // ── Content
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.4,
                  height: 1.2,
                ),
              )
                  .animate()
                  .fadeIn(delay: 100.ms, duration: 350.ms)
                  .slideY(begin: 0.06, end: 0),

              const SizedBox(height: 8),

              // Message
              Text(
                widget.message,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.55,
                ),
              )
                  .animate()
                  .fadeIn(delay: 150.ms, duration: 350.ms)
                  .slideY(begin: 0.06, end: 0),

              const SizedBox(height: 28),

              // Buttons
              _buildProfileButtons(context)
                  .animate()
                  .fadeIn(delay: 260.ms, duration: 350.ms)
                  .slideY(begin: 0.06, end: 0),

              // Safe area bottom padding
              SizedBox(
                  height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: CustomButton(
            onPressed: widget.onPrimaryPressed ?? () => Navigator.pop(context),
            text: widget.primaryButtonText ?? 'Continue',
            borderRadius: 16,
            height: 52,
          ),
        ),
        if (widget.secondaryButtonText != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed:
                  widget.onSecondaryPressed ?? () => Navigator.pop(context),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                widget.secondaryButtonText!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ─── Generic sheet (success / error / warning / confirmation) ──────────────

  Widget _buildGenericSheet(BuildContext context) {
    final cfg = _sheetConfig(widget.type);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DragHandle(),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 0),
          child: Column(
            children: [
              // Icon pill
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: cfg.iconBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: cfg.iconBorder, width: 1.5),
                ),
                child: Icon(cfg.icon, size: 34, color: cfg.iconColor),
              )
                  .animate()
                  .scale(
                      begin: const Offset(0.7, 0.7),
                      end: const Offset(1, 1),
                      curve: Curves.elasticOut,
                      duration: 600.ms)
                  .fadeIn(duration: 300.ms),

              const SizedBox(height: 20),

              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              )
                  .animate()
                  .fadeIn(delay: 120.ms, duration: 300.ms)
                  .slideY(begin: 0.06, end: 0),

              const SizedBox(height: 8),

              Text(
                widget.message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.55,
                ),
              )
                  .animate()
                  .fadeIn(delay: 170.ms, duration: 300.ms)
                  .slideY(begin: 0.06, end: 0),

              const SizedBox(height: 28),

              _buildGenericButtons(context)
                  .animate()
                  .fadeIn(delay: 230.ms, duration: 300.ms)
                  .slideY(begin: 0.06, end: 0),

              SizedBox(
                  height: MediaQuery.of(context).padding.bottom + 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenericButtons(BuildContext context) {
    final isDouble = widget.type == BottomSheetType.confirmation ||
        (widget.type == BottomSheetType.info &&
            widget.secondaryButtonText != null);

    final primaryText = widget.primaryButtonText ??
        _sheetConfig(widget.type).defaultPrimaryText;

    if (isDouble) {
      return Row(
        children: [
          Expanded(
            child: CustomButton(
              onPressed:
                  widget.onSecondaryPressed ?? () => Navigator.pop(context),
              text: widget.secondaryButtonText ?? 'Cancel',
              type: CustomButtonType.outline,
              borderRadius: 16,
              height: 50,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: CustomButton(
              onPressed: widget.onPrimaryPressed,
              text: primaryText,
              borderRadius: 16,
              height: 50,
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        onPressed:
            widget.onPrimaryPressed ?? () => Navigator.pop(context),
        text: primaryText,
        borderRadius: 16,
        height: 50,
      ),
    );
  }

  _SheetConfig _sheetConfig(BottomSheetType type) {
    switch (type) {
      case BottomSheetType.success:
        return _SheetConfig(
          icon: Icons.check_rounded,
          iconColor: Colors.black,
          iconBg: const Color(0xFFF0F0F0),
          iconBorder: const Color(0xFFDDDDDD),
          defaultPrimaryText: 'Continue',
        );
      case BottomSheetType.error:
        return _SheetConfig(
          icon: Icons.close_rounded,
          iconColor: Colors.black,
          iconBg: const Color(0xFFF5F5F5),
          iconBorder: const Color(0xFFE0E0E0),
          defaultPrimaryText: 'Close',
        );
      case BottomSheetType.warning:
        return _SheetConfig(
          icon: Icons.warning_amber_rounded,
          iconColor: Colors.black,
          iconBg: const Color(0xFFF5F5F5),
          iconBorder: const Color(0xFFE0E0E0),
          defaultPrimaryText: 'Okay',
        );
      case BottomSheetType.confirmation:
        return _SheetConfig(
          icon: Icons.help_outline_rounded,
          iconColor: AppColors.primary,
          iconBg: AppColors.primaryLight,
          iconBorder: AppColors.borderColor,
          defaultPrimaryText: 'Confirm',
        );
      case BottomSheetType.info:
        return _SheetConfig(
          icon: Icons.info_outline_rounded,
          iconColor: Colors.black,
          iconBg: const Color(0xFFF5F5F5),
          iconBorder: const Color(0xFFE0E0E0),
          defaultPrimaryText: 'Okay',
        );
    }
  }
}

// ─── Drag handle ───────────────────────────────────────────────────────────

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFFD8D8D8),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}



// ─── Config model ───────────────────────────────────────────────────────────

class _SheetConfig {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final Color iconBorder;
  final String defaultPrimaryText;

  const _SheetConfig({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.iconBorder,
    required this.defaultPrimaryText,
  });
}
