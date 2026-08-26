import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/core/app_routes.dart';
import 'package:life_partner_again/screens/lpa_guide_screen/lpa_guide_screen.dart';
import 'package:life_partner_again/screens/notification_screen/notification_screen.dart';

class WebMainLayout extends StatefulWidget {
  final Widget child;

  const WebMainLayout({super.key, required this.child});

  @override
  State<WebMainLayout> createState() => _WebMainLayoutState();
}

class _WebMainLayoutState extends State<WebMainLayout> {
  bool _showNotifications = false;
  bool _showGuideOverlay = false;

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
    if (index == 1) targetRoute = AppRoutes.matches;
    if (index == 2) targetRoute = AppRoutes.chat;
    if (index == 3) targetRoute = AppRoutes.profile;

    setState(() {
      _showNotifications = false;
    });
    context.go(_targetRoute(targetRoute));
  }

  int _getSelectedIndex() {
    final location = _currentAppLocation();
    if (location.startsWith(AppRoutes.matches)) return 1;
    if (location.startsWith(AppRoutes.chat)) return 2;
    if (location.startsWith(AppRoutes.profile) && !location.contains(':')) {
      return 3;
    }
    // For anything else including discover, default to 0 if it's a root route
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
        child: Icon(
          _showGuideOverlay ? Icons.close_rounded : Icons.support_agent_rounded,
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
            padding: const EdgeInsets.symmetric(horizontal: 24),
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
                          icon: Icons.favorite_border,
                          label: 'Matches',
                          onTabTapped: _onTabTapped,
                        ),
                        _WebNavLink(
                          index: 2,
                          selectedIndex: selectedIndex,
                          showNotifications: _showNotifications,
                          icon: Icons.chat_bubble_outline,
                          label: 'Chat',
                          onTabTapped: _onTabTapped,
                        ),
                        _WebNavLink(
                          index: 3,
                          selectedIndex: selectedIndex,
                          showNotifications: _showNotifications,
                          icon: Icons.person_outline,
                          label: 'Profile',
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
