import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/core/app_routes.dart';
import 'package:life_partner_again/screens/lpa_guide_screen/lpa_guide_screen.dart';
import 'package:life_partner_again/screens/notification_screen/notification_screen.dart';
import 'package:life_partner_again/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:life_partner_again/models/user_image.dart';
import 'package:life_partner_again/services/profile_repository.dart';
import 'package:life_partner_again/services/user_repository.dart';
import 'package:life_partner_again/widgets/cached_app_image.dart';

class WebMainLayout extends StatefulWidget {
  final Widget child;

  const WebMainLayout({super.key, required this.child});

  @override
  State<WebMainLayout> createState() => _WebMainLayoutState();
}

class _WebMainLayoutState extends State<WebMainLayout> {
  bool _showNotifications = false;
  bool _showGuideOverlay = false;
  UserImage? _primaryImage;
  bool _isLoadingImage = false;

  @override
  void initState() {
    super.initState();
    _fetchUserImage();
  }

  Future<void> _fetchUserImage() async {
    setState(() => _isLoadingImage = true);
    try {
      final images = await ProfileRepository().getUserImages();
      if (images.isNotEmpty) {
        setState(() {
          _primaryImage = images.firstWhere(
            (img) => img.isPrimary == true,
            orElse: () => images.first,
          );
        });
      }
    } catch (e) {
      debugPrint('Error fetching user image for navbar: $e');
    } finally {
      if (mounted) setState(() => _isLoadingImage = false);
    }
  }

