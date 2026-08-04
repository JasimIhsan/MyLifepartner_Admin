import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/widgets/custom_button.dart';

enum BlockSheetState { confirmation, success, failure }

class BlockConfirmationBottomSheet extends StatefulWidget {
  final Future<void> Function() onConfirm;
  final VoidCallback? onSuccess;
  final bool isBlocking;
  final String userName;

  const BlockConfirmationBottomSheet({
    super.key,
    required this.onConfirm,
    this.onSuccess,
    this.isBlocking = true,
    required this.userName,
  });

  static Future<void> show({
    required BuildContext context,
    required Future<void> Function() onConfirm,
    VoidCallback? onSuccess,
    bool isBlocking = true,
    required String userName,
  }) {
    return showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlockConfirmationBottomSheet(
        onConfirm: onConfirm,
        onSuccess: onSuccess,
        isBlocking: isBlocking,
        userName: userName,
      ),
    );
  }

  @override
  State<BlockConfirmationBottomSheet> createState() =>
      _BlockConfirmationBottomSheetState();
}

class _BlockConfirmationBottomSheetState
    extends State<BlockConfirmationBottomSheet> {
  BlockSheetState _state = BlockSheetState.confirmation;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleConfirm() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await widget.onConfirm();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _state = BlockSheetState.success;
        });
        if (widget.onSuccess != null) {
          widget.onSuccess!();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _state = BlockSheetState.failure;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 40, left: 24, right: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 32),

          // Icon Container
          Image.asset(
            'assets/images/illustrations/block_user.png',
            height: 120,
            fit: BoxFit.contain,
          ).animate().scale(
            begin: const Offset(0.7, 0.7),
            end: const Offset(1.0, 1.0),
            duration: 400.ms,
            curve: Curves.easeOutBack,
          ),
          const SizedBox(height: 24),

          // Animated Content Based on State
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (_state) {
      case BlockSheetState.confirmation:
        return _buildConfirmationContent(context);
      case BlockSheetState.success:
        return _buildSuccessContent(context);
      case BlockSheetState.failure:
        return _buildFailureContent(context);
    }
  }

  Widget _buildConfirmationContent(BuildContext context) {
    return Column(
      key: const ValueKey('confirmation'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.isBlocking
              ? 'Block ${widget.userName}?'
              : 'Unblock ${widget.userName}?',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
        const SizedBox(height: 12),
        Text(
          widget.isBlocking
              ? 'Are you sure you want to block this user? They will not be able to message you or view your profile.'
              : 'Are you sure you want to unblock this user? They will be able to message you and view your profile again.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
        const SizedBox(height: 32),
        Row(
              children: [
                Expanded(
                  child: CustomButton(
                    onPressed: _isLoading ? null : () => context.pop(),
                    text: "Cancel",
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
                    isLoading: _isLoading,
                    onPressed: _handleConfirm,
                    text: widget.isBlocking ? "Yes, Block" : "Yes, Unblock",
                    type: CustomButtonType.primary,
                    backgroundColor: widget.isBlocking
                        ? Colors.redAccent
                        : AppColors.primary,
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
    );
  }

  Widget _buildSuccessContent(BuildContext context) {
    return Column(
          key: const ValueKey('success'),
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Success!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.isBlocking
                  ? 'You have successfully blocked ${widget.userName}.'
                  : 'You have successfully unblocked ${widget.userName}.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                onPressed: () => context.pop(),
                text: "Done",
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
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.1, end: 0.0, curve: Curves.easeOut);
  }

  Widget _buildFailureContent(BuildContext context) {
    return Column(
          key: const ValueKey('failure'),
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Error',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.redAccent,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    onPressed: () => context.pop(),
                    text: "Cancel",
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
                    onPressed: () {
                      setState(() {
                        _state = BlockSheetState.confirmation;
                      });
                    },
                    text: "Try Again",
                    type: CustomButtonType.primary,
                    height: 54,
                    borderRadius: 27,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.1, end: 0.0, curve: Curves.easeOut);
  }
}
