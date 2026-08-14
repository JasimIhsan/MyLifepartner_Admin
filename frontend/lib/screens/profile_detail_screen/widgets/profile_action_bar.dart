import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/core/app_routes.dart';
import 'package:life_partner_again/models/match_recommendation.dart';
import 'package:life_partner_again/providers/match_provider.dart';
import 'package:life_partner_again/widgets/bottomsheet/feature_exhausted_modal.dart';
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

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Pass Button
          GestureDetector(
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
                        FeatureExhaustedModal.show(
                          context,
                          featureType: 'Skip',
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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 60,
              width: 80,
              decoration: BoxDecoration(
                color: isDark
                    ? theme.scaffoldBackgroundColor
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Center(
                child: _isPassing
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: theme.iconTheme.color ?? AppColors.textPrimary,
                        ),
                      )
                    : Icon(
                        Icons.heart_broken,
                        color: theme.iconTheme.color ?? AppColors.textPrimary,
                        size: 26,
                      ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Interest/Action Button
          Expanded(
            child: GestureDetector(
              onTap: canAction && !isInterestSent
                  ? () async {
                      if (_isPassing || _isInterested) return;

                      // If already matched, navigate to chat
                      if (isMatched) {
                        final prefs = await SharedPreferences.getInstance();
                        final currentUserId = prefs.getInt('userId') ?? 0;
                        if (!context.mounted) return;
                        context.push(
                          '/chat-detail/${widget.profile['id']}',
                          extra: ChatDetailArguments(
                            profile: MatchRecommendation.fromJson(
                              widget.profile,
                            ),
                            currentUserId: currentUserId,
                          ),
                        );
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
                        if (e is DioException &&
                            e.response?.statusCode == 402) {
                          FeatureExhaustedModal.show(
                            context,
                            featureType: 'Interest',
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
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 60,
                decoration: BoxDecoration(
                  color: (!canAction || isInterestSent)
                      ? theme.primaryColor.withValues(alpha: 0.5)
                      : theme.primaryColor,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: (!canAction || isInterestSent)
                      ? []
                      : [
                          BoxShadow(
                            color: theme.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isInterested)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    else ...[
                      Icon(
                        _getInteractionIcon(state),
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _getInteractionLabel(state),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
