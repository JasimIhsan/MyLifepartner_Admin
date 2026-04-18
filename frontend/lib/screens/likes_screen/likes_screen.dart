import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:mylifepartner/core/app_colors.dart';
import 'package:mylifepartner/models/match_recommendation.dart';
import 'package:mylifepartner/providers/match_provider.dart';
import 'package:mylifepartner/screens/profile_detail_screen/profile_detail_screen.dart';
import 'package:provider/provider.dart';

class LikedMatchesScreen extends StatefulWidget {
  const LikedMatchesScreen({super.key});

  @override
  State<LikedMatchesScreen> createState() => _LikedMatchesScreenState();
}

class _LikedMatchesScreenState extends State<LikedMatchesScreen>
    with TickerProviderStateMixin {
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _AnimatedHeader(
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
                  _MatchesList(tabIndex: 0, onScroll: _setHeaderVisible),
                  _MatchesList(tabIndex: 1, onScroll: _setHeaderVisible),
                  _MatchesList(tabIndex: 2, onScroll: _setHeaderVisible),
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
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.black.withValues(alpha: 0.04)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
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
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _AnimatedHeader extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _AnimatedHeader({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SizeTransition(
        sizeFactor: animation,
        axisAlignment: -1.0, // Top aligned
        child: child,
      ),
    );
  }
}

class _MatchesList extends StatefulWidget {
  final int tabIndex;
  final Function(bool) onScroll;

  const _MatchesList({required this.tabIndex, required this.onScroll});

  @override
  State<_MatchesList> createState() => _MatchesListState();
}

class _MatchesListState extends State<_MatchesList> {
  double _lastOffset = 0.0;
  bool _isVisible = true;
  static const double _threshold = 40.0; // Higher threshold for stability

  Future<void> _refresh(BuildContext context) async {
    final provider = context.read<MatchProvider>();
    switch (widget.tabIndex) {
      case 0:
        await provider.loadMutualMatches();
        break;
      case 1:
        await provider.loadReceivedInterests();
        break;
      case 2:
        await provider.loadSentInterests();
        break;
    }
  }

  void _handleScroll(ScrollNotification notification) {
    if (notification is UserScrollNotification) {
      final double pixels = notification.metrics.pixels;

      // Force header visible at top
      if (pixels <= 10) {
        if (!_isVisible) {
          _isVisible = true;
          widget.onScroll(true);
        }
        _lastOffset = pixels;
        return;
      }

      final double delta = pixels - _lastOffset;

      if (delta.abs() > _threshold) {
        if (delta > 0 && _isVisible) {
          // Scrolling down
          _isVisible = false;
          widget.onScroll(false);
        } else if (delta < 0 && !_isVisible) {
          // Scrolling up
          _isVisible = true;
          widget.onScroll(true);
        }
        _lastOffset = pixels;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MatchProvider>(
      builder: (context, provider, _) {
        List<MatchRecommendation> profiles = [];
        switch (widget.tabIndex) {
          case 0:
            profiles = provider.mutualMatches;
            break;
          case 1:
            profiles = provider.receivedInterests;
            break;
          case 2:
            profiles = provider.sentInterests;
            break;
        }

        if (provider.state == MatchLoadState.loading && profiles.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          );
        }

        if (provider.state == MatchLoadState.error && profiles.isEmpty) {
          return Center(
            child: Text(
              provider.error ?? 'Error loading profiles',
              style: TextStyle(color: AppColors.error),
            ),
          );
        }

        if (profiles.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.tabIndex == 0
                      ? Icons.favorite_border_rounded
                      : widget.tabIndex == 1
                      ? Icons.mark_email_unread_outlined
                      : Icons.send_outlined,
                  size: 48,
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No profiles found',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 400.ms),
          );
        }

        return NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification notification) {
            _handleScroll(notification);
            return false;
          },
          child: RefreshIndicator(
            onRefresh: () => _refresh(context),
            edgeOffset: 20,
            color: AppColors.black,
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
              ),
              itemCount: profiles.length,
              itemBuilder: (context, index) {
                final profile = profiles[index];
                return _ConnectionCard(profile: profile, index: index);
              },
            ),
          ),
        );
      },
    );
  }
}

class _ConnectionCard extends StatelessWidget {
  final MatchRecommendation profile;
  final int index;

  const _ConnectionCard({required this.profile, required this.index});

  String? get _imageUrl {
    final primary = profile.images.where((img) => img.isPrimary);
    if (primary.isNotEmpty) return primary.first.imageUrl;
    if (profile.images.isNotEmpty) return profile.images.first.imageUrl;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileDetailScreen(
                  profileId: profile.id,
                  profileName: profile.name,
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _imageUrl != null
                      ? Image.network(
                          _imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.4, 1.0],
                          colors: [
                            Colors.transparent,
                            AppColors.black.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${profile.name}, ${profile.age}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textWhite,
                                  height: 1.1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (profile.isVerified) ...[
                              const SizedBox(width: 4),
                              Image.asset(
                                'assets/icons/verified_icon.png',
                                width: 14,
                                height: 14,
                              ),
                            ],
                          ],
                        ),
                        if (profile.city != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                size: 10,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  profile.city!,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white70,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        '${profile.matchPercentage}%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms, delay: (50 * index.clamp(0, 10)).ms)
        .slideY(begin: 0.1, curve: Curves.easeOutCubic);
  }

  Widget _placeholder() => Container(color: AppColors.divider);
}
