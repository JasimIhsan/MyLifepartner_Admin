import 'dart:ui';

import 'package:country_flags/country_flags.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/core/country_helper.dart';
import 'package:life_partner_again/main.dart';
import 'package:life_partner_again/models/match_recommendation.dart';
import 'package:life_partner_again/providers/match_provider.dart';
import 'package:life_partner_again/screens/profile_detail_screen/profile_detail_screen.dart';
import 'package:life_partner_again/services/image_access_service.dart';
import 'package:life_partner_again/services/match_service.dart';
import 'package:life_partner_again/widgets/bottomsheet/custom_bottom_sheet.dart';
import 'package:life_partner_again/widgets/bottomsheet/feature_exhausted_modal.dart';
import 'package:life_partner_again/widgets/custom_button.dart';
import 'package:life_partner_again/widgets/verified_profile_bottom_sheet.dart';
import 'package:provider/provider.dart';

/// Discover screen refactored into a modern profile browser UI.
/// Each profile is displayed as a large hero card with floating navigation and interaction buttons.
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> with RouteAware {
  final PageController _pageController = PageController();
  final Set<int> _actionedProfileIds = {};
  List<MatchRecommendation> _localProfiles = [];
  int _currentIndex = 0;
  String? _loadingAction;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRecommendations();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    _fetchRecommendations();
  }

  void _fetchRecommendations() {
    if (mounted) {
      context.read<MatchProvider>().loadRecommendations().then(
        (_) => _syncWithProvider(),
      );
    }
  }

  void _syncWithProvider() {
    if (!mounted) return;
    final provider = context.read<MatchProvider>();
    setState(() {
      _localProfiles = List.from(provider.profiles);
      _currentIndex = 0;
    });
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
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

  void _showRejectionConfirmation(MatchRecommendation profile) {
    CustomBottomSheet.show(
      context: context,
      type: BottomSheetType.confirmation,
      title: 'Pass on Profile?',
      message:
          'Are you sure you want to pass on ${profile.name}? You won\'t see them again in your recommendations.',
      primaryButtonText: 'Pass Profile',
      secondaryButtonText: 'Cancel',
      imagePath: 'assets/images/illustrations/rejection.png',
      onPrimaryPressed: () {
        Navigator.pop(context); // Close bottom sheet
        _handleInteraction(profile, 'LEFT');
      },
      onSecondaryPressed: () {
        Navigator.pop(context); // Close bottom sheet
      },
    );
  }

  Future<void> _handleInteraction(
    MatchRecommendation profile,
    String action,
  ) async {
    if (_actionedProfileIds.contains(profile.id) || _loadingAction != null) {
      return;
    }

    setState(() {
      _loadingAction = action;
    });

    try {
      // Backend integration: 'RIGHT' for interest, 'LEFT' for not interested
      await MatchService.swipe(targetProfileId: profile.id, action: action);

      if (mounted) {
        setState(() {
          _actionedProfileIds.add(profile.id);
          _loadingAction = null;
        });
        // Animate to next profile smoothly only after success
        _goToNext();
      }
    } catch (e) {
      debugPrint("Action Failed: $e");
      if (mounted) {
        setState(() {
          _loadingAction = null;
        });
      }

      if (mounted && e is DioException && e.response?.statusCode == 402) {
        FeatureExhaustedModal.show(context, featureType: 'Interest');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to perform action. Please try again.'),
            ),
          );
        }
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
                          return RefreshIndicator(
                            color: AppColors.primary,
                            onRefresh: () async {
                              await context
                                  .read<MatchProvider>()
                                  .loadRecommendations();
                              _syncWithProvider();
                            },
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return SingleChildScrollView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  child: SizedBox(
                                    height: constraints.maxHeight,
                                    child: _ProfileBrowserCard(
                                      profile: profile,
                                      onInterest: () =>
                                          _handleInteraction(profile, 'RIGHT'),
                                      onNotInterested: () =>
                                          _showRejectionConfirmation(profile),
                                      onReturnFromDetail: () {
                                        context
                                            .read<MatchProvider>()
                                            .loadRecommendations()
                                            .then((_) => _syncWithProvider());
                                      },
                                      isActioning:
                                          _currentIndex == index &&
                                          _loadingAction != null,
                                      loadingAction: _currentIndex == index
                                          ? _loadingAction
                                          : null,
                                      isActioned: _actionedProfileIds.contains(
                                        profile.id,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
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
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/images/illustrations/empty_profile.png',
                height: 220,
                width: 220,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.favorite_border_rounded,
                    size: 100,
                    color: AppColors.primary.withValues(alpha: 0.5),
                  );
                },
              ),
            ).animate().fadeIn(duration: 600.ms, curve: Curves.easeOut).scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1.0, 1.0),
                  curve: Curves.easeOutBack,
                  duration: 600.ms,
                ),
            const SizedBox(height: 40),
            Text(
              'You\'re all caught up!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(
                  begin: 0.1,
                  end: 0,
                  curve: Curves.easeOutCubic,
                  duration: 500.ms,
                ),
            const SizedBox(height: 16),
            Text(
              'We are looking for more compatible profiles. Please check back in a bit for fresh recommendations.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ).animate().fadeIn(duration: 500.ms, delay: 300.ms).slideY(
                  begin: 0.1,
                  end: 0,
                  curve: Curves.easeOutCubic,
                  duration: 500.ms,
                ),
            const SizedBox(height: 48),
            SizedBox(
              width: 220,
              child: CustomButton(
                onPressed: () {
                  context.read<MatchProvider>().loadRecommendations().then(
                        (_) => _syncWithProvider(),
                      );
                },
                text: 'Refresh Profiles',
                borderRadius: 100,
                height: 52,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ).animate().fadeIn(duration: 500.ms, delay: 400.ms).slideY(
                  begin: 0.1,
                  end: 0,
                  curve: Curves.easeOutCubic,
                  duration: 500.ms,
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
  final VoidCallback? onReturnFromDetail;
  final bool isActioning;
  final String? loadingAction;
  final bool isActioned;

  const _ProfileBrowserCard({
    required this.profile,
    required this.onInterest,
    required this.onNotInterested,
    this.onReturnFromDetail,
    this.isActioning = false,
    this.loadingAction,
    this.isActioned = false,
  });

  String? get _imageUrl {
    final primary = profile.images.where((img) => img.isPrimary);
    if (primary.isNotEmpty) return primary.first.imageUrl;
    if (profile.images.isNotEmpty) return profile.images.first.imageUrl;
    return null;
  }

  bool get _isBlurred {
    final primary = profile.images.where((img) => img.isPrimary);
    if (primary.isNotEmpty) return primary.first.isBlurred;
    if (profile.images.isNotEmpty) return profile.images.first.isBlurred;
    return false;
  }

  bool _isNewProfile(String isoString) {
    try {
      if (isoString.isEmpty) return false;
      final date = DateTime.parse(isoString);
      final diff = DateTime.now().difference(date);
      return diff.inDays <= 7;
    } catch (_) {
      return false;
    }
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
          if (_isNewProfile(profile.createdAt.toString()))
            Positioned(
              top: 24,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  'NEW',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
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
                        _buildProfileInfo(context),
                        const SizedBox(height: 32),
                        _ActionButtonsRow(
                          onInterest: onInterest,
                          onNotInterested: onNotInterested,
                          isActioning: isActioning,
                          loadingAction: loadingAction,
                          isActioned: isActioned,
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
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileDetailScreen(
                      profileId: profile.id,
                      profileName: profile.name,
                    ),
                  ),
                );
                if (onReturnFromDetail != null) {
                  onReturnFromDetail!();
                }
              },
              child: Container(color: Colors.transparent),
            ),
          ),

          // Country Flag Top Right
          if (CountryHelper.getCode(profile.country) != null)
            Positioned(
              top: 24,
              right: 20,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: CountryFlag.fromCountryCode(
                    CountryHelper.getCode(profile.country)!,
                    width: 36,
                    height: 36,
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
            ),
          if (_isBlurred)
            Align(
              alignment: Alignment.center,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      profile.viewerPrivacyEnabled
                          ? 'Your profile is private'
                          : 'Photos are private',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      profile.viewerPrivacyEnabled
                          ? 'You need access to see ${profile.name}\'s photos.'
                          : 'Request access to see ${profile.name}\'s photos.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    _RequestAccessButton(profile: profile),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo(BuildContext context) {
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
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (_) =>
                        VerifiedProfileBottomSheet(profileName: profile.name),
                  );
                },
                child: Image.asset(
                  'assets/icons/verified_icon.png',
                  width: 24,
                  height: 24,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        if (profile.maritalStatus != null)
          _buildInfoRow(
            Icons.favorite_border_rounded,
            _formatEnum(profile.maritalStatus!),
          ),
        if (profile.city != null)
          _buildInfoRow(Icons.location_on_outlined, profile.city!),
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

  String _formatEnum(String value) {
    return value
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .map(
          (w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '',
        )
        .join(' ');
  }
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
                  left: isLeft ? 25 : 0,
                  right: !isLeft ? 25 : 0,
                ),
                width: 55,
                height: 55,
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.4),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 1.0,
                        ),
                      ),
                      child: Center(
                        child: Icon(icon, color: Colors.white, size: 24),
                      ),
                    ),
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 400.ms)
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.0, 1.0),
                curve: Curves.easeOutBack,
                duration: 500.ms,
              ),
    );
  }
}

