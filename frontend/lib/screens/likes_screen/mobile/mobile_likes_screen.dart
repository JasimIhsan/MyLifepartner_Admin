import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/main.dart';

import 'package:life_partner_again/widgets/tour/app_tour_overlay.dart';
import 'package:life_partner_again/widgets/tour/app_tour_step.dart';
import '../widgets/animated_header.dart';
import '../widgets/likes_controller.dart';
import '../widgets/matches_list.dart';

class MobileLikedMatchesScreen extends StatefulWidget {
  const MobileLikedMatchesScreen({super.key});

  @override
  State<MobileLikedMatchesScreen> createState() =>
      _MobileLikedMatchesScreenState();
}

class _MobileLikedMatchesScreenState extends State<MobileLikedMatchesScreen>
    with
        TickerProviderStateMixin,
        RouteAware,
        LikesControllerState<MobileLikedMatchesScreen> {
  final GlobalKey _tabBarKey = GlobalKey();

  List<AppTourStep> get _matchesTourSteps => [
        AppTourStep(
          targetKey: _tabBarKey,
          title: 'Connections & Matches',
          description: 'Switch between Likes Sent, Mutual Matches, and Received Likes.',
          borderRadius: BorderRadius.circular(26),
          preferredPosition: TourCardPosition.bottom,
        ),
      ];

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
    return AppTourOverlay(
      pageId: 'matches',
      dependsOn: const ['home'],
      steps: _matchesTourSteps,
      child: Scaffold(
        backgroundColor: Theme.of(context).canvasColor,
      body: SafeArea(
        child: Column(
          children: [
            AnimatedHeader(
              animation: headerAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Text(
                      'Connections',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color:
                            Theme.of(context).textTheme.bodyLarge?.color ??
                            AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
                  ),
                  _buildCustomTabBar(),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: tabController,
                physics: const BouncingScrollPhysics(),
                children: [
                  MatchesList(tabIndex: 0, onScroll: setHeaderVisible),
                  MatchesList(tabIndex: 1, onScroll: setHeaderVisible),
                  MatchesList(tabIndex: 2, onScroll: setHeaderVisible),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildCustomTabBar() {
    return Container(
      key: _tabBarKey,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).dividerColor, width: 2),
        borderRadius: BorderRadius.circular(26),
      ),
      child: TabBar(
        controller: tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        labelColor: AppColors.textWhite,
        unselectedLabelColor:
            Theme.of(context).textTheme.bodyMedium?.color ??
            AppColors.textSecondary,
        splashBorderRadius: BorderRadius.circular(24),
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        dividerColor: Colors.transparent,
        labelPadding: EdgeInsets.zero,
        tabs: [
          _buildTabItem(Icons.favorite_rounded, "Mutual"),
          _buildTabItem(Icons.call_received_rounded, "Received"),
          _buildTabItem(Icons.send_rounded, "Sent"),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.15);
  }

  Tab _buildTabItem(IconData icon, String text) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
