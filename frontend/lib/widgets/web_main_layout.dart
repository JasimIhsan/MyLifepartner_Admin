import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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

  void _onTabTapped(int index) {
    String targetRoute = AppRoutes.home;
    if (index == 0) targetRoute = AppRoutes.discover;
    if (index == 1) targetRoute = AppRoutes.matches;
    if (index == 2) targetRoute = AppRoutes.chat;
    if (index == 3) targetRoute = AppRoutes.profile;

    setState(() {
      _showNotifications = false;
    });
    context.go(targetRoute);
  }

  int _getSelectedIndex() {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(AppRoutes.matches)) return 1;
    if (location.startsWith(AppRoutes.chat)) return 2;
    if (location.startsWith(AppRoutes.profile) && !location.contains(':')) return 3;
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
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          Column(
            children: [
              _buildWebNavBar(),
              Expanded(
                child: _showNotifications 
                    ? NotificationScreen(onBack: () {
                        setState(() {
                          _showNotifications = false;
                        });
                      })
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
                shadowColor: Colors.black.withValues(alpha: 0.15),
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
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        onPressed: () {
          setState(() {
            _showGuideOverlay = !_showGuideOverlay;
          });
        },
        child: Icon(
          _showGuideOverlay
              ? Icons.close_rounded
              : Icons.support_agent_rounded,
        ),
      ),
    );
  }

  Widget _buildWebNavBar() {
    final int selectedIndex = _getSelectedIndex();

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Brand Logo and Title
          Row(
            children: [
              Image.asset(
                'assets/icons/app_logo.png',
                height: 36,
                width: 36,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.favorite,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Life Partner Again",
                style: GoogleFonts.outfit(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Navigation Tabs
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildWebNavItem(0, selectedIndex, Icons.explore_outlined, 'Discover'),
              _buildWebNavItem(1, selectedIndex, Icons.favorite_border, 'Matches'),
              _buildWebNavItem(2, selectedIndex, Icons.chat_bubble_outline, 'Chat'),
              _buildWebNavItem(3, selectedIndex, Icons.person_outline, 'Profile'),
            ],
          ),
          const Spacer(),
          // Right Side Actions
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _showNotifications
                      ? Icons.notifications
                      : Icons.notifications_active_outlined,
                  color: _showNotifications
                      ? AppColors.primary
                      : AppColors.textSecondary,
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
    );
  }

  Widget _buildWebNavItem(int index, int selectedIndex, IconData icon, String label) {
    // Only highlight if no notifications are showing and we match the index
    final bool isSelected = selectedIndex == index && !_showNotifications;
    return InkWell(
      onTap: () => _onTabTapped(index),
      hoverColor: AppColors.primary.withValues(alpha: 0.05),
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : Colors.grey.shade600,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: isSelected ? AppColors.primary : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
