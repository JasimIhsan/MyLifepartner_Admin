import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/core/app_routes.dart';
import 'package:life_partner_again/main.dart';
import 'package:life_partner_again/models/user_image.dart';
import 'package:life_partner_again/providers/auth_provider.dart';
import 'package:life_partner_again/providers/theme_provider.dart';
import 'package:life_partner_again/widgets/cached_app_image.dart';
import 'package:life_partner_again/widgets/founding_member_badge.dart';
import 'package:life_partner_again/widgets/verified_icon.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../widgets/bottomsheet/logout_bottom_sheet.dart';
import '../../../widgets/custom_button.dart';
import '../widgets/profile_controller.dart';

class MobileProfileScreen extends StatefulWidget {
  const MobileProfileScreen({super.key});

  @override
  State<MobileProfileScreen> createState() => _MobileProfileScreenState();
}

class _MobileProfileScreenState extends State<MobileProfileScreen>
    with RouteAware, ProfileControllerState<MobileProfileScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    subscribeToRoute(routeObserver);
  }

  @override
  void dispose() {
    unsubscribeFromRoute(routeObserver);
    super.dispose();
  }

  Widget _buildSkeleton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 12.0,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                              width: 2,
                            ),
                            color: Theme.of(
                              context,
                            ).disabledColor.withValues(alpha: 0.1),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          width: 140,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).disabledColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 200,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).disabledColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 40),
                        _skeletonSection(),
                        _skeletonSection(),
                        _skeletonSection(),
                        _skeletonSection(),
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                            ),
                            color: Theme.of(
                              context,
                            ).disabledColor.withValues(alpha: 0.05),
                          ),
                        ),
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _skeletonSection() {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 100,
            height: 12,
            margin: const EdgeInsets.only(bottom: 8, left: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 1.2,
            ),
          ),
          child: Column(
            children: List.generate(2, (index) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).disabledColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            height: 14,
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).disabledColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).disabledColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (index == 0)
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: 56,
                      color: Theme.of(context).dividerColor,
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  void _openProfileImageGallery(UserImage tappedImage) {
    final images = profileImages.isNotEmpty ? profileImages : [tappedImage];
    final tappedIndex = images.indexWhere(
      (image) => image.imageId == tappedImage.imageId,
    );

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => _ProfileImagePreviewGallery(
          images: images,
          initialIndex: tappedIndex == -1 ? 0 : tappedIndex,
        ),
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || user == null) {
      return _buildSkeleton();
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                    width: 2,
                  ),
                  color: Theme.of(context).colorScheme.surface,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    primaryImage != null
                        ? GestureDetector(
                            onTap: () =>
                                _openProfileImageGallery(primaryImage!),
                            child: ClipOval(
                              child: CachedAppImage(
                                width: 140,
                                height: 140,
                                imageId: primaryImage!.imageId,
                                presignedImageUrl:
                                    primaryImage!.presignedImageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    CircularProgressIndicator(
                                      color: Theme.of(context).primaryColor,
                                    ),
                                errorWidget: (context, url, error) => Icon(
                                  Icons.person,
                                  size: 50,
                                  color:
                                      Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color ??
                                      Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color ??
                                      AppColors.textSecondary,
                                ),
                              ),
                            ),
                          )
                        : Icon(
                            Icons.person,
                            size: 70,
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color ??
                                Theme.of(context).textTheme.bodyMedium?.color ??
                                AppColors.textSecondary,
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      user!.name ?? "Your Name",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        color:
                            Theme.of(context).textTheme.bodyLarge?.color ??
                            Theme.of(context).textTheme.bodyLarge?.color ??
                            AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (user!.isVerified ||
                      user!.isPremium ||
                      user!.isFoundingMember) ...[
                    const SizedBox(width: 6),
                    VerifiedIconWidget(
                      isVerified: user!.isVerified,
                      isFoundingMember: user!.isFoundingMember,
                      isPremium: user!.isPremium,
                      size: 22,
                    ),
                  ],
                  if (user!.isFoundingMember) ...[
                    const SizedBox(width: 6),
                    const FoundingMemberBadge(size: 22),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user!.email ?? "your.email@example.com",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color:
                    Theme.of(context).textTheme.bodyMedium?.color ??
                    Theme.of(context).textTheme.bodyMedium?.color ??
                    AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 40),

            _buildSectionHeader("Account"),
            _buildActionGroup([
              _buildActionItem(
                icon: Icons.person_outline,
                title: "Edit Profile Info",
                onTap: () async {
                  if (user != null) {
                    final result = await context.push(
                      AppRoutes.editProfile,
                      extra: user,
                    );
                    if (result == true) {
                      fetchProfileData();
                    }
                  }
                },
              ),
              _buildActionItem(
                icon: Icons.tune_rounded,
                title: "Edit Partner Preferences",
                onTap: () async {
                  final result = await context.push(
                    AppRoutes.editPartnerPreference,
                  );
                  if (result == true) {
                    fetchProfileData();
                  }
                },
              ),
              _buildActionItem(
                icon: Icons.photo_library_outlined,
                title: "Manage Profile Pictures",
                showDivider: false,
                onTap: () async {
                  final result = await context.push(
                    AppRoutes.manageProfilePictures,
                  );
                  if (result == true) {
                    fetchProfileData();
                  }
                },
              ),
            ]),

            _buildSectionHeader("Subscription"),
            _buildActionGroup([
              _buildActionItem(
                icon: Icons.star_outline,
                title: "My Subscription",
                showDivider: false,
                onTap: () {
                  context.push(AppRoutes.subscription);
                },
              ),
            ]),
            _buildSectionHeader("Privacy & Security"),
            _buildActionGroup([
              _buildSwitchItem(
                icon: Icons.shield_outlined,
                title: "Private Account",
                subtitle: "Only approved matches can see your photos",
                value: user?.privacyEnabled ?? false,
                isItemLoading: isUpdatingPrivacy,
                onChanged: (value) => togglePrivacy(value),
                showDivider: true,
              ),
              _buildActionItem(
                icon: Icons.lock_open_outlined,
                title: "Image Access Requests",
                showDivider: true,
                onTap: () {
                  context.push(AppRoutes.imageAccessRequests);
                },
              ),
              _buildActionItem(
                icon: Icons.block,
                title: "Blocked Users",
                showDivider: false,
                onTap: () {
                  context.push(AppRoutes.blockedUsers);
                },
              ),
            ]),

            _buildSectionHeader("Appearance"),
            _buildActionGroup([
              _buildSwitchItem(
                icon: Icons.dark_mode_outlined,
                title: "Dark Mode",
                subtitle: "Toggle dark theme for the app",
                value: context.watch<ThemeProvider>().isDarkMode,
                isItemLoading: false,
                onChanged: (value) =>
                    context.read<ThemeProvider>().toggleTheme(value),
                showDivider: false,
              ),
            ]),

            _buildSectionHeader("Support"),
            _buildActionGroup([
              _buildActionItem(
                icon: Icons.help_outline,
                title: "Help & Support",
                showDivider: false,
                onTap: () {
                  context.push(AppRoutes.support);
                },
              ),
            ]),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                onPressed: () {
                  LogoutBottomSheet.show(
                    context: context,
                    onLogoutConfirm: () async {
                      final sharedPrefs = await SharedPreferences.getInstance();
                      await sharedPrefs.clear();
                      if (context.mounted) {
                        await context.read<AuthProvider>().logout();
                      }
                    },
                  );
                },
                text: "Logout",
                type: CustomButtonType.outline,
                textColor: Theme.of(context).primaryColor,
                height: 56,
                borderRadius: 16,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
            color:
                Theme.of(context).textTheme.bodyMedium?.color ??
                Theme.of(context).textTheme.bodyMedium?.color ??
                AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildActionGroup(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1.2),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor, size: 22),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color:
                          Theme.of(context).textTheme.bodyLarge?.color ??
                          Theme.of(context).textTheme.bodyLarge?.color ??
                          AppColors.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color:
                      Theme.of(context).textTheme.bodyMedium?.color ??
                      Theme.of(context).textTheme.bodyMedium?.color ??
                      AppColors.textSecondary.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: 56,
            color: Theme.of(context).dividerColor,
          ),
      ],
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required bool isItemLoading,
    required ValueChanged<bool> onChanged,
    bool showDivider = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).primaryColor, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color:
                            Theme.of(context).textTheme.bodyLarge?.color ??
                            Theme.of(context).textTheme.bodyLarge?.color ??
                            AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            Theme.of(context).textTheme.bodyMedium?.color ??
                            Theme.of(context).textTheme.bodyMedium?.color ??
                            AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isItemLoading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Switch(
                  value: value,
                  onChanged: onChanged,
                  activeTrackColor: Theme.of(
                    context,
                  ).primaryColor.withValues(alpha: 0.5),
                  activeThumbColor: Theme.of(context).primaryColor,
                ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: 56,
            color: Theme.of(context).dividerColor,
          ),
      ],
    );
  }
}

