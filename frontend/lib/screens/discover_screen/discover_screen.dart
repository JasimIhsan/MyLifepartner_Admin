import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mylifepartner/core/app_colors.dart';
import 'package:mylifepartner/models/match_recommendation.dart';
import 'package:mylifepartner/providers/match_provider.dart';
import 'package:mylifepartner/screens/profile_detail_screen/profile_detail_screen.dart';
import 'package:mylifepartner/screens/profile_detail_screen/widgets/interest_limit_bottom_sheet.dart';
import 'package:mylifepartner/services/match_service.dart';
import 'package:provider/provider.dart';

/// Discover screen refactored into a modern profile browser UI.
/// Each profile is displayed as a large hero card with floating navigation and interaction buttons.
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final PageController _pageController = PageController();
  final Set<int> _actionedProfileIds = {};
  List<MatchRecommendation> _localProfiles = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = context.read<MatchProvider>();
        if (provider.state == MatchLoadState.idle ||
            provider.profiles.isEmpty) {
          provider.loadRecommendations().then((_) => _syncWithProvider());
        } else {
          _syncWithProvider();
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _syncWithProvider() {
    if (!mounted) return;
    final provider = context.read<MatchProvider>();
    setState(() {
      _localProfiles = List.from(provider.profiles);
    });
  }

  void _goToNext() {
    if (_currentIndex < _localProfiles.length - 1) {
      _pageController.nextPage(duration: 500.ms, curve: Curves.easeOutCubic);
    } else {
      // End of list - refresh or loop
      context.read<MatchProvider>().loadRecommendations().then((_) {
        _syncWithProvider();
      });
    }
  }

  void _goToPrevious() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: 500.ms,
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _handleInteraction(
    MatchRecommendation profile,
    String action,
  ) async {
    if (_actionedProfileIds.contains(profile.id)) return;

    setState(() {
      _actionedProfileIds.add(profile.id);
    });

    // Animate to next profile smoothly
    _goToNext();

    try {
      // Backend integration: 'RIGHT' for interest, 'LEFT' for not interested
      await MatchService.swipe(targetProfileId: profile.id, action: action);
    } catch (e) {
      debugPrint("Action Failed: $e");
      if (mounted && e is DioException && e.response?.statusCode == 402) {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => InterestLimitBottomSheet(
            message:
                e.response?.data?['message'] ??
                'You have reached your interest limit. Upgrade your plan to send more interests!',
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<MatchProvider>(
          builder: (context, provider, _) {
            if (provider.state == MatchLoadState.loading &&
                _localProfiles.isEmpty) {
              return _buildLoading();
            }

            if (provider.state == MatchLoadState.error &&
                _localProfiles.isEmpty) {
              return _buildError(provider);
            }

            if (_localProfiles.isEmpty) {
              return _buildEmpty();
            }

            return Column(
              children: [
                // const _TopTabs(),
                Expanded(
                  child: Stack(
                    children: [
                      // Main Profile Browser
                      PageView.builder(
                        controller: _pageController,
                        onPageChanged: (idx) =>
                            setState(() => _currentIndex = idx),
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _localProfiles.length,
                        itemBuilder: (context, index) {
                          final profile = _localProfiles[index];
                          return _ProfileBrowserCard(
                            profile: profile,
                            onInterest: () =>
                                _handleInteraction(profile, 'RIGHT'),
                            onNotInterested: () =>
                                _handleInteraction(profile, 'LEFT'),
                          );
                        },
                      ),

                      // Floating Side Navigation Buttons
                      if (_currentIndex > 0)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _SideNavigationButton(
                            icon: Icons.chevron_left_rounded,
                            onTap: _goToPrevious,
                            isLeft: true,
                          ),
                        ),
                      if (_currentIndex < _localProfiles.length - 1)
                        Align(
                          alignment: Alignment.centerRight,
                          child: _SideNavigationButton(
                            icon: Icons.chevron_right_rounded,
                            onTap: _goToNext,
                            isLeft: false,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
          SizedBox(height: 16),
          Text(
            "Finding best matches for you...",
            style: TextStyle(
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(MatchProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Connection Error',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            _ActionButton(
              label: 'Retry',
              icon: Icons.refresh_rounded,
              onTap: () => provider.loadRecommendations().then(
                (_) => _syncWithProvider(),
              ),
              primary: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.people_outline_rounded,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 24),
            Text(
              'No profiles available right now',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Check back later for fresh recommendations.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// class _TopTabs extends StatelessWidget {
//   const _TopTabs();

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           _buildPillTab('Matches', isSelected: true),
//           const SizedBox(width: 8),
//           _buildPillTab('Online', isSelected: false),
//           const SizedBox(width: 8),
//           _buildPillTab('Search', isSelected: false),
//         ],
//       ),
//     );
//   }

//   Widget _buildPillTab(String label, {required bool isSelected}) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//       decoration: BoxDecoration(
//         color: isSelected ? Colors.black : Colors.grey.shade100,
//         borderRadius: BorderRadius.circular(100),
//       ),
//       child: Text(
//         label,
//         style: TextStyle(
//           fontSize: 13,
//           fontWeight: FontWeight.bold,
//           color: isSelected ? Colors.white : Colors.grey.shade600,
//         ),
//       ),
//     );
//   }
// }

class _ProfileBrowserCard extends StatelessWidget {
  final MatchRecommendation profile;
  final VoidCallback onInterest;
  final VoidCallback onNotInterested;

  const _ProfileBrowserCard({
    required this.profile,
    required this.onInterest,
    required this.onNotInterested,
  });

  String? get _imageUrl {
    final primary = profile.images.where((img) => img.isPrimary);
    if (primary.isNotEmpty) return primary.first.imageUrl;
    if (profile.images.isNotEmpty) return profile.images.first.imageUrl;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.grey.shade100,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: -5,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Profile Hero Image
          _imageUrl != null
              ? Image.network(
                  _imageUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return _placeholder(showLoading: true);
                  },
                  errorBuilder: (_, __, ___) => _placeholder(),
                )
              : _placeholder(),

          // Dark Gradient Overlay at the bottom
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.5, 1.0],
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.9),
                  ],
                ),
              ),
            ),
          ),

          // Detail Overlay & Action Buttons
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child:
                Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildProfileInfo(),
                        const SizedBox(height: 32),
                        _ActionButtonsRow(
                          onInterest: onInterest,
                          onNotInterested: onNotInterested,
                        ),
                      ],
                    )
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 200.ms)
                    .slideY(begin: 0.1, end: 0),
          ),

          // View Profile Tap Area (Top portion)
          Positioned.fill(
            bottom: 300,
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileDetailScreen(
                    profileId: profile.id,
                    profileName: profile.name,
                    seedProfile: profile,
                  ),
                ),
              ),
              child: Container(color: Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${profile.name}, ${profile.age}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            if (profile.isVerified) ...[
              const SizedBox(width: 8),
              Image.asset(
                'assets/icons/verified_icon.png',
                width: 24,
                height: 24,
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        if (profile.occupation != null)
          _buildInfoRow(Icons.work_outline_rounded, profile.occupation!),
        if (profile.city != null)
          _buildInfoRow(Icons.location_on_outlined, profile.city!),
        // if (profile.religion != null)
        //   _buildInfoRow(Icons.star_border_rounded, profile.religion!),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder({bool showLoading = false}) => Container(
    color: const Color(0xFFF2F2F2),
    child: showLoading
        ? const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          )
        : null,
  );
}

class _SideNavigationButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isLeft;

  const _SideNavigationButton({
    required this.icon,
    required this.onTap,
    required this.isLeft,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child:
          Container(
                margin: EdgeInsets.only(
                  left: isLeft ? 10 : 0,
                  right: !isLeft ? 10 : 0,
                ),
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.35),
                      Colors.white.withValues(alpha: 0.1),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.45),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                      child: Center(
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 30,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 800.ms)
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.0, 1.0),
                curve: Curves.elasticOut,
                duration: 1000.ms,
              ),
    );
  }
}

class _ActionButtonsRow extends StatelessWidget {
  final VoidCallback onInterest;
  final VoidCallback onNotInterested;

  const _ActionButtonsRow({
    required this.onInterest,
    required this.onNotInterested,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: 'Not Interested',
            icon: Icons.close_rounded,
            onTap: onNotInterested,
            primary: false,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ActionButton(
            label: 'Interested',
            icon: Icons.favorite_rounded,
            onTap: onInterest,
            primary: true,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: primary ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          border: primary
              ? null
              : Border.all(color: Colors.white30, width: 1.5),
          boxShadow: primary
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
