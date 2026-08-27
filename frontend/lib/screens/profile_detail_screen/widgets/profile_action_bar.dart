import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/core/app_routes.dart';
import 'package:life_partner_again/models/match_recommendation.dart';
import 'package:life_partner_again/providers/match_provider.dart';
import 'package:life_partner_again/widgets/bottomsheet/feature_exhausted_modal.dart';
import 'package:life_partner_again/widgets/feature_download_prompt.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileActionBar extends StatefulWidget {
  final Map<String, dynamic> profile;
  final VoidCallback onReportPressed;
  final VoidCallback onBlockPressed;

  const ProfileActionBar({
    super.key,
    required this.profile,
    required this.onReportPressed,
    required this.onBlockPressed,
  });

  @override
  State<ProfileActionBar> createState() => _ProfileActionBarState();
}

class _ProfileActionBarState extends State<ProfileActionBar> {
  bool _isPassing = false;
  bool _isInterested = false;
  bool _isMoreExpanded = false;

  @override
  void didUpdateWidget(covariant ProfileActionBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile['id'] != widget.profile['id']) {
      _isMoreExpanded = false;
    }
  }

  void _toggleMore() {
    setState(() => _isMoreExpanded = !_isMoreExpanded);
  }

  void _closeMore() {
    if (!_isMoreExpanded) return;
    setState(() => _isMoreExpanded = false);
  }

  void _runMoreAction(VoidCallback action) {
    _closeMore();
    action();
  }

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
        return LucideIcons.send;
      case InteractionState.interestReceived:
        return LucideIcons.heart_handshake;
      case InteractionState.matched:
        return LucideIcons.message_circle_dashed;
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
    final bool isBusy = _isPassing || _isInterested;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: _isMoreExpanded ? 12 : 14,
        bottom: MediaQuery.of(context).padding.bottom + 14,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.bottomCenter,
            child: _isMoreExpanded
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      children: [
                        _MoreActionButton(
                          icon: LucideIcons.flag,
                          title: 'Report profile',
                          subtitle:
                              'Tell us about suspicious or inappropriate activity.',
                          onTap: () => _runMoreAction(widget.onReportPressed),
                        ),
                        const SizedBox(height: 8),
                        _MoreActionButton(
                          icon: LucideIcons.ban,
                          title: 'Block profile',
                          subtitle:
                              'Hide this profile and prevent future contact.',
                          isDestructive: true,
                          onTap: () => _runMoreAction(widget.onBlockPressed),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Row(
            children: [
              Semantics(
                button: true,
                label: 'Pass',
                child: GestureDetector(
                  onTap: canPass
                      ? () async {
                          if (FeatureDownloadPrompt.intercept(context, featureName: 'Match & Connect')) return;
                          if (isBusy) return;
                          _closeMore();
                          setState(() => _isPassing = true);
                          try {
                            await context.read<MatchProvider>().swipeLeft(
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
                    height: 54,
                    width: 54,
                    decoration: BoxDecoration(
                      color: isDark
                          ? theme.scaffoldBackgroundColor
                          : const Color(0xFFFBF8F8),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.primaryColor.withValues(alpha: 0.12),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isPassing
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color:
                                    theme.iconTheme.color ??
                                    AppColors.textPrimary,
                              ),
                            )
                          : Icon(
                              Icons.heart_broken,
                              color:
                                  theme.iconTheme.color ??
                                  AppColors.textPrimary,
                              size: 24,
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: canAction && !isInterestSent
                      ? () async {
                          if (FeatureDownloadPrompt.intercept(context, featureName: 'Match & Connect')) return;
                          if (isBusy) return;
                          _closeMore();

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
                            if (mounted) {
                              setState(() => _isInterested = false);
                            }
                          }
                        }
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 54,
                    decoration: BoxDecoration(
                      color: (!canAction || isInterestSent)
                          ? theme.primaryColor.withValues(alpha: 0.5)
                          : theme.primaryColor,
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: (!canAction || isInterestSent)
                          ? []
                          : [
                              BoxShadow(
                                color: theme.primaryColor.withValues(
                                  alpha: 0.3,
                                ),
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
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        else ...[
                          Icon(
                            _getInteractionIcon(state),
                            color: Colors.white,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _getInteractionLabel(state),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Semantics(
                button: true,
                label: 'More actions',
                child: GestureDetector(
                  onTap: isBusy ? null : _toggleMore,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 54,
                    width: 54,
                    decoration: BoxDecoration(
                      color: isDark
                          ? theme.scaffoldBackgroundColor
                          : const Color(0xFFFBF8F8),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.primaryColor.withValues(alpha: 0.12),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        _isMoreExpanded ? LucideIcons.x : LucideIcons.ellipsis,
                        color: theme.iconTheme.color ?? AppColors.textPrimary,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoreActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDestructive;
  final VoidCallback onTap;

  const _MoreActionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isDestructive ? Colors.redAccent : theme.primaryColor;
    final textColor = isDestructive
        ? Colors.redAccent
        : theme.textTheme.bodyLarge?.color ?? AppColors.textPrimary;
    final subtitleColor =
        theme.textTheme.bodyMedium?.color ?? AppColors.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Ink(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDestructive
                  ? color.withValues(alpha: 0.07)
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: color.withValues(alpha: isDestructive ? 0.28 : 0.14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.11),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDestructive
                      ? Colors.redAccent
                      : subtitleColor.withValues(alpha: 0.8),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
