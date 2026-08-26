import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/core/app_routes.dart';
import 'package:life_partner_again/main.dart';
import 'package:life_partner_again/models/user_image.dart';
import 'package:life_partner_again/providers/auth_provider.dart';
import 'package:life_partner_again/providers/theme_provider.dart';
import 'package:life_partner_again/widgets/cached_app_image.dart';
import 'package:life_partner_again/widgets/custom_button.dart';
import 'package:life_partner_again/widgets/founding_member_badge.dart';
import 'package:life_partner_again/widgets/verified_icon.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/profile_controller.dart';
import 'widgets/web_profile_image_lightbox.dart';

// ─── Tab Model ───────────────────────────────────────────────────────────────

enum _ProfileTab {
  account,
  subscription,
  privacy,
  appearance,
  support;

  String get label {
    switch (this) {
      case _ProfileTab.account:
        return 'Account';
      case _ProfileTab.subscription:
        return 'Subscription';
      case _ProfileTab.privacy:
        return 'Privacy & Security';
      case _ProfileTab.appearance:
        return 'Appearance';
      case _ProfileTab.support:
        return 'Support';
    }
  }

  IconData get icon {
    switch (this) {
      case _ProfileTab.account:
        return Icons.person_outline_rounded;
      case _ProfileTab.subscription:
        return Icons.star_outline_rounded;
      case _ProfileTab.privacy:
        return Icons.shield_outlined;
      case _ProfileTab.appearance:
        return Icons.palette_outlined;
      case _ProfileTab.support:
        return Icons.help_outline_rounded;
    }
  }
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class WebProfileScreen extends StatefulWidget {
  const WebProfileScreen({super.key});

  @override
  State<WebProfileScreen> createState() => _WebProfileScreenState();
}

class _WebProfileScreenState extends State<WebProfileScreen>
    with RouteAware, ProfileControllerState<WebProfileScreen> {
  _ProfileTab _activeTab = _ProfileTab.account;

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

  // ── Lightbox ─────────────────────────────────────────────────────────────

  void _openWebLightbox(UserImage tappedImage) {
    final images = profileImages.isNotEmpty ? profileImages : [tappedImage];
    final tappedIndex = images.indexWhere(
      (image) => image.imageId == tappedImage.imageId,
    );

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return WebProfileImageLightbox(
          images: images,
          initialIndex: tappedIndex == -1 ? 0 : tappedIndex,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  // ── Privacy toggle ────────────────────────────────────────────────────────

  void _handleWebPrivacyToggle(bool newValue) {
    if (isUpdatingPrivacy) return;

    final isEnabling = newValue;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isEnabling ? 'Enable Privacy?' : 'Disable Privacy?',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          isEnabling
              ? 'Your profile photos will be blurred for everyone except matches you approve.'
              : 'Your profile photos will be visible to everyone on the platform.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              setState(() => isUpdatingPrivacy = true);
              try {
                await profileRepository.updatePrivacySettings(newValue);
                await fetchProfileData();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll('Exception: ', '')),
                    ),
                  );
                }
              } finally {
                if (mounted) setState(() => isUpdatingPrivacy = false);
              }
            },
            child: Text(isEnabling ? 'Enable' : 'Disable'),
          ),
        ],
      ),
    );
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  void _handleWebLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Logout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to log out of your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final sharedPrefs = await SharedPreferences.getInstance();
              await sharedPrefs.clear();
              if (mounted) {
                await context.read<AuthProvider>().logout();
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (isLoading || user == null) {
      return _WebProfileSkeleton();
    }

    final isWide = MediaQuery.of(context).size.width >= 960;

    return Scaffold(
      backgroundColor: Theme.of(context).canvasColor,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 40 : 20,
                vertical: 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Hero Banner ──────────────────────────────────────────
                  _HeroBanner(
                    user: user!,
                    primaryImage: primaryImage,
                    profileImages: profileImages,
                    isWide: isWide,
                    onAvatarTap: () {
                      if (primaryImage != null || profileImages.isNotEmpty) {
                        _openWebLightbox(
                          primaryImage ?? profileImages.first,
                        );
                      }
                    },
                    onEditProfile: () async {
                      final result = await context.push(
                        AppRoutes.editProfile,
                        extra: user,
                      );
                      if (result == true) fetchProfileData();
                    },
                    onLogout: _handleWebLogout,
                  ).animate().fadeIn(duration: 350.ms).slideY(
                        begin: -0.06,
                        curve: Curves.easeOutCubic,
                      ),

                  const SizedBox(height: 28),

                  // ── Tab Bar ──────────────────────────────────────────────
                  _ProfileTabBar(
                    activeTab: _activeTab,
                    isWide: isWide,
                    onTabChanged: (tab) => setState(() => _activeTab = tab),
                  ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

                  const SizedBox(height: 24),

                  // ── Tab Content Panel ─────────────────────────────────────
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.04),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                          child: child,
                        ),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey(_activeTab),
                      child: _buildTabContent(),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB CONTENT
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildTabContent() {
    switch (_activeTab) {
      case _ProfileTab.account:
        return _buildAccountTab();
      case _ProfileTab.subscription:
        return _buildSubscriptionTab();
      case _ProfileTab.privacy:
        return _buildPrivacyTab();
      case _ProfileTab.appearance:
        return _buildAppearanceTab();
      case _ProfileTab.support:
        return _buildSupportTab();
    }
  }

  Widget _buildAccountTab() {
    return _SettingsCard(
      children: [
        _WebActionItem(
          icon: Icons.person_outline_rounded,
          title: 'Edit Profile Info',
          subtitle: 'Update your personal details, bio and more',
          onTap: () async {
            if (user != null) {
              final result = await context.push(
                AppRoutes.editProfile,
                extra: user,
              );
              if (result == true) fetchProfileData();
            }
          },
        ),
        _itemDivider(),
        _WebActionItem(
          icon: Icons.tune_rounded,
          title: 'Edit Partner Preferences',
          subtitle: 'Adjust age range, status, and language filters',
          onTap: () async {
            final result = await context.push(
              AppRoutes.editPartnerPreference,
            );
            if (result == true) fetchProfileData();
          },
        ),
        _itemDivider(),
        _WebActionItem(
          icon: Icons.photo_library_outlined,
          title: 'Manage Profile Pictures',
          subtitle: 'Add, reorder or remove photos from your gallery',
          onTap: () async {
            final result = await context.push(
              AppRoutes.manageProfilePictures,
            );
            if (result == true) fetchProfileData();
          },
          showDivider: false,
        ),
      ],
    );
  }

  Widget _buildSubscriptionTab() {
    return _SettingsCard(
      children: [
        _WebActionItem(
          icon: Icons.star_outline_rounded,
          title: 'My Subscription',
          subtitle: 'View and manage your current premium plan',
          onTap: () => context.push(AppRoutes.subscription),
          showDivider: false,
        ),
      ],
    );
  }

  Widget _buildPrivacyTab() {
    return _SettingsCard(
      children: [
        _WebSwitchItem(
          icon: Icons.shield_outlined,
          title: 'Private Account',
          subtitle: 'Only approved matches can see your photos',
          value: user?.privacyEnabled ?? false,
          isItemLoading: isUpdatingPrivacy,
          onChanged: _handleWebPrivacyToggle,
        ),
        _itemDivider(),
        _WebActionItem(
          icon: Icons.lock_open_outlined,
          title: 'Image Access Requests',
          subtitle: 'Manage who can view your private photos',
          onTap: () => context.push(AppRoutes.imageAccessRequests),
        ),
        _itemDivider(),
        _WebActionItem(
          icon: Icons.block_rounded,
          title: 'Blocked Users',
          subtitle: 'Manage profiles you have blocked',
          onTap: () => context.push(AppRoutes.blockedUsers),
          showDivider: false,
        ),
      ],
    );
  }

  Widget _buildAppearanceTab() {
    return _SettingsCard(
      children: [
        _WebSwitchItem(
          icon: Icons.dark_mode_outlined,
          title: 'Dark Mode',
          subtitle: 'Toggle dark theme across the entire app',
          value: context.watch<ThemeProvider>().isDarkMode,
          isItemLoading: false,
          onChanged: (value) =>
              context.read<ThemeProvider>().toggleTheme(value),
          showDivider: false,
        ),
      ],
    );
  }

  Widget _buildSupportTab() {
    return _SettingsCard(
      children: [
        _WebActionItem(
          icon: Icons.help_outline_rounded,
          title: 'Help & Support',
          subtitle: 'Get assistance, FAQs, and contact support',
          onTap: () => context.push(AppRoutes.support),
          showDivider: false,
        ),
      ],
    );
  }

  Widget _itemDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 76,
      endIndent: 24,
      color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO BANNER
// ─────────────────────────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  final dynamic user;
  final UserImage? primaryImage;
  final List<UserImage> profileImages;
  final bool isWide;
  final VoidCallback onAvatarTap;
  final VoidCallback onEditProfile;
  final VoidCallback onLogout;

  const _HeroBanner({
    required this.user,
    required this.primaryImage,
    required this.profileImages,
    required this.isWide,
    required this.onAvatarTap,
    required this.onEditProfile,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final textPrimary =
        theme.textTheme.bodyLarge?.color ?? AppColors.textPrimary;
    final textSecondary =
        theme.textTheme.bodyMedium?.color ?? AppColors.textSecondary;

    final hasLocation = user.city != null && user.state != null;
    final hasBadge =
        (user.isVerified == true) ||
        (user.isPremium == true) ||
        (user.isFoundingMember == true);

    Widget content;

    if (isWide) {
      content = Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _AvatarStack(
            primaryImage: primaryImage,
            profileImages: profileImages,
            onTap: onAvatarTap,
            primaryColor: primaryColor,
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.name ?? 'Your Name',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hasBadge) ...[
                      const SizedBox(width: 8),
                      VerifiedIconWidget(
                        isVerified: user.isVerified ?? false,
                        isFoundingMember: user.isFoundingMember ?? false,
                        isPremium: user.isPremium ?? false,
                        size: 22,
                      ),
                    ],
                    if (user.isFoundingMember == true) ...[
                      const SizedBox(width: 6),
                      const FoundingMemberBadge(size: 22),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(
                      icon: Icons.mail_outline_rounded,
                      label: user.email ?? 'your.email@example.com',
                      color: primaryColor,
                    ),
                    if (hasLocation)
                      _InfoChip(
                        icon: Icons.location_on_outlined,
                        label: '${user.city}, ${user.state}',
                        color: textSecondary,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                width: 180,
                child: CustomButton(
                  onPressed: onEditProfile,
                  text: 'Edit Profile',
                  type: CustomButtonType.primary,
                  height: 46,
                  borderRadius: 12,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 180,
                child: CustomButton(
                  onPressed: onLogout,
                  text: 'Logout',
                  type: CustomButtonType.outline,
                  textColor: Colors.red,
                  height: 46,
                  borderRadius: 12,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      content = Column(
        children: [
          _AvatarStack(
            primaryImage: primaryImage,
            profileImages: profileImages,
            onTap: onAvatarTap,
            primaryColor: primaryColor,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  user.name ?? 'Your Name',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasBadge) ...[
                const SizedBox(width: 8),
                VerifiedIconWidget(
                  isVerified: user.isVerified ?? false,
                  isFoundingMember: user.isFoundingMember ?? false,
                  isPremium: user.isPremium ?? false,
                  size: 20,
                ),
              ],
              if (user.isFoundingMember == true) ...[
                const SizedBox(width: 6),
                const FoundingMemberBadge(size: 20),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _InfoChip(
                icon: Icons.mail_outline_rounded,
                label: user.email ?? 'your.email@example.com',
                color: primaryColor,
              ),
              if (hasLocation)
                _InfoChip(
                  icon: Icons.location_on_outlined,
                  label: '${user.city}, ${user.state}',
                  color: textSecondary,
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  onPressed: onEditProfile,
                  text: 'Edit Profile',
                  type: CustomButtonType.primary,
                  height: 46,
                  borderRadius: 12,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  onPressed: onLogout,
                  text: 'Logout',
                  type: CustomButtonType.outline,
                  textColor: Colors.red,
                  height: 46,
                  borderRadius: 12,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Container(
      padding: EdgeInsets.all(isWide ? 28 : 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: content,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AVATAR STACK
// ─────────────────────────────────────────────────────────────────────────────

class _AvatarStack extends StatelessWidget {
  final UserImage? primaryImage;
  final List<UserImage> profileImages;
  final VoidCallback onTap;
  final Color primaryColor;

  const _AvatarStack({
    required this.primaryImage,
    required this.profileImages,
    required this.onTap,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasImages = primaryImage != null || profileImages.isNotEmpty;

    return MouseRegion(
      cursor: hasImages ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: hasImages ? onTap : null,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 116,
              height: 116,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.25),
                  width: 3,
                ),
              ),
              padding: const EdgeInsets.all(3),
              child: ClipOval(
                child: primaryImage != null
                    ? CachedAppImage(
                        imageId: primaryImage!.imageId,
                        presignedImageUrl: primaryImage!.presignedImageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Center(
                          child: CircularProgressIndicator(
                            color: primaryColor,
                            strokeWidth: 2,
                          ),
                        ),
                        errorWidget: (_, __, ___) => Icon(
                          Icons.person,
                          size: 52,
                          color:
                              Theme.of(context).textTheme.bodyMedium?.color ??
                              AppColors.textSecondary,
                        ),
                      )
                    : Icon(
                        Icons.person,
                        size: 52,
                        color:
                            Theme.of(context).textTheme.bodyMedium?.color ??
                            AppColors.textSecondary,
                      ),
              ),
            ),
            if (profileImages.length > 1)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.photo_library,
                        color: Colors.white,
                        size: 11,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${profileImages.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INFO CHIP
// ─────────────────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB BAR
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileTabBar extends StatelessWidget {
  final _ProfileTab activeTab;
  final bool isWide;
  final ValueChanged<_ProfileTab> onTabChanged;

  const _ProfileTabBar({
    required this.activeTab,
    required this.isWide,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          children: _ProfileTab.values.map((tab) {
            return _ProfileTabItem(
              tab: tab,
              isActive: tab == activeTab,
              isWide: isWide,
              onTap: () => onTabChanged(tab),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ProfileTabItem extends StatefulWidget {
  final _ProfileTab tab;
  final bool isActive;
  final bool isWide;
  final VoidCallback onTap;

  const _ProfileTabItem({
    required this.tab,
    required this.isActive,
    required this.isWide,
    required this.onTap,
  });

  @override
  State<_ProfileTabItem> createState() => _ProfileTabItemState();
}

class _ProfileTabItemState extends State<_ProfileTabItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final isActive = widget.isActive;

    final fgColor = isActive
        ? primaryColor
        : _isHovered
            ? primaryColor.withValues(alpha: 0.75)
            : theme.textTheme.bodyMedium?.color ?? AppColors.textSecondary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          padding: EdgeInsets.symmetric(
            horizontal: widget.isWide ? 18 : 14,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: isActive
                ? primaryColor.withValues(alpha: 0.1)
                : _isHovered
                    ? primaryColor.withValues(alpha: 0.04)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.tab.icon, size: 16, color: fgColor),
              const SizedBox(width: 6),
              Text(
                widget.tab.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: fgColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SETTINGS CARD CONTAINER
// ─────────────────────────────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTION ITEM
// ─────────────────────────────────────────────────────────────────────────────

class _WebActionItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showDivider;

  const _WebActionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  State<_WebActionItem> createState() => _WebActionItemState();
}

class _WebActionItemState extends State<_WebActionItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              color: _isHovered
                  ? primaryColor.withValues(alpha: 0.04)
                  : Colors.transparent,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 20,
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _isHovered
                          ? primaryColor.withValues(alpha: 0.15)
                          : primaryColor.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.icon, color: primaryColor, size: 22),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.bodyLarge?.color ??
                                AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.textTheme.bodyMedium?.color ??
                                AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    transform: Matrix4.translationValues(
                      _isHovered ? 3 : 0,
                      0,
                      0,
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 15,
                      color: (theme.textTheme.bodyMedium?.color ??
                              AppColors.textSecondary)
                          .withValues(alpha: _isHovered ? 0.7 : 0.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: 76,
            endIndent: 24,
            color: theme.dividerColor.withValues(alpha: 0.5),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SWITCH ITEM
// ─────────────────────────────────────────────────────────────────────────────

class _WebSwitchItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final bool isItemLoading;
  final ValueChanged<bool> onChanged;
  final bool showDivider;

  const _WebSwitchItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.isItemLoading,
    required this.onChanged,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: primaryColor, size: 22),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyLarge?.color ??
                            AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.textTheme.bodyMedium?.color ??
                            AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isItemLoading)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: primaryColor,
                  ),
                )
              else
                Switch(
                  value: value,
                  onChanged: onChanged,
                  activeTrackColor: primaryColor.withValues(alpha: 0.3),
                  activeThumbColor: primaryColor,
                ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: 76,
            endIndent: 24,
            color: theme.dividerColor.withValues(alpha: 0.5),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SKELETON
// ─────────────────────────────────────────────────────────────────────────────

class _WebProfileSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shimmerBase = theme.dividerColor.withValues(alpha: 0.12);

    return Scaffold(
      backgroundColor: theme.canvasColor,
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 40,
                vertical: 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero skeleton
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        _SkeletonBox(
                          width: 116,
                          height: 116,
                          color: shimmerBase,
                          radius: 58,
                        ),
                        const SizedBox(width: 32),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SkeletonBox(
                                width: 200,
                                height: 24,
                                color: shimmerBase,
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  _SkeletonBox(
                                    width: 150,
                                    height: 28,
                                    color: shimmerBase,
                                    radius: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  _SkeletonBox(
                                    width: 110,
                                    height: 28,
                                    color: shimmerBase,
                                    radius: 20,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Column(
                          children: [
                            _SkeletonBox(
                              width: 180,
                              height: 46,
                              color: shimmerBase,
                              radius: 12,
                            ),
                            const SizedBox(height: 10),
                            _SkeletonBox(
                              width: 180,
                              height: 46,
                              color: shimmerBase,
                              radius: 12,
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat())
                      .shimmer(duration: 1400.ms, color: Colors.white24),

                  const SizedBox(height: 28),

                  // Tab bar skeleton
                  Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: List.generate(
                        5,
                        (i) => Expanded(
                          child: Center(
                            child: _SkeletonBox(
                              width: 80,
                              height: 14,
                              color: shimmerBase,
                              radius: 8,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat())
                      .shimmer(duration: 1400.ms, color: Colors.white24),

                  const SizedBox(height: 24),

                  // Content panel skeleton
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      children: List.generate(3, (i) {
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 20,
                              ),
                              child: Row(
                                children: [
                                  _SkeletonBox(
                                    width: 42,
                                    height: 42,
                                    color: shimmerBase,
                                    radius: 12,
                                  ),
                                  const SizedBox(width: 18),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _SkeletonBox(
                                          width: 160,
                                          height: 14,
                                          color: shimmerBase,
                                        ),
                                        const SizedBox(height: 8),
                                        _SkeletonBox(
                                          width: 240,
                                          height: 11,
                                          color: shimmerBase,
                                        ),
                                      ],
                                    ),
                                  ),
                                  _SkeletonBox(
                                    width: 14,
                                    height: 14,
                                    color: shimmerBase,
                                    radius: 4,
                                  ),
                                ],
                              ),
                            ),
                            if (i < 2)
                              Divider(
                                height: 1,
                                thickness: 1,
                                indent: 76,
                                endIndent: 24,
                                color: theme.dividerColor
                                    .withValues(alpha: 0.4),
                              ),
                          ],
                        );
                      }),
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat())
                      .shimmer(duration: 1400.ms, color: Colors.white24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final double radius;

  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.color,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
