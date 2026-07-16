import 'package:life_partner_again/core/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/models/match_recommendation.dart';
import 'package:life_partner_again/providers/match_provider.dart';

import 'package:life_partner_again/screens/profile_detail_screen/widgets/interest_limit_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileActionBar extends StatefulWidget {
  final Map<String, dynamic> profile;

  const ProfileActionBar({super.key, required this.profile});

  @override
  State<ProfileActionBar> createState() => _ProfileActionBarState();
}

class _ProfileActionBarState extends State<ProfileActionBar> {
  bool _isPassing = false;
  bool _isInterested = false;

  String _getInteractionLabel(InteractionState state) {
    switch (state) {
      case InteractionState.none:
        return 'Send Interest';
      case InteractionState.interestSent:
        return 'Interest Sent';
      case InteractionState.interestReceived:
        return 'Accept';
      case InteractionState.matched:
        return 'Chat';
    }
  }

  IconData _getInteractionIcon(InteractionState state) {
    switch (state) {
      case InteractionState.none:
        return Icons.favorite_rounded;
      case InteractionState.interestSent:
        return Icons.send_rounded;
      case InteractionState.interestReceived:
        return Icons.check_circle_rounded;
      case InteractionState.matched:
        return Icons.chat_bubble_rounded;
    }
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required bool isOutlined,
    required VoidCallback? onTap,
    bool isLoading = false,
    bool isDisabled = false,
  }) {
    final bool effectivelyDisabled = isDisabled || onTap == null;
    return Expanded(
      child: GestureDetector(
        onTap: isLoading || effectivelyDisabled ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: isOutlined
                ? Colors.white
                : effectivelyDisabled
                ? AppColors.primary.withValues(alpha: 0.5)
                : AppColors.primary,
            borderRadius: BorderRadius.circular(16),
            border: isOutlined
                ? Border.all(
                    color: effectivelyDisabled
                        ? Colors.grey.shade200
                        : Colors.grey.shade300,
                    width: 1.5,
                  )
                : null,
            boxShadow: !isOutlined && !effectivelyDisabled
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isOutlined ? AppColors.textPrimary : Colors.white,
                  ),
                )
              else ...[
                Icon(
                  icon,
                  size: 18,
                  color: isOutlined
                      ? (effectivelyDisabled
                            ? AppColors.textSecondary.withValues(alpha: 0.5)
                            : AppColors.textPrimary)
                      : Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isOutlined
                        ? (effectivelyDisabled
                              ? AppColors.textSecondary.withValues(alpha: 0.5)
                              : AppColors.textPrimary)
                        : Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final interactionStateRaw = widget.profile['interactionState'];
    InteractionState state = InteractionState.none;
    if (interactionStateRaw is InteractionState) {
      state = interactionStateRaw;
    } else if (interactionStateRaw is String) {
      state = InteractionState.fromString(interactionStateRaw);
    }
    final bool isMatched = state == InteractionState.matched;
    final bool isInterestSent = state == InteractionState.interestSent;
    final bool isInterestReceived = state == InteractionState.interestReceived;
    final bool isNone = state == InteractionState.none;

    final bool canPass = isNone || isInterestReceived;
    final bool canAction = isNone || isInterestReceived || isMatched;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          _actionButton(
            label: '',
            icon: Icons.heart_broken,
            isOutlined: true,
            isLoading: _isPassing,
            onTap: canPass
                ? () async {
                    if (_isPassing || _isInterested) return;
                    setState(() => _isPassing = true);
                    try {
                      await context.read<MatchProvider>().swipeLeft(
                        targetProfileId: widget.profile['id'],
                      );
                      if (!context.mounted) return;
                      context.pop();
                    } catch (e) {
                      if (!context.mounted) return;
                      if (e is DioException && e.response?.statusCode == 402) {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (_) => InterestLimitBottomSheet(
                            message:
                                e.response?.data?['message'] ??
                                'Unable to process skip at this moment.',
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              context.read<MatchProvider>().error ??
                                  'Failed to skip',
                            ),
                          ),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isPassing = false);
                    }
                  }
                : null,
          ),
          const SizedBox(width: 12),
          _actionButton(
            label: _getInteractionLabel(state),
            icon: _getInteractionIcon(state),
            isOutlined: false,
            isLoading: _isInterested,
            isDisabled: !canAction || isInterestSent,
            onTap: canAction && !isInterestSent
                ? () async {
                    if (_isPassing || _isInterested) return;

                    // If already matched, navigate to chat
                    if (isMatched) {
                      final prefs = await SharedPreferences.getInstance();
                      final currentUserId = prefs.getInt('userId') ?? 0;
                      if (!context.mounted) return;
                      context.push(AppRoutes.chatDetail, extra: ChatDetailArguments(profile: MatchRecommendation.fromJson(widget.profile,), currentUserId: currentUserId,));
                      return;
                    }

                    setState(() => _isInterested = true);
                    try {
                      await context.read<MatchProvider>().swipeRight(
                        targetProfileId: widget.profile['id'],
                      );
                      if (!context.mounted) return;
                      context.pop();
                    } catch (e) {
                      if (!context.mounted) return;
                      if (e is DioException && e.response?.statusCode == 402) {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (_) => InterestLimitBottomSheet(
                            message:
                                e.response?.data?['message'] ??
                                'Unable to send interest at this moment.',
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              context.read<MatchProvider>().error ??
                                  'Failed to send interest',
                            ),
                          ),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isInterested = false);
                    }
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
