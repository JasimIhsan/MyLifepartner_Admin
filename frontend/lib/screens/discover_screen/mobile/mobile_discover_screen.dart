import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/providers/match_provider.dart';
import 'package:life_partner_again/screens/profile_detail_screen/widgets/report_user_dialog.dart';
import 'package:life_partner_again/services/block_service.dart';
import 'package:life_partner_again/services/image_access_service.dart';
import 'package:life_partner_again/widgets/bottomsheet/block_confirmation_bottom_sheet.dart';
import 'package:life_partner_again/widgets/cached_app_image.dart';
import 'package:life_partner_again/widgets/custom_button.dart';
import 'package:life_partner_again/widgets/feature_download_prompt.dart';
import 'package:life_partner_again/widgets/founding_member_badge.dart';
import 'package:life_partner_again/widgets/fullscreen_image_preview.dart';
import 'package:life_partner_again/widgets/verified_icon.dart';
import 'package:provider/provider.dart';

import '../widgets/discover_components.dart';
import 'package:life_partner_again/widgets/tour/app_tour_overlay.dart';
import 'package:life_partner_again/widgets/tour/app_tour_step.dart';
import '../widgets/discover_controller.dart';

class MobileDiscoverScreen extends StatefulWidget {
  const MobileDiscoverScreen({super.key});

  @override
  State<MobileDiscoverScreen> createState() => _MobileDiscoverScreenState();
}

