import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/main.dart';
import '../widgets/likes_controller.dart';
import '../widgets/matches_list.dart';

class WebLikedMatchesScreen extends StatefulWidget {
  const WebLikedMatchesScreen({super.key});

  @override
  State<WebLikedMatchesScreen> createState() => _WebLikedMatchesScreenState();
}

class _WebLikedMatchesScreenState extends State<WebLikedMatchesScreen>
    with TickerProviderStateMixin, RouteAware, LikesControllerState<WebLikedMatchesScreen> {

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // A premium light gray for background
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1400),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Sidebar for Tabs
              SizedBox(
                width: 280,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Connections',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -1.0,
                        height: 1.2,
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
                    const SizedBox(height: 12),
                    const Text(
                      'Manage your likes, mutual matches, and connection requests.',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                    const SizedBox(height: 48),
                    _buildWebSidebarTab(
                      index: 0,
                      icon: Icons.favorite_rounded,
                      title: "Mutual Matches",
                    ),
                    const SizedBox(height: 12),
                    _buildWebSidebarTab(
                      index: 1,
                      icon: Icons.call_received_rounded,
                      title: "Received Interests",
                    ),
                    const SizedBox(height: 12),
                    _buildWebSidebarTab(
                      index: 2,
                      icon: Icons.send_rounded,
                      title: "Sent Interests",
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 48),
              // Right Content Area for Grid
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 40,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    border: Border.all(
                      color: AppColors.borderColor.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: TabBarView(
                    controller: tabController,
                    physics: const NeverScrollableScrollPhysics(), // Disable swipe on web
                    children: [
                      _buildWebContent(0),
                      _buildWebContent(1),
                      _buildWebContent(2),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebContent(int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 32, 32, 24),
          child: Text(
            index == 0
                ? "Mutual Matches"
                : index == 1
                    ? "Received Interests"
                    : "Sent Interests",
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const Divider(height: 1, thickness: 1, color: AppColors.borderColor),
        Expanded(
          child: MatchesList(
            tabIndex: index,
            onScroll: setHeaderVisible, // No-op on web since there's no mobile header
            isWeb: true, // Grid will have 4 columns
          ),
        ),
      ],
    );
  }

  Widget _buildWebSidebarTab({
    required int index,
    required IconData icon,
    required String title,
  }) {
    return AnimatedBuilder(
      animation: tabController,
      builder: (context, _) {
        final isSelected = tabController.index == index;
        return InkWell(
          onTap: () {
            tabController.animateTo(index);
          },
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.primary.withValues(alpha: 0.5) : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  size: 22,
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
