import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/widgets/custom_button.dart';

class LogoutBottomSheet extends StatelessWidget {
  final VoidCallback onLogoutConfirm;

  const LogoutBottomSheet({super.key, required this.onLogoutConfirm});

  static Future<void> show({
    required BuildContext context,
    required VoidCallback onLogoutConfirm,
  }) {
    return showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LogoutBottomSheet(onLogoutConfirm: onLogoutConfirm),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 40, left: 24, right: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          const SizedBox(height: 32),

          // Logout Icon Container with soft red pulse/shadow
          Image.asset(
            'assets/images/illustrations/logout.png',
            height: 120,
            fit: BoxFit.contain,
          ).animate().scale(
            begin: const Offset(0.7, 0.7),
            end: const Offset(1.0, 1.0),
            duration: 400.ms,
            curve: Curves.easeOutBack,
          ),

          const SizedBox(height: 24),

          // Title
          Text(
            'Log Out',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
          const SizedBox(height: 12),

          // Subtitle
          Text(
            'Are you sure you want to log out of your account? You will need to sign in again to access your matches and chats.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textSecondary,
              height: 1.5,
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
          const SizedBox(height: 32),

          // Action Buttons
          Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      onPressed: () {
                        context.pop();
                        onLogoutConfirm();
                      },
                      text: "Yes, Log Out",
                      type: CustomButtonType.outline,
                      height: 54,
                      borderRadius: 27,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: CustomButton(
                      onPressed: () => context.pop(),
                      text: "Cancel",
                      type: CustomButtonType.primary,
                      height: 54,
                      borderRadius: 27,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
              .animate()
              .fadeIn(delay: 300.ms, duration: 300.ms)
              .slideY(begin: 0.1, end: 0.0, curve: Curves.easeOut),
        ],
      ),
    );
  }
}