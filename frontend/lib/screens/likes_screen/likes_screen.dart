import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/main.dart';
import 'package:life_partner_again/providers/match_provider.dart';
import 'package:provider/provider.dart';
import 'widgets/animated_header.dart';
import 'widgets/matches_list.dart';

class LikedMatchesScreen extends StatefulWidget {
  const LikedMatchesScreen({super.key});

  @override
  State<LikedMatchesScreen> createState() => _LikedMatchesScreenState();
}

class _LikedMatchesScreenState extends State<LikedMatchesScreen>
    with TickerProviderStateMixin, RouteAware {
  late TabController _tabController;
  late AnimationController _headerController;
  late Animation<double> _headerAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);

    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _headerAnimation = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeInOutCubic,
    );
    _headerController.value = 1.0; // Initially visible

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDataForCurrentTab();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void didPopNext() {
    _loadDataForCurrentTab();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      _loadDataForCurrentTab();
    }
  }

  void _loadDataForCurrentTab() {
    final provider = context.read<MatchProvider>();
    switch (_tabController.index) {
      case 0:
        provider.loadMutualMatches();
        break;
      case 1:
        provider.loadReceivedInterests();
        break;
      case 2:
        provider.loadSentInterests();
        break;
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _tabController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  void _setHeaderVisible(bool visible) {
    if (visible) {
      _headerController.forward();
    } else {
      _headerController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            AnimatedHeader(
              animation: _headerAnimation,
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
                        color: AppColors.textPrimary,
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
                controller: _tabController,
                physics: const BouncingScrollPhysics(),
                children: [
                  MatchesList(tabIndex: 0, onScroll: _setHeaderVisible),
                  MatchesList(tabIndex: 1, onScroll: _setHeaderVisible),
                  MatchesList(tabIndex: 2, onScroll: _setHeaderVisible),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.borderColor, width: 2),
        borderRadius: BorderRadius.circular(26),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: AppColors.primary,
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
        unselectedLabelColor: AppColors.textSecondary,
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