class _MobileDiscoverScreenState extends State<MobileDiscoverScreen>
    with DiscoverControllerState {
  final BlockService _blockService = BlockService();
  bool _isBottomNavVisible = true;

  final GlobalKey _passBtnKey = GlobalKey();
  final GlobalKey _likeBtnKey = GlobalKey();

  List<AppTourStep> get _discoverTourSteps => [
        AppTourStep(
          targetKey: _likeBtnKey,
          title: 'Like Profiles',
          description: 'Tap the heart icon to send a like to profiles you feel connected with.',
          borderRadius: const BorderRadius.all(Radius.circular(40)),
          preferredPosition: TourCardPosition.top,
        ),
        AppTourStep(
          targetKey: _passBtnKey,
          title: 'Pass Profiles',
          description: 'Tap the broken heart icon to pass on a profile and view the next match.',
          borderRadius: const BorderRadius.all(Radius.circular(40)),
          preferredPosition: TourCardPosition.top,
        ),
      ];

  final GlobalKey _nextBtnKey = GlobalKey();
  final GlobalKey _prevBtnKey = GlobalKey();

  List<AppTourStep> get _discoverNextTourSteps => [
        AppTourStep(
          targetKey: _nextBtnKey,
          title: 'Next Profile',
          description: 'Tap here to quickly view the next profile.',
          borderRadius: const BorderRadius.all(Radius.circular(40)),
          preferredPosition: TourCardPosition.left,
        ),
      ];

  List<AppTourStep> get _discoverPrevTourSteps => [
        AppTourStep(
          targetKey: _prevBtnKey,
          title: 'Previous Profile',
          description: 'Tap here to go back to the previous profile.',
          borderRadius: const BorderRadius.all(Radius.circular(40)),
          preferredPosition: TourCardPosition.right,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final bool canGoNext = localProfiles.length > 1 && currentIndex < localProfiles.length - 1;

    Widget content = Scaffold(
      backgroundColor: Theme.of(context).canvasColor,
        body: SafeArea(
          bottom: false,
          child: Consumer<MatchProvider>(
          builder: (context, provider, _) {
            if (provider.state == MatchLoadState.loading &&
                localProfiles.isEmpty) {
              return _buildLoading();
            }

            if (provider.state == MatchLoadState.error &&
                localProfiles.isEmpty) {
              return _buildError(provider);
            }

            if (localProfiles.isEmpty) {
              return _buildEmpty();
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                // Compute button size dynamically based on screen dimensions (e.g. 17% of width, clamped between 64 and 84)
                final btnSize = (screenWidth * 0.17).clamp(64.0, 84.0);
                final iconSize = btnSize * 0.58;
                // When bottom nav is hidden and centered, calculate offset using exact btnSize
                final hiddenCenterOffset = (screenWidth / 2) - btnSize - 12;

                return NotificationListener<UserScrollNotification>(
                  onNotification: (notification) {
                    if (notification.direction == ScrollDirection.reverse) {
                      if (_isBottomNavVisible) {
                        setState(() => _isBottomNavVisible = false);
                      }
                    } else if (notification.direction == ScrollDirection.forward) {
                      if (!_isBottomNavVisible) {
                        setState(() => _isBottomNavVisible = true);
                      }
                    }
                    return false;
                  },
                  child: Stack(
                    children: [
                      // Full-screen scrollable profile detail pager
                      PageView.builder(
                        controller: pageController,
                        onPageChanged: (idx) => setState(() => currentIndex = idx),
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: localProfiles.length,
                        itemBuilder: (context, index) {
                          final profile = localProfiles[index];
                          final profileMap = profile.toDetailMap();
                          return _InlineProfileDetail(
                            profileMap: profileMap,
                            onReportPressed: () =>
                                ReportUserDialog.show(context, profileMap),
                            onBlockPressed: () =>
                                _showBlockConfirmation(context, profileMap),
                          );
                        },
                      ),

                      // Left Prev button – floats at vertical center of left edge
                      if (currentIndex > 0)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: SideNavigationButton(
                            buttonKey: _prevBtnKey,
                            icon: Icons.chevron_left_rounded,
                            onTap: goToPrevious,
                            isLeft: true,
                          ),
                        ),

                      // Right Next button – floats at vertical center of right edge
                      if (currentIndex < localProfiles.length - 1)
                        Align(
                          alignment: Alignment.centerRight,
                          child: SideNavigationButton(
                            buttonKey: _nextBtnKey,
                            icon: Icons.chevron_right_rounded,
                            onTap: goToNext,
                            isLeft: false,
                          ),
                        ),

                      // Left Action Floating Button (Pass)
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        bottom: _isBottomNavVisible
                            ? MediaQuery.of(context).padding.bottom - 4
                            : 32,
                        left: _isBottomNavVisible ? 24 : hiddenCenterOffset,
                        child: SizedBox(
                          key: _passBtnKey,
                          width: btnSize,
                          height: btnSize,
                          child: FloatingActionButton(
                            heroTag: 'pass_btn',
                            onPressed: loadingAction != null
                                ? null
                                : () {
                                    if (FeatureDownloadPrompt.intercept(
                                      context,
                                      featureName: 'Match & Connect',
                                    )) {
                                      return;
                                    }
                                    handleInteraction(
                                      localProfiles[currentIndex],
                                      'LEFT',
                                    );
                                  },
                            backgroundColor: Theme.of(context).cardColor,
                            foregroundColor: Colors.black,
                            elevation: 4,
                            shape: const CircleBorder(),
                            child: Icon(Icons.heart_broken_rounded, size: iconSize),
                          ),
                        ),
                      ),

                      // Right Action Floating Button (Favorite)
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        bottom: _isBottomNavVisible
                            ? MediaQuery.of(context).padding.bottom - 4
                            : 32,
                        right: _isBottomNavVisible ? 24 : hiddenCenterOffset,
                        child: SizedBox(
                          key: _likeBtnKey,
                          width: btnSize,
                          height: btnSize,
                          child: FloatingActionButton(
                            heroTag: 'favorite_btn',
                            onPressed: loadingAction != null
                                ? null
                                : () {
                                    if (FeatureDownloadPrompt.intercept(
                                      context,
                                      featureName: 'Match & Connect',
                                    )) {
                                      return;
                                    }
                                    handleInteraction(
                                      localProfiles[currentIndex],
                                      'RIGHT',
                                    );
                                  },
                            backgroundColor: Theme.of(context).cardColor,
                            foregroundColor: Theme.of(context).primaryColor,
                            elevation: 4,
                            shape: const CircleBorder(),
                            child: Icon(Icons.favorite_rounded, size: iconSize),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );

    content = AppTourOverlay(
      pageId: 'discover_prev',
      dependsOn: const ['discover_next'],
      steps: _discoverPrevTourSteps,
      enabled: currentIndex > 0,
      child: content,
    );

    content = AppTourOverlay(
      pageId: 'discover_next',
      dependsOn: const ['discover'],
      steps: _discoverNextTourSteps,
      enabled: canGoNext,
      child: content,
    );

    content = AppTourOverlay(
      pageId: 'discover',
      dependsOn: const ['home'],
      steps: _discoverTourSteps,
      child: content,
    );

    return content;
  }

  void _showBlockConfirmation(
    BuildContext context,
    Map<String, dynamic> profile,
  ) {
    BlockConfirmationBottomSheet.show(
      context: context,
      isBlocking: true,
      userName: profile['name'] as String? ?? 'this user',
      onConfirm: () async {
        await _blockService.blockUser(profile['userId'] as int);
      },
      onSuccess: () {
        final profileId = profile['id'] as int?;
        if (profileId != null) {
          context.read<MatchProvider>().removeProfile(profileId);
        }
      },
    );
  }

  Widget _buildLoading() {
    return Container(
      color: Theme.of(context).canvasColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              "Finding best matches for you...",
              style: TextStyle(
                color:
                    Theme.of(context).textTheme.bodyMedium?.color ??
                    AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(MatchProvider provider) {
    return Container(
      color: Theme.of(context).canvasColor,
      child: Center(
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
                  color:
                      Theme.of(context).textTheme.bodyLarge?.color ??
                      AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                provider.error ?? 'Something went wrong',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:
                      Theme.of(context).textTheme.bodyMedium?.color ??
                      AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: 'Retry',
                onPressed: () => provider.loadRecommendations().then(
                  (_) => syncWithProvider(),
                ),
                height: 48,
                borderRadius: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      color: Theme.of(context).canvasColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.05),
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
                          color: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.5),
                        );
                      },
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                  .scale(
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
                      color:
                          Theme.of(context).textTheme.bodyLarge?.color ??
                          AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  )
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 200.ms)
                  .slideY(
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
                      color:
                          Theme.of(context).textTheme.bodyMedium?.color ??
                          AppColors.textSecondary,
                      height: 1.5,
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 300.ms)
                  .slideY(
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
                        context
                            .read<MatchProvider>()
                            .loadRecommendations()
                            .then((_) => syncWithProvider());
                      },
                      text: 'Refresh Profiles',
                      borderRadius: 100,
                      height: 52,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 400.ms)
                  .slideY(
                    begin: 0.1,
                    end: 0,
                    curve: Curves.easeOutCubic,
                    duration: 500.ms,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Inline profile detail widget – renders the complete profile detail UI
// directly inside the Discover screen without any navigation.
// ─────────────────────────────────────────────────────────────────────────────

class _InlineProfileDetail extends StatelessWidget {
  final Map<String, dynamic> profileMap;
  final VoidCallback onReportPressed;
  final VoidCallback onBlockPressed;

  const _InlineProfileDetail({
    required this.profileMap,
    required this.onReportPressed,
    required this.onBlockPressed,
  });

  @override
  Widget build(BuildContext context) {
    final images = (profileMap['images'] as List<dynamic>? ?? []);
    final isBlurred =
        images.isNotEmpty &&
        images.first is Map &&
        images.first['isBlurred'] == true;
    final isPrivate = profileMap['viewerPrivacyEnabled'] == true || isBlurred;
    final bodyImages = (images.length > 1 && !isPrivate)
        ? images.skip(1).toList()
        : [];

    return RefreshIndicator(
      onRefresh: () async {
        await context.read<MatchProvider>().loadRecommendations();
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHero(context, profileMap, images),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                      child: _buildContent(
                        context,
                        profileMap,
                        bodyImages,
                        onReportPressed,
                        onBlockPressed,
                      ),
                    ),
                    Builder(
                      builder: (ctx) => SizedBox(
                        height: MediaQuery.of(ctx).padding.bottom + 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(
    BuildContext context,
    Map<String, dynamic> profile,
    List<dynamic> images,
  ) {
    if (images.isEmpty) {
      return SizedBox(
        height: 500,
        child: DecoratedBox(
          decoration: BoxDecoration(color: Theme.of(context).primaryColorLight),
          child: const Center(
            child: Icon(LucideIcons.user, size: 84, color: Color(0xFFCCCCCC)),
          ),
        ),
      );
    }

    final firstImage = images.first;

    return GestureDetector(
      onTap: (firstImage is Map && firstImage['isBlurred'] == true)
          ? null
          : () {
              FullscreenImagePreview.show(
                context,
                images: images,
                initialIndex: 0,
              );
            },
      child: Stack(
        children: [
          _ProfileAspectPhoto(
            image: firstImage,
            borderRadius: BorderRadius.zero,
            fallbackAspectRatio: 0.78,
            allImages: images,
            imageIndex: 0,
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.78),
                      Colors.black.withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                    stops: const [0, 0.45, 1],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: SafeArea(
                bottom: false,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (firstImage is Map &&
                                  firstImage['isBlurred'] == true) ...[
                                const Spacer(flex: 4),
                                _buildPrivacyOverlay(context, profile),
                                const Spacer(flex: 1),
                              ] else
                                const Spacer(),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: _HeroProfileInfo(profile: profile),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    Map<String, dynamic> profile,
    List<dynamic> images,
    VoidCallback onReportPressed,
    VoidCallback onBlockPressed,
  ) {
    final children = <Widget>[];
    int imageIndex = 0;

    final allImagesList = (profile['images'] as List<dynamic>? ?? []);

    if (_hasText(profile['bio'])) {
      children.add(_buildSectionTitle(context, 'About'));
      children.add(const SizedBox(height: 10));
      children.add(_buildAbout(context, profile['bio'].toString()));
      children.add(const SizedBox(height: 22));
    }

    if (imageIndex < images.length) {
      final img = images[imageIndex++];
      final overallIdx = allImagesList.indexOf(img);
      children.add(_buildInlinePhoto(img, allImagesList, overallIdx >= 0 ? overallIdx : imageIndex));
    }

    final basics = _basicItems(profile);
    if (basics.isNotEmpty) {
      children.add(_buildSectionTitle(context, 'The Basics'));
      children.add(const SizedBox(height: 12));
      children.add(_BasicsList(items: basics));
      children.add(const SizedBox(height: 26));
    }

    final career = _careerItems(profile);
    if (career.isNotEmpty) {
      children.add(_buildSectionTitle(context, 'Education & Career'));
      children.add(const SizedBox(height: 12));
      children.add(_CardGrid(items: career));
      children.add(const SizedBox(height: 22));
    }

    if (imageIndex < images.length) {
      final img = images[imageIndex++];
      final overallIdx = allImagesList.indexOf(img);
      children.add(_buildInlinePhoto(img, allImagesList, overallIdx >= 0 ? overallIdx : imageIndex));
    }

    final lifestyle = _lifestyleItems(profile);
    if (lifestyle.isNotEmpty) {
      children.add(_buildSectionTitle(context, 'Lifestyle'));
      children.add(const SizedBox(height: 12));
      children.add(_CardGrid(items: lifestyle, compact: true));
      children.add(const SizedBox(height: 26));
    }

    final languages = _languages(profile);
    if (languages.isNotEmpty) {
      children.add(_buildSectionTitle(context, 'Languages'));
      children.add(const SizedBox(height: 14));
      children.add(_LanguageChips(languages: languages));
      children.add(const SizedBox(height: 26));
    }

    final lookingFor = _lookingForText(profile);
    if (lookingFor != null) {
      children.add(_buildSectionTitle(context, 'Looking For'));
      children.add(const SizedBox(height: 12));
      children.add(_LookingForCard(text: lookingFor));
      children.add(const SizedBox(height: 22));
    }

    while (imageIndex < images.length) {
      final img = images[imageIndex++];
      final overallIdx = allImagesList.indexOf(img);
      children.add(_buildInlinePhoto(img, allImagesList, overallIdx >= 0 ? overallIdx : imageIndex));
    }

    children.add(const SizedBox(height: 16));
    children.add(
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(
            onTap: onBlockPressed,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                'Block User',
                style: TextStyle(
                  color:
                      Theme.of(
                        context,
                      ).textTheme.bodyLarge?.color?.withValues(alpha: 0.85) ??
                      Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
          Container(
            width: 1.5,
            height: 12,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          InkWell(
            onTap: onReportPressed,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                'Report User',
                style: TextStyle(
                  color: Colors.grey.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
    children.add(
      const SizedBox(height: 20),
    ); // Space to ensure it scrolls completely above the FABs

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: Theme.of(context).primaryColor,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildAbout(BuildContext context, String bio) {
    return Text(
      bio,
      style: TextStyle(
        color:
            Theme.of(context).textTheme.bodyLarge?.color ??
            AppColors.textPrimary,
        fontSize: 15,
        height: 1.55,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  Widget _buildInlinePhoto(dynamic image, List<dynamic> allImages, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: _ProfileAspectPhoto(
        image: image,
        borderRadius: BorderRadius.circular(12),
        fallbackAspectRatio: 16 / 10,
        allImages: allImages,
        imageIndex: index,
      ),
    );
  }

  Widget _buildPrivacyOverlay(
    BuildContext context,
    Map<String, dynamic> profile,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 56),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.lock, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            (profile['viewerPrivacyEnabled'] == true)
                ? 'Your profile is private'
                : 'Photos are private',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            (profile['viewerPrivacyEnabled'] == true)
                ? "You need access to see ${profile['name'] ?? 'this user'}'s photos."
                : "Request access to see ${profile['name'] ?? 'this user'}'s photos.",
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          _DiscoverRequestAccessButton(
            userId: profile['userId'] as int? ?? 0,
            imageAccessRequestStatus:
                profile['imageAccessRequestStatus'] as String?,
          ),
        ],
      ),
    );
  }

  // ── Data helpers ─────────────────────────────────────────────────────────

  List<_ProfileInfoItem> _basicItems(Map<String, dynamic> profile) {
    return [
      if (_hasText(profile['gender']))
        _ProfileInfoItem(
          icon: LucideIcons.heart,
          label: 'Gender',
          value: _formatEnum(profile['gender'].toString()),
        ),
      if (profile['heightCm'] != null)
        _ProfileInfoItem(
          icon: LucideIcons.ruler,
          label: 'Height',
          value: _formatHeight(profile['heightCm']),
        ),
      if (_hasText(profile['maritalStatus']))
        _ProfileInfoItem(
          icon: LucideIcons.users,
          label: 'Marital status',
          value: _formatEnum(profile['maritalStatus'].toString()),
        ),
      if (_hasText(profile['country']))
        _ProfileInfoItem(
          icon: LucideIcons.map_pin,
          label: 'Country',
          value: profile['country'].toString(),
        ),
      if (_hasText(profile['childrenStatus']))
        _ProfileInfoItem(
          icon: LucideIcons.baby,
          label: 'Children',
          value: _formatEnum(profile['childrenStatus'].toString()),
        ),
    ];
  }

  List<_ProfileInfoItem> _careerItems(Map<String, dynamic> profile) {
    return [
      if (_hasText(profile['highestEducation']))
        _ProfileInfoItem(
          icon: LucideIcons.graduation_cap,
          label: 'Education',
          value: _readableEducation(profile['highestEducation'].toString()),
        ),
      if (_hasText(profile['occupation']))
        _ProfileInfoItem(
          icon: LucideIcons.briefcase,
          label: 'Profession',
          value: profile['occupation'].toString(),
        ),
    ];
  }

  List<_ProfileInfoItem> _lifestyleItems(Map<String, dynamic> profile) {
    return [
      if (_hasText(profile['smokingHabit']))
        _ProfileInfoItem(
          icon: LucideIcons.cigarette,
          label: 'Smoking',
          value: _formatEnum(profile['smokingHabit'].toString()),
        ),
      if (_hasText(profile['drinkingHabit']))
        _ProfileInfoItem(
          icon: LucideIcons.glass_water,
          label: 'Drinking',
          value: _formatEnum(profile['drinkingHabit'].toString()),
        ),
    ];
  }

  List<String> _languages(Map<String, dynamic> profile) {
    final values = <String>[];
    final rawLanguages = profile['languages'];

    if (rawLanguages is List) {
      values.addAll(rawLanguages.whereType<String>());
    }

    if (_hasText(profile['motherTongue'])) {
      values.insert(0, profile['motherTongue'].toString());
    }

    final seen = <String>{};
    return values.where((value) {
      final normalized = value.trim().toLowerCase();
      if (normalized.isEmpty || seen.contains(normalized)) return false;
      seen.add(normalized);
      return true;
    }).toList();
  }

  String? _lookingForText(Map<String, dynamic> profile) {
    final values = <String>[];
    if (_hasText(profile['lookingFor'])) {
      values.add(_formatEnum(profile['lookingFor'].toString()));
    }
    if (_hasText(profile['relationshipTimeline'])) {
      values.add(_formatEnum(profile['relationshipTimeline'].toString()));
    }
    if (values.isEmpty) return null;
    return values.join(' / ');
  }

  bool _hasText(dynamic value) => value != null && value.toString().isNotEmpty;

  String _formatHeight(dynamic rawCm) {
    final cm = rawCm is int
        ? rawCm
        : rawCm is num
        ? rawCm.toInt()
        : int.tryParse(rawCm.toString());

    if (cm == null || cm <= 0) return rawCm.toString();

    final feet = cm ~/ 30.48;
    final inches = ((cm % 30.48) / 2.54).round();
    return '$feet\'$inches" ($cm cm)';
  }

  String _readableEducation(String value) {
    switch (value) {
      case 'HIGH_SCHOOL':
        return 'High School';
      case 'DIPLOMA_CERTIFICATE':
        return 'Diploma / Certificate';
      case 'BACHELORS':
        return "Bachelor's Degree";
      case 'MASTERS':
        return "Master's Degree";
      case 'DOCTORATE':
        return 'Doctorate / PhD';
      case 'OTHER':
        return 'Other';
      default:
        return _formatEnum(value);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private sub-widgets (same design as MobileProfileDetailScreen)
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileAspectPhoto extends StatelessWidget {
  final dynamic image;
  final BorderRadius borderRadius;
  final double fallbackAspectRatio;
  final List<dynamic>? allImages;
  final int imageIndex;

  const _ProfileAspectPhoto({
    required this.image,
    required this.borderRadius,
    required this.fallbackAspectRatio,
    this.allImages,
    this.imageIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final imagesList = allImages ?? [image];
    final isBlurred = image is Map && image['isBlurred'] == true;

    return GestureDetector(
      onTap: isBlurred
          ? null
          : () {
              FullscreenImagePreview.show(
                context,
                images: imagesList,
                initialIndex: imageIndex,
              );
            },
      child: ClipRRect(
        borderRadius: borderRadius,
        child: CachedAppImage.fromProfileImageMap(
          image: image,
          width: double.infinity,
          fit: BoxFit.contain,
          imageBuilder: (context, imageProvider) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth.isFinite
                    ? constraints.maxWidth
                    : MediaQuery.of(context).size.width;

                return Image(
                  image: imageProvider,
                  width: width,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                );
              },
            );
          },
          placeholder: (context, url) =>
              _PhotoPlaceholder(aspectRatio: fallbackAspectRatio),
          errorWidget: (context, url, error) => _PhotoPlaceholder(
            aspectRatio: fallbackAspectRatio,
            icon: LucideIcons.image_off,
          ),
        ),
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  final double aspectRatio;
  final IconData? icon;

  const _PhotoPlaceholder({required this.aspectRatio, this.icon});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColorLight.withValues(alpha: 0.12),
        ),
        child: Center(
          child: icon == null
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).primaryColor,
                  ),
                )
              : Icon(
                  icon,
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withValues(alpha: 0.55),
                ),
        ),
      ),
    );
  }
}

class _HeroProfileInfo extends StatelessWidget {
  final Map<String, dynamic> profile;

  const _HeroProfileInfo({required this.profile});

  @override
  Widget build(BuildContext context) {
    final name = profile['name']?.toString() ?? 'Unknown';
    final age = profile['age']?.toString();
    final title = (age == null || age.isEmpty || age == '0')
        ? name
        : '$name, $age';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _MatchPill(percentage: profile['matchPercentage'] ?? 0),
        const SizedBox(height: 10),
        Row(
          children: [
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
            ),
            if (profile['isVerified'] == true ||
                profile['isPremium'] == true ||
                profile['isFoundingMember'] == true) ...[
              const SizedBox(width: 6),
              VerifiedIconWidget(
                isVerified: profile['isVerified'] == true,
                isFoundingMember: profile['isFoundingMember'] == true,
                isPremium: profile['isPremium'] == true,
                size: 20,
              ),
            ],
            if (profile['isFoundingMember'] == true) ...[
              const SizedBox(width: 6),
              const FoundingMemberBadge(size: 20, isOverlay: true),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (profile['city'] != null || profile['state'] != null)
              _HeroMetaItem(
                icon: LucideIcons.map_pin,
                text: [
                  profile['city'],
                  profile['state'],
                ].where((v) => v != null).join(', '),
              ),
            if (profile['maritalStatus'] != null)
              _HeroMetaItem(
                icon: LucideIcons.heart,
                text: _formatEnum(profile['maritalStatus'].toString()),
              ),
            if (profile['lastLoginAt'] != null)
              _HeroMetaItem(
                icon: LucideIcons.circle,
                text: _formatLastLogin(profile['lastLoginAt'].toString()),
                iconColor: const Color(0xFF37C871),
              ),
          ],
        ),
      ],
    );
  }
}

class _HeroMetaItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? iconColor;

  const _HeroMetaItem({required this.icon, required this.text, this.iconColor});

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: icon == LucideIcons.circle ? 7 : 14,
          color: iconColor ?? Colors.white,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _MatchPill extends StatelessWidget {
  final dynamic percentage;

  const _MatchPill({required this.percentage});

  @override
  Widget build(BuildContext context) {
    final pct = percentage is num
        ? percentage.round()
        : int.tryParse(percentage.toString()) ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Text(
        '$pct% Match',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _BasicsList extends StatelessWidget {
  final List<_ProfileInfoItem> items;

  const _BasicsList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(items.length, (index) {
        final item = items[index];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: Row(
                children: [
                  Icon(
                    item.icon,
                    size: 20,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    item.label,
                    style: TextStyle(
                      color:
                          Theme.of(context).textTheme.bodyMedium?.color ??
                          AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      item.value,
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color:
                            Theme.of(context).textTheme.bodyLarge?.color ??
                            AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (index != items.length - 1)
              Divider(
                height: 1,
                color: Theme.of(context).dividerColor.withValues(alpha: 0.72),
              ),
          ],
        );
      }),
    );
  }
}

class _CardGrid extends StatelessWidget {
  final List<_ProfileInfoItem> items;
  final bool compact;

  const _CardGrid({required this.items, this.compact = false});

  @override
  Widget build(BuildContext context) {
    if (items.length == 1) {
      return _InfoCard(item: items.first, compact: compact);
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            Expanded(
              child: _InfoCard(item: items[i], compact: compact),
            ),
            if (i != items.length - 1) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final _ProfileInfoItem item;
  final bool compact;

  const _InfoCard({required this.item, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: compact ? 68 : 92),
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(item.icon, color: Theme.of(context).primaryColor, size: 20),
          SizedBox(height: compact ? 7 : 12),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color:
                  Theme.of(context).textTheme.bodyMedium?.color ??
                  AppColors.textSecondary,
              fontSize: compact ? 11 : 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color:
                  Theme.of(context).textTheme.bodyLarge?.color ??
                  AppColors.textPrimary,
              fontSize: compact ? 13 : 14,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageChips extends StatelessWidget {
  final List<String> languages;

  const _LanguageChips({required this.languages});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: languages.map((language) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.languages,
                color: Theme.of(context).primaryColor,
                size: 16,
              ),
              const SizedBox(width: 7),
              Text(
                language,
                style: TextStyle(
                  color:
                      Theme.of(context).textTheme.bodyLarge?.color ??
                      AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _LookingForCard extends StatelessWidget {
  final String text;

  const _LookingForCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.heart,
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color:
                    Theme.of(context).textTheme.bodyLarge?.color ??
                    AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileInfoItem {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileInfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}

// ── Request Access button (uses ImageAccessService directly) ─────────────────

class _DiscoverRequestAccessButton extends StatefulWidget {
  final int userId;
  final String? imageAccessRequestStatus;

  const _DiscoverRequestAccessButton({
    required this.userId,
    required this.imageAccessRequestStatus,
  });

  @override
  State<_DiscoverRequestAccessButton> createState() =>
      _DiscoverRequestAccessButtonState();
}

class _DiscoverRequestAccessButtonState
    extends State<_DiscoverRequestAccessButton> {
  bool _isLoading = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _status = widget.imageAccessRequestStatus;
  }

  @override
  void didUpdateWidget(covariant _DiscoverRequestAccessButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _status = widget.imageAccessRequestStatus;
    }
  }

  Future<void> _sendRequest() async {
    setState(() => _isLoading = true);
    final success = await ImageAccessService.requestAccess(widget.userId);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (success) _status = 'PENDING';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Access request sent successfully'
                : 'Failed to send access request',
          ),
        ),
      );
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

// ── Free-standing format helpers ─────────────────────────────────────────────

String _formatEnum(String value) {
  return value
      .replaceAll('_', ' ')
      .toLowerCase()
      .split(' ')
      .map((word) {
        if (word.isEmpty) return '';
        return '${word[0].toUpperCase()}${word.substring(1)}';
      })
      .join(' ');
}

String _formatLastLogin(String isoString) {
  try {
    if (isoString.isEmpty) return '';
    final date = DateTime.parse(isoString);
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) {
      if (diff.inHours == 0) return 'Active just now';
      return 'Active ${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Active yesterday';
    }
    return 'Active ${diff.inDays}d ago';
  } catch (_) {
    return '';
  }
}
