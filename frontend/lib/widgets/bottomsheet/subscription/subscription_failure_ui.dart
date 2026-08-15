import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:life_partner_again/core/app_colors.dart';

/// Describes the category of a subscription failure so the UI can render
/// the right icon, title, and CTA without relying on string matching.
enum SubscriptionFailureType {
  /// A genuine error (network, API, unknown). Shows red icon + "Try Again".
  error,

  /// User dismissed the store payment sheet themselves. Shows amber info
  /// icon + "Got It" — no retry needed.
  cancelled,

  /// Payment is pending store/bank approval (SCA, carrier billing, family
  /// purchase approval, etc.). Shows amber clock icon + "Restore Purchases".
  pending,
}

/// Shows the appropriate subscription failure / info bottom sheet.
///
/// [failureType] controls the icon and CTA shown. Defaults to [SubscriptionFailureType.error].
/// [onRestorePurchases] is only used when [failureType] is [SubscriptionFailureType.pending].
Future<void> showSubscriptionFailureUI(
  BuildContext context,
  String? errorMessage, {
  SubscriptionFailureType failureType = SubscriptionFailureType.error,
  VoidCallback? onRestorePurchases,
}) {
  final message = errorMessage ??
      (failureType == SubscriptionFailureType.pending
          ? 'Your payment is being reviewed by the store. This usually takes a few seconds. If access doesn\'t activate automatically, tap Restore below.'
          : failureType == SubscriptionFailureType.cancelled
              ? 'You cancelled the purchase. You can try again whenever you\'re ready.'
              : 'Failed to complete subscription. Please try again.');

  if (kIsWeb) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          contentPadding: const EdgeInsets.all(32),
          content: SubscriptionFailureUI(
            errorMessage: message,
            failureType: failureType,
            onRestorePurchases: onRestorePurchases,
          ),
        );
      },
    );
  } else {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
            child: SubscriptionFailureUI(
              errorMessage: message,
              failureType: failureType,
              onRestorePurchases: onRestorePurchases,
            ),
          ),
        );
      },
    );
  }
}

class SubscriptionFailureUI extends StatelessWidget {
  final String errorMessage;
  final SubscriptionFailureType failureType;
  final VoidCallback? onRestorePurchases;

  const SubscriptionFailureUI({
    super.key,
    required this.errorMessage,
    this.failureType = SubscriptionFailureType.error,
    this.onRestorePurchases,
  });

  @override
  Widget build(BuildContext context) {
    final isCancelled = failureType == SubscriptionFailureType.cancelled;
    final isPending = failureType == SubscriptionFailureType.pending;
    final isError = failureType == SubscriptionFailureType.error;

    // Icon & colour per failure type
    final IconData icon = isPending
        ? Icons.schedule_rounded
        : isCancelled
            ? Icons.info_outline_rounded
            : Icons.error_outline_rounded;

    final Color iconColor = isError
        ? Theme.of(context).colorScheme.error
        : Colors.amber.shade800;

    final Color iconBg = isError
        ? Theme.of(context).colorScheme.error.withValues(alpha: 0.1)
        : Colors.amber.withValues(alpha: 0.1);

    final String title = isPending
        ? 'Payment Processing'
        : isCancelled
            ? 'Purchase Cancelled'
            : 'Something Went Wrong';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Icon ──────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 48),
        ),
        const SizedBox(height: 24),

        // ── Title ─────────────────────────────────────────────────────────
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).textTheme.bodyLarge?.color ??
                AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),

        // ── Body message ──────────────────────────────────────────────────
        Text(
          errorMessage,
          style: TextStyle(
            fontSize: 15,
            color: Theme.of(context).textTheme.bodyMedium?.color ??
                AppColors.textSecondary,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // ── Primary CTA ───────────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (isPending && onRestorePurchases != null) {
                onRestorePurchases!();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isPending
                  ? Colors.amber.shade700
                  : Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: Text(
              isPending
                  ? 'Restore Purchases'
                  : isCancelled
                      ? 'Got It'
                      : 'Try Again',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),

        // ── Secondary link (pending only: dismiss without restoring) ──────
        if (isPending) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor:
                  Theme.of(context).textTheme.bodyMedium?.color ??
                      AppColors.textSecondary,
              splashFactory: NoSplash.splashFactory,
            ),
            child: const Text(
              'Check back later',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
        ] else ...[
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
