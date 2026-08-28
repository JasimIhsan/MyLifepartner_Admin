import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/providers/match_provider.dart';
import 'package:life_partner_again/screens/profile_detail_screen/widgets/report_user_dialog.dart';
import 'package:life_partner_again/services/block_service.dart';
import 'package:life_partner_again/services/image_access_service.dart';
import 'package:life_partner_again/widgets/bottomsheet/block_confirmation_bottom_sheet.dart';
import 'package:life_partner_again/widgets/cached_app_image.dart';
import 'package:life_partner_again/widgets/custom_button.dart';
import 'package:life_partner_again/widgets/founding_member_badge.dart';
import 'package:life_partner_again/widgets/fullscreen_image_preview.dart';
import 'package:life_partner_again/widgets/verified_icon.dart';
import 'package:life_partner_again/widgets/feature_download_prompt.dart';
import 'package:provider/provider.dart';

import '../widgets/discover_controller.dart';

class WebDiscoverScreen extends StatefulWidget {
  const WebDiscoverScreen({super.key});

  @override
  State<WebDiscoverScreen> createState() => _WebDiscoverScreenState();
}

class _WebDiscoverScreenState extends State<WebDiscoverScreen>
    with DiscoverControllerState {
  final BlockService _blockService = BlockService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).canvasColor,
      body: Consumer<MatchProvider>(
        builder: (context, provider, _) {
          if (provider.state == MatchLoadState.loading &&
              localProfiles.isEmpty) {
            return _buildLoading();
          }

          if (provider.state == MatchLoadState.error && localProfiles.isEmpty) {
            return _buildError(provider);
          }

          if (localProfiles.isEmpty) {
            return _buildEmpty();
          }

          final selectedProfile = localProfiles[currentIndex];
          final profileMap = selectedProfile.toDetailMap();

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 80,
                      vertical: 24,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left Side - Photos Gallery
                        Expanded(
                          flex: 5,
                          child: _WebPhotoGallery(
                            profileMap: profileMap,
                            onPass: () {
                              if (FeatureDownloadPrompt.intercept(context, featureName: 'Match & Connect')) return;
                              handleInteraction(selectedProfile, 'LEFT');
                            },
                            onLike: () {
                              if (FeatureDownloadPrompt.intercept(context, featureName: 'Match & Connect')) return;
                              handleInteraction(selectedProfile, 'RIGHT');
                            },
                            isLoading: loadingAction != null,
                          ),
                        ),
                        // Right Side - Compact Scrollable Details
                        Expanded(
                          flex: 7,
                          child: Container(
                            color: Theme.of(context).canvasColor,
                            child: _WebProfileDetails(
                              profileMap: profileMap,
                              onReportPressed: () =>
                                  ReportUserDialog.show(context, profileMap),
                              onBlockPressed: () =>
                                  _showBlockConfirmation(context, profileMap),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Left Nav
                  if (currentIndex > 0)
                    Positioned(
                      left: 16,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: _buildNavButton(
                          isNext: false,
                          onTap: goToPrevious,
                        ),
                      ),
                    ),
                  // Right Nav
                  if (currentIndex < localProfiles.length - 1)
                    Positioned(
                      right: 16,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: _buildNavButton(isNext: true, onTap: goToNext),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
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

  Widget _buildNavButton({required bool isNext, required VoidCallback? onTap}) {
    final bool isDisabled = onTap == null;
    return MouseRegion(
      cursor: isDisabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isDisabled
                ? Theme.of(context).disabledColor.withValues(alpha: 0.1)
                : Theme.of(context).colorScheme.surface,
            shape: BoxShape.circle,
            boxShadow: isDisabled
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
            border: Border.all(
              color: isDisabled
                  ? Colors.transparent
                  : Theme.of(context).dividerColor.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Center(
            child: Icon(
              isNext ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
              color: isDisabled
                  ? Theme.of(context).disabledColor
                  : Theme.of(context).primaryColor,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
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
            style: GoogleFonts.outfit(
              color:
                  Theme.of(context).textTheme.bodyMedium?.color ??
                  AppColors.textSecondary,
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
              style: GoogleFonts.outfit(
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
              style: GoogleFonts.outfit(
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
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    'assets/images/illustrations/empty_profile.png',
                    height: 240,
                    width: 240,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.favorite_border_rounded,
                        size: 120,
                        color: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.5),
                      );
                    },
                  ),
                )
                .animate()
                .fadeIn(duration: 600.ms)
                .scale(begin: const Offset(0.8, 0.8)),
            const SizedBox(height: 40),
            Text(
              'You\'re all caught up!',
              style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color:
                    Theme.of(context).textTheme.bodyLarge?.color ??
                    AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
            const SizedBox(height: 16),
            Text(
              'We are looking for more compatible profiles.\nPlease check back in a bit for fresh recommendations.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color:
                    Theme.of(context).textTheme.bodyMedium?.color ??
                    AppColors.textSecondary,
                fontSize: 16,
                height: 1.5,
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
            const SizedBox(height: 48),
            SizedBox(
              width: 240,
              child: CustomButton(
                onPressed: () {
                  context.read<MatchProvider>().loadRecommendations().then(
                    (_) => syncWithProvider(),
                  );
                },
                text: 'Refresh Profiles',
                borderRadius: 100,
                height: 56,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Web Photo Gallery (Scrollable List)
// ─────────────────────────────────────────────────────────────────────────────

class _WebPhotoGallery extends StatefulWidget {
  final Map<String, dynamic> profileMap;
  final VoidCallback onPass;
  final VoidCallback onLike;
  final bool isLoading;

  const _WebPhotoGallery({
    required this.profileMap,
    required this.onPass,
    required this.onLike,
    required this.isLoading,
  });

  @override
  State<_WebPhotoGallery> createState() => _WebPhotoGalleryState();
}

class _WebPhotoGalleryState extends State<_WebPhotoGallery> {
  int _currentIndex = 0;

  @override
  void didUpdateWidget(covariant _WebPhotoGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profileMap['id'] != widget.profileMap['id']) {
      _currentIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = (widget.profileMap['images'] as List<dynamic>? ?? []);
    final isBlurred =
        images.isNotEmpty &&
        images.first is Map &&
        images.first['isBlurred'] == true;
    final isPrivate =
        widget.profileMap['viewerPrivacyEnabled'] == true || isBlurred;

    final displayImages = isPrivate
        ? (images.isNotEmpty ? [images.first] : [])
        : images;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Main Image Section (Takes up most space)
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Main Image
                displayImages.isNotEmpty
                    ? GestureDetector(
                        onTap: isPrivate
                            ? null
                            : () {
                                FullscreenImagePreview.show(
                                  context,
                                  images: displayImages,
                                  initialIndex: _currentIndex,
                                );
                              },
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: CachedAppImage.fromProfileImageMap(
                            key: ValueKey(
                              '${widget.profileMap['id']}_$_currentIndex',
                            ),
                            image: displayImages[_currentIndex],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            placeholder: (_, __) => _buildPlaceholder(),
                            errorWidget: (_, __, ___) =>
                                _buildPlaceholder(icon: LucideIcons.image_off),
                          ),
                        ),
                      )
                    : _buildPlaceholder(icon: LucideIcons.user, size: 84),

                // Bottom Gradient over the main image for buttons
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 200,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Privacy Overlay
                if (isPrivate)
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.lock,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.profileMap['viewerPrivacyEnabled'] == true
                                ? 'Private Profile'
                                : 'Private Photos',
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Request access to view ${widget.profileMap['name']}\'s photos.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _DiscoverRequestAccessButton(
                            userId: widget.profileMap['userId'] as int? ?? 0,
                            imageAccessRequestStatus:
                                widget.profileMap['imageAccessRequestStatus']
                                    as String?,
                          ),
                        ],
                      ),
                    ),
                  ),

                // Floating Actions at the bottom of the main image
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    ignoring: widget.isLoading,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _FloatingActionButton(
                          icon: Icons.heart_broken_rounded,
                          color: Theme.of(context).cardColor,
                          iconColor: Colors.black87,
                          size: 64,
                          iconSize: 32,
                          onTap: widget.isLoading ? null : widget.onPass,
                          hasShadow: true,
                        ),
                        const SizedBox(width: 24),
                        _FloatingActionButton(
                          icon: Icons.favorite_rounded,
                          color: Theme.of(context).primaryColor,
                          iconColor: Colors.white,
                          size: 64,
                          iconSize: 32,
                          onTap: widget.isLoading ? null : widget.onLike,
                          hasShadow: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom Thumbnail Row (Separate)
        if (displayImages.length > 1) ...[
          const SizedBox(height: 16),
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: displayImages.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final isSelected = _currentIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _currentIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 72,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: CachedAppImage.fromProfileImageMap(
                      image: displayImages[index],
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _buildPlaceholder(size: 20),
                      errorWidget: (_, __, ___) => _buildPlaceholder(
                        icon: LucideIcons.image_off,
                        size: 20,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPlaceholder({IconData? icon, double size = 48}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF1E1E2C) : Colors.grey.shade200,
      child: Center(
        child: Icon(
          icon ?? LucideIcons.image,
          color: isDark
              ? Colors.white.withValues(alpha: 0.3)
              : Colors.grey.shade400,
          size: size,
        ),
      ),
    );
  }
}

class _FloatingActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final bool hasShadow;

  const _FloatingActionButton({
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.onTap,
    this.size = 64,
    this.iconSize = 32,
    this.hasShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedOpacity(
          opacity: onTap == null ? 0.6 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: hasShadow
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : [],
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Center(
              child: Icon(icon, color: iconColor, size: iconSize),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Web Profile Details (Compact)
// ─────────────────────────────────────────────────────────────────────────────

class _WebProfileDetails extends StatelessWidget {
  final Map<String, dynamic> profileMap;
  final VoidCallback onReportPressed;
  final VoidCallback onBlockPressed;

  const _WebProfileDetails({
    required this.profileMap,
    required this.onReportPressed,
    required this.onBlockPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: 40,
        vertical: 8,
      ), // More compact padding
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 32),
          _buildContent(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final name = profileMap['name']?.toString() ?? 'Unknown';
    final age = profileMap['age']?.toString();
    final title = (age == null || age.isEmpty || age == '0')
        ? name
        : '$name, $age';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _MatchPill(percentage: profileMap['matchPercentage'] ?? 0),
            const SizedBox(width: 12),
            if (profileMap['lastLoginAt'] != null)
              _HeroMetaItem(
                icon: LucideIcons.circle,
                text: _formatLastLogin(profileMap['lastLoginAt'].toString()),
                iconColor: const Color(0xFF37C871),
                textColor:
                    Theme.of(context).textTheme.bodyMedium?.color ??
                    AppColors.textSecondary,
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 36, // Smaller font for compactness
                  fontWeight: FontWeight.w800,
                  color:
                      Theme.of(context).textTheme.bodyLarge?.color ??
                      AppColors.textPrimary,
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            if (profileMap['isVerified'] == true ||
                profileMap['isPremium'] == true ||
                profileMap['isFoundingMember'] == true) ...[
              const SizedBox(width: 12),
              VerifiedIconWidget(
                isVerified: profileMap['isVerified'] == true,
                isFoundingMember: profileMap['isFoundingMember'] == true,
                isPremium: profileMap['isPremium'] == true,
                size: 24,
              ),
            ],
            if (profileMap['isFoundingMember'] == true) ...[
              const SizedBox(width: 12),
              const FoundingMemberBadge(size: 24),
            ],
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 24,
          runSpacing: 8,
          children: [
            if (profileMap['city'] != null || profileMap['state'] != null)
              _HeroMetaItem(
                icon: LucideIcons.map_pin,
                text: [
                  profileMap['city'],
                  profileMap['state'],
                ].where((v) => v != null).join(', '),
                textColor:
                    Theme.of(context).textTheme.bodyMedium?.color ??
                    AppColors.textSecondary,
                iconColor: Theme.of(context).primaryColor,
              ),
            if (profileMap['maritalStatus'] != null)
              _HeroMetaItem(
                icon: LucideIcons.heart,
                text: _formatEnum(profileMap['maritalStatus'].toString()),
                textColor:
                    Theme.of(context).textTheme.bodyMedium?.color ??
                    AppColors.textSecondary,
                iconColor: Theme.of(context).primaryColor,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    final children = <Widget>[];

    if (_hasText(profileMap['bio'])) {
      children.add(_buildSectionTitle(context, 'About'));
      children.add(const SizedBox(height: 12));
      children.add(_buildAbout(context, profileMap['bio'].toString()));
      children.add(const SizedBox(height: 32));
    }

    final basics = _basicItems(profileMap);
    if (basics.isNotEmpty) {
      children.add(_buildSectionTitle(context, 'The Basics'));
      children.add(const SizedBox(height: 12));
      children.add(_WebInfoList(items: basics));
      children.add(const SizedBox(height: 32));
    }

    final career = _careerItems(profileMap);
    if (career.isNotEmpty) {
      children.add(_buildSectionTitle(context, 'Education & Career'));
      children.add(const SizedBox(height: 16));
      children.add(_WebCardGrid(items: career));
      children.add(const SizedBox(height: 32));
    }

    final lifestyle = _lifestyleItems(profileMap);
    if (lifestyle.isNotEmpty) {
      children.add(_buildSectionTitle(context, 'Lifestyle'));
      children.add(const SizedBox(height: 16));
      children.add(_WebCardGrid(items: lifestyle));
      children.add(const SizedBox(height: 32));
    }

    final languages = _languages(profileMap);
    if (languages.isNotEmpty) {
      children.add(_buildSectionTitle(context, 'Languages'));
      children.add(const SizedBox(height: 16));
      children.add(_LanguageChips(languages: languages));
      children.add(const SizedBox(height: 32));
    }

    final lookingFor = _lookingForText(profileMap);
    if (lookingFor != null) {
      children.add(_buildSectionTitle(context, 'Looking For'));
      children.add(const SizedBox(height: 16));
      children.add(_LookingForCard(text: lookingFor));
      children.add(const SizedBox(height: 48));
    }

    children.add(
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _ActionButton(
            text: 'Block User',
            icon: LucideIcons.ban,
            onTap: onBlockPressed,
            isDestructive: true,
          ),
          const SizedBox(width: 16),
          _ActionButton(
            text: 'Report User',
            icon: LucideIcons.flag,
            onTap: onReportPressed,
          ),
        ],
      ),
    );

    // Padding to scroll past the end
    children.add(const SizedBox(height: 48));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.outfit(
        color: Theme.of(context).primaryColor,
        fontSize: 13,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildAbout(BuildContext context, String bio) {
    return Text(
      bio,
      style: GoogleFonts.outfit(
        color:
            Theme.of(context).textTheme.bodyLarge?.color ??
            AppColors.textPrimary,
        fontSize: 15,
        height: 1.5,
        fontWeight: FontWeight.w400,
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
      if (profile['heightCm'] != null)
        _ProfileInfoItem(
          icon: LucideIcons.ruler,
          label: 'Height',
          value: _formatHeight(profile['heightCm']),
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

class _WebInfoList extends StatelessWidget {
  final List<_ProfileInfoItem> items;

  const _WebInfoList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(items.length, (index) {
        final item = items[index];
        final isLast = index == items.length - 1;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  Icon(
                    item.icon,
                    color: Theme.of(context).primaryColor,
                    size: 22,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    item.label,
                    style: GoogleFonts.outfit(
                      color:
                          Theme.of(context).textTheme.bodyMedium?.color ??
                          AppColors.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    item.value,
                    style: GoogleFonts.outfit(
                      color:
                          Theme.of(context).textTheme.bodyLarge?.color ??
                          AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (!isLast)
              Divider(
                height: 1,
                thickness: 1,
                color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
              ),
          ],
        );
      }),
    );
  }
}

class _WebCardGrid extends StatelessWidget {
  final List<_ProfileInfoItem> items;

  const _WebCardGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: items
          .map((item) => SizedBox(width: 180, child: _WebInfoCard(item: item)))
          .toList(),
    );
  }
}

class _WebInfoCard extends StatelessWidget {
  final _ProfileInfoItem item;

  const _WebInfoCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, color: Theme.of(context).primaryColor, size: 22),
          const SizedBox(height: 12),
          Text(
            item.label,
            style: GoogleFonts.outfit(
              color:
                  Theme.of(context).textTheme.bodyMedium?.color ??
                  AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.value,
            style: GoogleFonts.outfit(
              color:
                  Theme.of(context).textTheme.bodyLarge?.color ??
                  AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
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
              const SizedBox(width: 6),
              Text(
                language,
                style: GoogleFonts.outfit(
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.heart,
            color: Theme.of(context).primaryColor,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(
                color:
                    Theme.of(context).textTheme.bodyLarge?.color ??
                    AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
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

class _MatchPill extends StatelessWidget {
  final dynamic percentage;

  const _MatchPill({required this.percentage});

  @override
  Widget build(BuildContext context) {
    final pct = percentage is num
        ? percentage.round()
        : int.tryParse(percentage.toString()) ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.sparkles, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            '$pct% Match',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetaItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? iconColor;
  final Color? textColor;

  const _HeroMetaItem({
    required this.icon,
    required this.text,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: icon == LucideIcons.circle ? 8 : 18,
          color: iconColor ?? Colors.white,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.outfit(
            color: textColor ?? Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionButton({
    required this.text,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.red.shade600 : Colors.grey.shade700;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              text,
              style: GoogleFonts.outfit(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'Access Pending',
            style: GoogleFonts.outfit(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              fontSize: 15,
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
        height: 48,
        borderRadius: 12,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

String _formatEnum(String value) {
  return value
      .replaceAll('_', ' ')
      .toLowerCase()
      .split(' ')
      .map(
        (word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '',
      )
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
