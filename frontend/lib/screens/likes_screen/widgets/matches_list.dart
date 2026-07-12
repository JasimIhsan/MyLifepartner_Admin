import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/models/match_recommendation.dart';
import 'package:life_partner_again/providers/match_provider.dart';
import 'package:provider/provider.dart';
import 'connection_card.dart';

class MatchesList extends StatefulWidget {
  final int tabIndex;
  final Function(bool) onScroll;

  const MatchesList({
    super.key,
    required this.tabIndex,
    required this.onScroll,
  });

  @override
  State<MatchesList> createState() => _MatchesListState();
}

class _MatchesListState extends State<MatchesList> {
  double _lastOffset = 0.0;
  bool _isVisible = true;
  static const double _threshold = 40.0; // Higher threshold for stability

  Future<void> _refresh(BuildContext context) async {
    final provider = context.read<MatchProvider>();
    switch (widget.tabIndex) {
      case 0:
        await provider.loadMutualMatches();
        break;
      case 1:
        await provider.loadReceivedInterests();
        break;
      case 2:
        await provider.loadSentInterests();
        break;
    }
  }

  void _handleScroll(ScrollNotification notification) {
    if (notification is UserScrollNotification) {
      final double pixels = notification.metrics.pixels;

      // Force header visible at top
      if (pixels <= 10) {
        if (!_isVisible) {
          _isVisible = true;
          widget.onScroll(true);
        }
        _lastOffset = pixels;
        return;
      }

      final double delta = pixels - _lastOffset;

      if (delta.abs() > _threshold) {
        if (delta > 0 && _isVisible) {
          // Scrolling down
          _isVisible = false;
          widget.onScroll(false);
        } else if (delta < 0 && !_isVisible) {
          // Scrolling up
          _isVisible = true;
          widget.onScroll(true);
        }
        _lastOffset = pixels;
      }
    }
  }

  Future<void> _showCancelConfirmation(BuildContext context, MatchRecommendation profile) async {
    final provider = context.read<MatchProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Cancel Interest?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          content: Text(
            'Are you sure you want to cancel your interest request to ${profile.name}?',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(
                'No',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Yes, Cancel'),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      try {
        await provider.cancelInterest(profile.id);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Interest request to ${profile.name} canceled'),
            backgroundColor: AppColors.textPrimary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      } catch (e) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Failed to cancel interest request: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MatchProvider>(
      builder: (context, provider, _) {
        List<MatchRecommendation> profiles = [];
        switch (widget.tabIndex) {
          case 0:
            profiles = provider.mutualMatches;
            break;
          case 1:
            profiles = provider.receivedInterests;
            break;
          case 2:
            profiles = provider.sentInterests;
            break;
        }

        if (provider.state == MatchLoadState.loading && profiles.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          );
        }

        if (provider.state == MatchLoadState.error && profiles.isEmpty) {
          return Center(
            child: Text(
              provider.error ?? 'Error loading profiles',
              style: const TextStyle(color: AppColors.error),
            ),
          );
        }

        if (profiles.isEmpty) {
          final String title;
          final String subtitle;

          if (widget.tabIndex == 0) {
            title = 'No Matches Yet';
            subtitle =
                "When you like someone and they like you back, they will appear here.";
          } else if (widget.tabIndex == 1) {
            title = 'No Likes Received';
            subtitle =
                "Profiles of people who liked you will be shown here. Keep your profile updated!";
          } else {
            title = 'No Likes Sent';
            subtitle =
                "You haven't liked anyone yet. Discover profiles to find your perfect partner!";
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/illustrations/empty_profile.png',
                    height: 200,
                    fit: BoxFit.contain,
                  ).animate().scale(
                    begin: const Offset(0.7, 0.7),
                    end: const Offset(1.0, 1.0),
                    duration: 500.ms,
                    curve: Curves.easeOutBack,
                  ),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 150.ms, duration: 450.ms)
                      .slideY(begin: 0.2, end: 0.0, curve: Curves.easeOutQuad),
                  const SizedBox(height: 12),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 450.ms)
                      .slideY(begin: 0.2, end: 0.0, curve: Curves.easeOutQuad),
                ],
              ),
            ),
          );
        }

        return NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification notification) {
            _handleScroll(notification);
            return false;
          },
          child: RefreshIndicator(
            onRefresh: () => _refresh(context),
            edgeOffset: 20,
            color: AppColors.black,
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
              ),
              itemCount: profiles.length,
              itemBuilder: (context, index) {
                final profile = profiles[index];
                return ConnectionCard(
                  profile: profile,
                  index: index,
                  onCancel: widget.tabIndex == 2
                      ? () => _showCancelConfirmation(context, profile)
                      : null,
                );
              },
            ),
          ),
        );
      },
    );
  }
}
