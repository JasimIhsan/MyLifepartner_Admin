import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:life_partner_again/core/app_colors.dart';

Future<void> showSubscriptionFailureUI(
  BuildContext context,
  String? errorMessage,
) {
  final message =
      errorMessage ?? 'Failed to complete subscription. Please try again.';
  final isCancelled = message.toLowerCase().contains('cancel');

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
            isCancelled: isCancelled,
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
              isCancelled: isCancelled,
            ),
          ),
        );
      },
    );
  }
}

class SubscriptionFailureUI extends StatelessWidget {
  final String errorMessage;
  final bool isCancelled;

  const SubscriptionFailureUI({
    super.key,
    required this.errorMessage,
    required this.isCancelled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isCancelled
                ? Colors.amber.withValues(alpha: 0.1)
                : Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCancelled
                ? Icons.info_outline_rounded
                : Icons.error_outline_rounded,
            color: isCancelled ? Colors.amber.shade800 : Theme.of(context).colorScheme.error,
            size: 48,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          isCancelled ? 'Purchase Cancelled' : 'Something Went Wrong',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          errorMessage,
          style: TextStyle(
            fontSize: 15,
            color: Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textSecondary,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: Text(
              isCancelled ? 'Got It' : 'Try Again',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}