  void _handleLogout() {
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

  bool get _isPrefixedWebAppRoute {
    final location = GoRouterState.of(context).matchedLocation;
    return location == '/app' || location.startsWith('/app/');
  }

  String _targetRoute(String route) {
    return _isPrefixedWebAppRoute ? '/app$route' : route;
  }

  String _currentAppLocation() {
    final location = GoRouterState.of(context).matchedLocation;
    if (location == '/app') return AppRoutes.home;
    if (location.startsWith('/app/')) return location.substring('/app'.length);
    return location;
  }

  void _onTabTapped(int index) {
    String targetRoute = AppRoutes.home;
    if (index == 0) targetRoute = AppRoutes.discover;
    if (index == 1) targetRoute = AppRoutes.browseProfiles;

    setState(() {
      _showNotifications = false;
    });
    context.go(_targetRoute(targetRoute));
  }

  int _getSelectedIndex() {
    final location = _currentAppLocation();
    if (location.startsWith(AppRoutes.browseProfiles)) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = kIsWeb && MediaQuery.of(context).size.width >= 800;

    if (!isDesktop) {
      return widget.child;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Column(
            children: [
              _buildWebNavBar(),
              Expanded(
                child: _showNotifications
                    ? NotificationScreen(
                        onBack: () {
                          setState(() {
                            _showNotifications = false;
                          });
                        },
                      )
                    : widget.child,
              ),
            ],
          ),
          if (_showGuideOverlay)
            Positioned(
              right: 32,
              bottom: 88,
              width: 420,
              height: 600,
              child: Card(
                elevation: 16,
                shadowColor: Theme.of(
                  context,
                ).shadowColor.withValues(alpha: 0.15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                clipBehavior: Clip.antiAlias,
                child: const LpaGuideScreen(),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () {
          setState(() {
            _showGuideOverlay = !_showGuideOverlay;
          });
        },
        child: _showGuideOverlay
            ? const Icon(Icons.close_rounded)
            : Padding(
                padding: const EdgeInsets.all(2.0),
                child: Image.asset(
                  'assets/icons/app_icon_foreground.png',
                  color: Theme.of(context).colorScheme.onPrimary,
                  width: 70,
                  height: 70,
                  fit: BoxFit.contain,
                ),
              ),
      ),
    );
  }

  Widget _buildWebNavBar() {
    final int selectedIndex = _getSelectedIndex();
    final theme = Theme.of(context);

    return Container(
      height: 66,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.96),
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.9)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.055),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1480),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 64),
            child: Row(
              children: [
                // Brand Logo
                InkWell(
                  onTap: () => context.go(AppRoutes.public),
                  borderRadius: BorderRadius.circular(8),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 4,
                      ),
                      child: Image.asset(
                        theme.brightness == Brightness.dark
                            ? 'assets/icons/app_logo_dark.png'
                            : 'assets/icons/app_logo.png',
                        height: 100,
                        width: 100,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.favorite,
                          color: theme.primaryColor,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ),
                // Center Nav
                Expanded(
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _WebNavLink(
                          index: 0,
                          selectedIndex: selectedIndex,
                          showNotifications: _showNotifications,
                          icon: Icons.explore_outlined,
                          label: 'Discover',
                          onTabTapped: _onTabTapped,
                        ),
                        _WebNavLink(
                          index: 1,
                          selectedIndex: selectedIndex,
                          showNotifications: _showNotifications,
                          icon: Icons.search_rounded,
                          label: 'Search',
                          onTabTapped: _onTabTapped,
                        ),
                      ],
                    ),
                  ),
                ),
                // Right Side Actions
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _showNotifications
                            ? Icons.notifications
                            : Icons.notifications_active_outlined,
                        color: _showNotifications
                            ? theme.primaryColor
                            : theme.textTheme.bodyMedium?.color ??
                                  AppColors.textSecondary,
                      ),
                      tooltip: 'Notifications',
                      onPressed: () {
                        setState(() {
                          _showNotifications = !_showNotifications;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      offset: const Offset(0, 56),
                      color: theme.colorScheme.surface,
                      // surfaceTintColor: theme.primaryColor.withValues(alpha: 0.05),
                      elevation: 12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: theme.dividerColor.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      tooltip: 'Profile Options',
                      onSelected: (value) async {
                        if (value == 'edit_profile') {
                          try {
                            final user = await UserRepository().getUser();
                            if (!mounted) return;
                            final result = await this.context.push(
                              AppRoutes.editProfile,
                              extra: user,
                            );
                            if (result == true) _fetchUserImage();
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to load user data.'),
                              ),
                            );
                          }

                        } else if (value == 'manage_images') {
                          final result = await context.push(
                            AppRoutes.manageProfilePictures,
                          );
                          if (result == true) _fetchUserImage();
                        } else if (value == 'edit_preference') {
                          context.push(AppRoutes.editPartnerPreference);
                        } else if (value == 'logout') {
                          _handleLogout();
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit_profile',
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          height: 48,
                          child: Row(
                            children: [
                              Icon(Icons.person_outline_rounded, size: 22),
                              SizedBox(width: 16),
                              Text(
                                'Edit Profile',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'manage_images',
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          height: 48,
                          child: Row(
                            children: [
                              Icon(Icons.photo_library_outlined, size: 22),
                              SizedBox(width: 16),
                              Text(
                                'Manage Images',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'edit_preference',
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          height: 48,
                          child: Row(
                            children: [
                              Icon(Icons.tune_rounded, size: 22),
                              SizedBox(width: 16),
                              Text(
                                'Edit Preference',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'logout',
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          height: 48,
                          child: Row(
                            children: [
                              Icon(
                                Icons.logout_rounded,
                                size: 22,
                                color: Colors.red,
                              ),
                              SizedBox(width: 16),
                              Text(
                                'Logout',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.dividerColor,
                            width: 1.5,
                          ),
                        ),
                        child: ClipOval(
                          child: _isLoadingImage
                              ? const Padding(
                                  padding: EdgeInsets.all(10.0),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : _primaryImage != null
                              ? CachedAppImage(
                                  imageId: _primaryImage!.imageId,
                                  presignedImageUrl:
                                      _primaryImage!.presignedImageUrl,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Icon(
                                    Icons.person,
                                    size: 24,
                                    color:
                                        theme.textTheme.bodyMedium?.color ??
                                        AppColors.textSecondary,
                                  ),
                                )
                              : Icon(
                                  Icons.person,
                                  size: 24,
                                  color:
                                      theme.textTheme.bodyMedium?.color ??
                                      AppColors.textSecondary,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WebNavLink extends StatefulWidget {
  final int index;
  final int selectedIndex;
  final bool showNotifications;
  final IconData icon;
  final String label;
  final ValueChanged<int> onTabTapped;

  const _WebNavLink({
    required this.index,
    required this.selectedIndex,
    required this.showNotifications,
    required this.icon,
    required this.label,
    required this.onTabTapped,
  });

  @override
  State<_WebNavLink> createState() => _WebNavLinkState();
}

class _WebNavLinkState extends State<_WebNavLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive =
        widget.selectedIndex == widget.index && !widget.showNotifications;
    final foreground = isActive
        ? theme.colorScheme.primary
        : _isHovered
        ? theme.colorScheme.primary.withValues(alpha: 0.85)
        : theme.textTheme.bodyMedium?.color ?? AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: InkWell(
          onTap: () => widget.onTabTapped(widget.index),
          borderRadius: BorderRadius.circular(8),
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: SizedBox(
            height: 66,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(widget.icon, color: foreground, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        widget.label,
                        style: TextStyle(
                          color: foreground,
                          fontWeight: isActive
                              ? FontWeight.w900
                              : FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    height: isActive ? 3.5 : 0,
                    decoration: BoxDecoration(
                      color: isActive
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
