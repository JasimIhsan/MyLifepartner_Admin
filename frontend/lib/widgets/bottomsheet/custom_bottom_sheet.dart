import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/widgets/custom_button.dart';

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
    String? imagePath,
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
        imagePath: imagePath,
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
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
  final String? imagePath;

  const _BottomSheetContent({
    required this.type,
    required this.title,
    required this.message,
    this.primaryButtonText,
    this.onPrimaryPressed,
    this.secondaryButtonText,
    this.onSecondaryPressed,
    this.imagePath,
  });

  @override
  State<_BottomSheetContent> createState() => _BottomSheetContentState();
}

class _BottomSheetContentState extends State<_BottomSheetContent> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
        border: const Border(
          top: BorderSide(color: Color(0xFFF9F9F9), width: 1.5),
        ),
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
        _DragHandle(),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                    widget.title,
                    style: const TextStyle(
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

              const SizedBox(height: 10),

              // Message
              Text(
                    widget.message,
                    style: const TextStyle(
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

              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
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
            onPressed: widget.onPrimaryPressed ?? () => context.pop(),
            text: widget.primaryButtonText ?? 'Continue',
            borderRadius: 16,
            height: 52,
            fontSize: 16,
          ),
        ),
        if (widget.secondaryButtonText != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed:
                  widget.onSecondaryPressed ?? () => context.pop(),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                widget.secondaryButtonText!,
                style: const TextStyle(
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
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 0),
          child: Column(
            children: [
              if (widget.imagePath != null)
                Container(
                      height: 120,
                      alignment: Alignment.center,
                      child: Image.asset(
                        widget.imagePath!,
                        fit: BoxFit.contain,
                      ),
                    )
                    .animate()
                    .scale(
                      begin: const Offset(0.7, 0.7),
                      end: const Offset(1, 1),
                      curve: Curves.easeOutBack,
                      duration: 500.ms,
                    )
                    .fadeIn(duration: 250.ms)
              else
                // Vibrant nested glowing icon with pulse
                Container(
                      width: 90,
                      height: 90,
                      alignment: Alignment.center,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Pulse ring
                          Container(
                                width: 86,
                                height: 86,
                                decoration: BoxDecoration(
                                  color: cfg.iconColor.withValues(alpha: 0.06),
                                  shape: BoxShape.circle,
                                ),
                              )
                              .animate(
                                onPlay: (controller) =>
                                    controller.repeat(reverse: true),
                              )
                              .scale(
                                begin: const Offset(0.92, 0.92),
                                end: const Offset(1.06, 1.06),
                                duration: 2000.ms,
                                curve: Curves.easeInOut,
                              ),
                          // Middle border ring
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: cfg.iconColor.withValues(alpha: 0.09),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: cfg.iconBorder.withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                            ),
                          ),
                          // Main filled circle with shadow
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: cfg.iconBg,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: cfg.iconColor.withValues(alpha: 0.12),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              cfg.icon,
                              size: 28,
                              color: cfg.iconColor,
                            ),
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .scale(
                      begin: const Offset(0.4, 0.4),
                      end: const Offset(1, 1),
                      curve: Curves.easeOutBack,
                      duration: 500.ms,
                    )
                    .fadeIn(duration: 250.ms),

              const SizedBox(height: 20),

              Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
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
                    style: const TextStyle(
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

              SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenericButtons(BuildContext context) {
    final isDouble =
        widget.type == BottomSheetType.confirmation ||
        (widget.type == BottomSheetType.info &&
            widget.secondaryButtonText != null);

    final primaryText =
        widget.primaryButtonText ??
        _sheetConfig(widget.type).defaultPrimaryText;

    if (isDouble) {
      return Row(
        children: [
          Expanded(
            child: CustomButton(
              onPressed:
                  widget.onSecondaryPressed ?? () => context.pop(),
              text: widget.secondaryButtonText ?? 'Cancel',
              type: CustomButtonType.outline,
              borderRadius: 16,
              height: 52,
              backgroundColor: AppColors.borderColor,
              textColor: AppColors.textSecondary,
              fontSize: 15,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CustomButton(
              onPressed: widget.onPrimaryPressed,
              text: primaryText,
              borderRadius: 16,
              height: 52,
              backgroundColor: AppColors.primary,
              textColor: Colors.white,
              fontSize: 15,
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        onPressed: widget.onPrimaryPressed ?? () => context.pop(),
        text: primaryText,
        borderRadius: 16,
        height: 52,
        fontSize: 16,
      ),
    );
  }

  _SheetConfig _sheetConfig(BottomSheetType type) {
    switch (type) {
      case BottomSheetType.success:
        return const _SheetConfig(
          icon: Icons.check_circle_outline_rounded,
          iconColor: Color(0xFF10B981),
          iconBg: Color(0xFFECFDF5),
          iconBorder: Color(0xFFA7F3D0),
          defaultPrimaryText: 'Continue',
        );
      case BottomSheetType.error:
        return const _SheetConfig(
          icon: Icons.error_outline_rounded,
          iconColor: Color(0xFFEF4444),
          iconBg: Color(0xFFFEF2F2),
          iconBorder: Color(0xFFFEE2E2),
          defaultPrimaryText: 'Close',
        );
      case BottomSheetType.warning:
        return const _SheetConfig(
          icon: Icons.warning_amber_rounded,
          iconColor: Color(0xFFF59E0B),
          iconBg: Color(0xFFFFFBEB),
          iconBorder: Color(0xFFFEF3C7),
          defaultPrimaryText: 'Okay',
        );
      case BottomSheetType.confirmation:
        return const _SheetConfig(
          icon: Icons.help_outline_rounded,
          iconColor: AppColors.primary,
          iconBg: Color(0xFFFFF5F5),
          iconBorder: Color(0xFFFED7D7),
          defaultPrimaryText: 'Confirm',
        );
      case BottomSheetType.info:
        return const _SheetConfig(
          icon: Icons.info_outline_rounded,
          iconColor: Color(0xFF3B82F6),
          iconBg: Color(0xFFEFF6FF),
          iconBorder: Color(0xFFDBEAFE),
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
        width: 36,
        height: 4.5,
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
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