class _ProfileImagePreviewGallery extends StatefulWidget {
  final List<UserImage> images;
  final int initialIndex;

  const _ProfileImagePreviewGallery({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_ProfileImagePreviewGallery> createState() =>
      _ProfileImagePreviewGalleryState();
}

class _ProfileImagePreviewGalleryState
    extends State<_ProfileImagePreviewGallery> {
  static const double _thumbnailSize = 54;
  static const double _thumbnailGap = 8;

  late final PageController _pageController;
  late final ScrollController _thumbnailScrollController;
  late int _currentIndex;
  bool _isCurrentImageZoomed = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.images.isEmpty
        ? 0
        : widget.initialIndex.clamp(0, widget.images.length - 1).toInt();
    _pageController = PageController(initialPage: _currentIndex);
    _thumbnailScrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerSelectedThumbnail();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _thumbnailScrollController.dispose();
    super.dispose();
  }

  void _handlePageChanged(int index) {
    setState(() {
      _currentIndex = index;
      _isCurrentImageZoomed = false;
    });
    _centerSelectedThumbnail();
  }

  void _handleZoomChanged(int index, bool isZoomed) {
    if (index != _currentIndex || _isCurrentImageZoomed == isZoomed) return;

    setState(() {
      _isCurrentImageZoomed = isZoomed;
    });
  }

  void _goToImage(int index) {
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
      _isCurrentImageZoomed = false;
    });
    _pageController.jumpToPage(index);
    _centerSelectedThumbnail();
  }

  void _centerSelectedThumbnail() {
    if (!mounted || !_thumbnailScrollController.hasClients) return;

    final position = _thumbnailScrollController.position;
    final itemExtent = _thumbnailSize + _thumbnailGap;
    final targetOffset =
        (_currentIndex * itemExtent) -
        ((position.viewportDimension - _thumbnailSize) / 2);
    final clampedOffset = targetOffset.clamp(0.0, position.maxScrollExtent);

    _thumbnailScrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;

    if (images.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded, color: Colors.white),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: PageView.builder(
              controller: _pageController,
              physics: _isCurrentImageZoomed
                  ? const NeverScrollableScrollPhysics()
                  : const PageScrollPhysics(),
              itemCount: images.length,
              onPageChanged: _handlePageChanged,
              itemBuilder: (context, index) {
                return _ZoomableProfileImage(
                  key: ValueKey(images[index].imageId),
                  image: images[index],
                  isActive: index == _currentIndex,
                  onZoomChanged: (isZoomed) =>
                      _handleZoomChanged(index, isZoomed),
                );
              },
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_currentIndex + 1} / ${images.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.82),
                    Colors.black.withValues(alpha: 0.0),
                  ],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 18, 12, 12),
                  child: SizedBox(
                    height: _thumbnailSize,
                    child: ListView.separated(
                      controller: _thumbnailScrollController,
                      scrollDirection: Axis.horizontal,
                      itemCount: images.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: _thumbnailGap),
                      itemBuilder: (context, index) {
                        return _ProfileImageThumbnail(
                          image: images[index],
                          isSelected: index == _currentIndex,
                          onTap: () => _goToImage(index),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoomableProfileImage extends StatefulWidget {
  final UserImage image;
  final bool isActive;
  final ValueChanged<bool> onZoomChanged;

  const _ZoomableProfileImage({
    super.key,
    required this.image,
    required this.isActive,
    required this.onZoomChanged,
  });

  @override
  State<_ZoomableProfileImage> createState() => _ZoomableProfileImageState();
}

class _ZoomableProfileImageState extends State<_ZoomableProfileImage>
    with SingleTickerProviderStateMixin {
  static const double _doubleTapScale = 2.5;
  static const double _minScale = 1.0;
  static const double _maxScale = 4.0;
  static const double _extraPanBoundary = 80;

  late final AnimationController _animationController;
  Animation<double>? _scaleAnimation;
  Animation<Offset>? _offsetAnimation;
  final Map<int, Offset> _pointers = {};
  Offset _doubleTapPosition = Offset.zero;
  Offset _offset = Offset.zero;
  Offset _gestureStartFocal = Offset.zero;
  Offset _gestureStartOffset = Offset.zero;
  Offset? _lastPanPosition;
  Size _viewportSize = Size.zero;
  double _scale = _minScale;
  double _gestureStartDistance = 1;
  double _gestureStartScale = _minScale;
  bool _hasNotifiedGestureLock = false;
  bool _isPinching = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(_handleZoomAnimation);
  }

  @override
  void didUpdateWidget(covariant _ZoomableProfileImage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.image.imageId != widget.image.imageId) {
      _resetZoom(notify: false);
      return;
    }

    if (oldWidget.isActive && !widget.isActive) {
      _resetZoom(notify: false);
    }
  }

  @override
  void dispose() {
    _animationController
      ..removeListener(_handleZoomAnimation)
      ..dispose();
    super.dispose();
  }

  void _handleZoomAnimation() {
    final scaleAnimation = _scaleAnimation;
    final offsetAnimation = _offsetAnimation;
    if (scaleAnimation == null || offsetAnimation == null) return;

    setState(() {
      _scale = scaleAnimation.value;
      _offset = _clampOffset(offsetAnimation.value, _scale);
    });
    _syncGestureLock();
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapPosition = details.localPosition;
  }

  void _handleDoubleTap() {
    if (_scale > 1.01) {
      _animateTo(scale: _minScale, offset: Offset.zero);
      return;
    }

    final center = _viewportSize.center(Offset.zero);
    final targetOffset = _clampOffset(
      (center - _doubleTapPosition) * (_doubleTapScale - 1),
      _doubleTapScale,
    );
    _animateTo(scale: _doubleTapScale, offset: targetOffset);
  }

  void _animateTo({required double scale, required Offset offset}) {
    _animationController.stop();
    _scaleAnimation = Tween<double>(begin: _scale, end: scale).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _offsetAnimation = Tween<Offset>(begin: _offset, end: offset).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward(from: 0);
  }

  void _resetZoom({required bool notify}) {
    _animationController.stop();
    _pointers.clear();
    _lastPanPosition = null;
    _isPinching = false;
    _scale = _minScale;
    _offset = Offset.zero;
    if (!notify) {
      _hasNotifiedGestureLock = false;
      return;
    }

    _syncGestureLock();
  }

  void _handlePointerDown(PointerDownEvent event) {
    _animationController.stop();
    _pointers[event.pointer] = event.localPosition;

    if (_pointers.length == 1) {
      _lastPanPosition = event.localPosition;
    } else {
      _startPinch();
      _syncGestureLock(forceLock: true);
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (!_pointers.containsKey(event.pointer)) return;

    _pointers[event.pointer] = event.localPosition;

    if (_pointers.length >= 2) {
      if (!_isPinching) {
        _startPinch();
      }
      _updatePinch();
      return;
    }

    if (_scale <= 1.01) return;

    final previousPosition = _lastPanPosition ?? event.localPosition;
    final delta = event.localPosition - previousPosition;
    _lastPanPosition = event.localPosition;

    setState(() {
      _offset = _clampOffset(_offset + delta, _scale);
    });
  }

  void _handlePointerUp(PointerEvent event) {
    _pointers.remove(event.pointer);

    if (_pointers.length >= 2) {
      _startPinch();
      return;
    }

    _isPinching = false;
    _lastPanPosition = _pointers.values.firstOrNull;

    if (_scale <= 1.01) {
      _animateTo(scale: _minScale, offset: Offset.zero);
    }
    _syncGestureLock();
  }

  void _startPinch() {
    final points = _pointers.values.take(2).toList();
    if (points.length < 2) return;

    _isPinching = true;
    _gestureStartFocal = (points[0] + points[1]) / 2;
    _gestureStartDistance = (points[0] - points[1]).distance;
    _gestureStartOffset = _offset;
    _gestureStartScale = _scale;
  }

  void _updatePinch() {
    final points = _pointers.values.take(2).toList();
    if (points.length < 2 || _gestureStartDistance == 0) return;

    final focal = (points[0] + points[1]) / 2;
    final distance = (points[0] - points[1]).distance;
    final nextScale = (_gestureStartScale * distance / _gestureStartDistance)
        .clamp(_minScale, _maxScale)
        .toDouble();
    final center = _viewportSize.center(Offset.zero);
    final scaleRatio = nextScale / _gestureStartScale;
    final nextOffset =
        focal -
        center -
        ((_gestureStartFocal - center - _gestureStartOffset) * scaleRatio);

    setState(() {
      _scale = nextScale;
      _offset = _clampOffset(nextOffset, nextScale);
    });
    _syncGestureLock();
  }

  Offset _clampOffset(Offset offset, double scale) {
    if (scale <= 1.01 || _viewportSize == Size.zero) return Offset.zero;

    final maxX = (_viewportSize.width * (scale - 1) / 2) + _extraPanBoundary;
    final maxY = (_viewportSize.height * (scale - 1) / 2) + _extraPanBoundary;

    return Offset(
      offset.dx.clamp(-maxX, maxX).toDouble(),
      offset.dy.clamp(-maxY, maxY).toDouble(),
    );
  }

  void _syncGestureLock({bool forceLock = false}) {
    final shouldLock = forceLock || _scale > 1.01 || _pointers.length >= 2;
    if (shouldLock == _hasNotifiedGestureLock) return;

    _hasNotifiedGestureLock = shouldLock;
    widget.onZoomChanged(shouldLock);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewportSize = Size(constraints.maxWidth, constraints.maxHeight);

        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _handlePointerDown,
          onPointerMove: _handlePointerMove,
          onPointerUp: _handlePointerUp,
          onPointerCancel: _handlePointerUp,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onDoubleTapDown: _handleDoubleTapDown,
            onDoubleTap: _handleDoubleTap,
            child: ClipRect(
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..translateByDouble(_offset.dx, _offset.dy, 0, 1)
                  ..scaleByDouble(_scale, _scale, 1, 1),
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: CachedAppImage(
                    imageId: widget.image.imageId,
                    presignedImageUrl: widget.image.presignedImageUrl,
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    fit: BoxFit.contain,
                    placeholder: (_, __) => const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white70,
                        size: 44,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProfileImageThumbnail extends StatelessWidget {
  final UserImage image;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProfileImageThumbnail({
    required this.image,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: _ProfileImagePreviewGalleryState._thumbnailSize,
        height: _ProfileImagePreviewGalleryState._thumbnailSize,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.18),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: AnimatedOpacity(
            opacity: isSelected ? 1 : 0.66,
            duration: const Duration(milliseconds: 180),
            child: CachedAppImage(
              imageId: image.imageId,
              presignedImageUrl: image.presignedImageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: Colors.white.withValues(alpha: 0.08),
                child: const Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
              errorWidget: (_, __, ___) => Container(
                color: Colors.white.withValues(alpha: 0.08),
                child: const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