class _ActionButtonsRow extends StatelessWidget {
  final VoidCallback onInterest;
  final VoidCallback onNotInterested;
  final bool isActioning;
  final String? loadingAction;
  final bool isActioned;

  const _ActionButtonsRow({
    required this.onInterest,
    required this.onNotInterested,
    this.isActioning = false,
    this.loadingAction,
    this.isActioned = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: '',
            icon: Icons.heart_broken,
            onTap: (isActioning || isActioned) ? () {} : onNotInterested,
            primary: false,
            isLoading: isActioning && loadingAction == 'LEFT',
            isDisabled: isActioned,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ActionButton(
            label: '',
            icon: Icons.favorite_rounded,
            onTap: (isActioning || isActioned) ? () {} : onInterest,
            primary: true,
            isLoading: isActioning && loadingAction == 'RIGHT',
            isDisabled: isActioned,
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
  final bool isLoading;
  final bool isDisabled;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.primary,
    this.isLoading = false,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color buttonColor = isDisabled
        ? Colors.grey.shade400
        : (primary ? AppColors.primary : Colors.transparent);

    return GestureDetector(
      onTap: (isLoading || isDisabled) ? null : onTap,
      child: Opacity(
        opacity: (isLoading || isDisabled) ? 0.6 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: buttonColor,
            borderRadius: BorderRadius.circular(100),
            border: (primary || isDisabled)
                ? null
                : Border.all(color: Colors.white30, width: 1.5),
            boxShadow: (primary && !isDisabled && !isLoading)
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
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else ...[
                Icon(icon, color: Colors.white, size: 20),
                if (label.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestAccessButton extends StatefulWidget {
  final MatchRecommendation profile;
  const _RequestAccessButton({required this.profile});

  @override
  State<_RequestAccessButton> createState() => _RequestAccessButtonState();
}

class _RequestAccessButtonState extends State<_RequestAccessButton> {
  bool _isLoading = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _status = widget.profile.imageAccessRequestStatus;
  }

  Future<void> _sendRequest() async {
    setState(() {
      _isLoading = true;
    });
    final success = await ImageAccessService.requestAccess(
      widget.profile.userId,
    );
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (success) {
          _status = 'PENDING';
        }
      });
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Access request sent successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send access request')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_status == 'PENDING') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'Access Pending',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    if (_status == 'APPROVED') {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        onPressed: _isLoading ? () {} : _sendRequest,
        text: _isLoading ? 'Sending...' : 'Request Access',
        height: 40,
        borderRadius: 12,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
