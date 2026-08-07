import 'package:go_router/go_router.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/models/match_recommendation.dart';
import 'package:life_partner_again/providers/match_provider.dart';
import 'package:provider/provider.dart';

/// Discover listing – editorial magazine feel with portrait cards.
class MatchesListTab extends StatefulWidget {
  final String title;

  const MatchesListTab({super.key, this.title = ''});

  @override
  State<MatchesListTab> createState() => _MatchesListTabState();
}

class _MatchesListTabState extends State<MatchesListTab> {
  final ScrollController _scrollController = ScrollController();
  final List<MatchRecommendation> _displayed = [];
  List<MatchRecommendation> _source = [];
  bool _isLoadingMore = false;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = context.read<MatchProvider>();
        // Always try to load if idle or if we have no profiles yet
        if (provider.state == MatchLoadState.idle ||
            provider.profiles.isEmpty) {
          provider.loadRecommendations();
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _seedFromProvider(List<MatchRecommendation> profiles) {
    if (profiles.isEmpty) {
      _source.clear();
      _displayed.clear();
      return;
    }

    if (_source.length == profiles.length &&
        _source.isNotEmpty &&
        _source.first.id == profiles.first.id) {
      return;
    }

    if (_source.isNotEmpty && profiles.length < _source.length) {
      final newIds = profiles.map((e) => e.id).toSet();
      _source = List.from(profiles);
      _displayed.removeWhere((d) => !newIds.contains(d.id));
      return;
    }

    _source = List.from(profiles);
    _displayed
      ..clear()
      ..addAll(_source.take(_pageSize));
  }

  void _onScroll() {
    if (_isLoadingMore || _source.isEmpty) return;
    final threshold = _scrollController.position.maxScrollExtent - 200;
    if (_scrollController.position.pixels >= threshold) _loadMore();
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    final cur = _displayed.length;
    for (int i = 0; i < _pageSize; i++) {
      _displayed.add(_source[(cur + i) % _source.length]);
    }
    setState(() => _isLoadingMore = false);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MatchProvider>(
      builder: (context, provider, _) {
        final sourceProfiles = provider.profiles;

        if (provider.state == MatchLoadState.loading) {
          return _buildSkeleton();
        }
        if (provider.state == MatchLoadState.error) {
          return _buildError(provider);
        }
        if (sourceProfiles.isEmpty) {
          return _buildEmpty(provider);
        }
        _seedFromProvider(sourceProfiles);
        return _buildList(context, provider);
      },
    );
  }

  // ─── Skeleton ──────────────────────────────────────────────────────────────

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      itemBuilder: (_, i) => Padding(
        padding: EdgeInsets.only(bottom: i == 0 ? 16 : 12),
        child: _SkeletonCard(index: i, hero: i == 0),
      ),
    );
  }

  // ─── Error & Empty ─────────────────────────────────────────────────────────

  Widget _buildError(MatchProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 1.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded, size: 32),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.error ?? 'Check your network and try again',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            _buildRetryButton(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(MatchProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 1.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.people_outline_rounded, size: 36),
            ),
            const SizedBox(height: 24),
            Text(
              'No profiles yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'New profiles are added daily.\\nCheck back soon.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            _buildRetryButton(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildRetryButton(MatchProvider provider) {
    return GestureDetector(
      onTap: () {
        _displayed.clear();
        _source.clear();
        provider.loadRecommendations();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          'Refresh',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  // ─── Real list ─────────────────────────────────────────────────────────────

  Widget _buildList(BuildContext context, MatchProvider provider) {
    return RefreshIndicator(
      color: Colors.black,
      strokeWidth: 1.5,
      onRefresh: () async {
        _displayed.clear();
        _source.clear();
        await provider.loadRecommendations();
      },
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                if (index == _displayed.length) return _buildFooterLoader();
                final profile = _displayed[index];
                final isHero = index == 0;
                return Padding(
                  padding: EdgeInsets.only(bottom: isHero ? 16 : 10),
                  child:
                      (isHero
                              ? _HeroCard(profile: profile)
                              : _PortraitCard(profile: profile, index: index))
                          .animate()
                          .fadeIn(
                            duration: 450.ms,
                            delay: Duration(
                              milliseconds: 50 * index.clamp(0, 10),
                            ),
                          )
                          .slideY(
                            begin: 0.08,
                            end: 0,
                            curve: Curves.easeOutCubic,
                            duration: 400.ms,
                          ),
                );
              }, childCount: _displayed.length + (_isLoadingMore ? 1 : 0)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLoader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Loading more…',
              style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Hero Card (first card, large) ───────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final MatchRecommendation profile;
  const _HeroCard({required this.profile});

  String? get _imageUrl {
    final primary = profile.images.where((img) => img.isPrimary);
    if (primary.isNotEmpty) return primary.first.imageUrl;
    if (profile.images.isNotEmpty) return profile.images.first.imageUrl;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/profile/${profile.id}'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 300,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Photo
              _imageUrl != null
                  ? Image.network(
                      _imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),

              // Bottom gradient overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.35, 1.0],
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.82),
                      ],
                    ),
                  ),
                ),
              ),

              // Info overlay
              Positioned(
                left: 18,
                right: 18,
                bottom: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            '${profile.name}, ${profile.age}',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              height: 1.1,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        _MatchArc(percentage: profile.matchPercentage),
                      ],
                    ),
                    if (profile.city != null) ...[
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            profile.city!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    _buildChips(),
                  ],
                ),
              ),
              if (profile.interactionState != InteractionState.none)
                Positioned(
                  top: 16,
                  left: 16,
                  child: _InteractionBadge(state: profile.interactionState),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(color: const Color(0xFFEEEEEE));

  Widget _buildChips() {
    final items = <String>[];
    if (profile.occupation != null) items.add(profile.occupation!);
    if (items.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      children: items
          .map(
            (label) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

// ─── Portrait Card (regular cards) ───────────────────────────────────────────

class _PortraitCard extends StatelessWidget {
  final MatchRecommendation profile;
  final int index;
  const _PortraitCard({required this.profile, required this.index});

  String? get _imageUrl {
    final primary = profile.images.where((img) => img.isPrimary);
    if (primary.isNotEmpty) return primary.first.imageUrl;
    if (profile.images.isNotEmpty) return profile.images.first.imageUrl;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/profile/${profile.id}'),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEBEBEB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Photo
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: SizedBox(
                width: 100,
                height: 120,
                child: _imageUrl != null
                    ? Image.network(
                        _imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${profile.name}, ${profile.age}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary,
                            height: 1.1,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (profile.city != null) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 11,
                                color: Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textSecondary,
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  profile.city!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [Expanded(child: _buildBottom())],
                    ),
                  ],
                ),
              ),
            ),
            // Badges / Match arc
            Padding(
              padding: const EdgeInsets.only(right: 14, top: 14, bottom: 14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (profile.interactionState != InteractionState.none)
                    _InteractionBadge(state: profile.interactionState),
                  if (profile.interactionState == InteractionState.none)
                    const SizedBox(height: 20),
                  _MatchArc(percentage: profile.matchPercentage, size: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(color: const Color(0xFFF0F0F0));

  Widget _buildBottom() {
    final items = <String>[];
    if (profile.occupation != null) items.add(profile.occupation!);
    if (items.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 5,
      children: items
          .map(
            (label) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFDDDDDD)),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _InteractionBadge extends StatelessWidget {
  final InteractionState state;

  const _InteractionBadge({required this.state});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    String label;
    IconData icon;

    switch (state) {
      case InteractionState.matched:
        bgColor = Theme.of(context).primaryColor;
        label = 'MATCHED';
        icon = Icons.favorite_rounded;
        break;
      case InteractionState.interestSent:
        bgColor = Colors.blue.shade600;
        label = 'INTEREST SENT';
        icon = Icons.send_rounded;
        break;
      case InteractionState.interestReceived:
        bgColor = Colors.amber.shade600;
        label = 'INTEREST RECEIVED';
        icon = Icons.mark_email_unread_rounded;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Match Arc Widget ─────────────────────────────────────────────────────────

class _MatchArc extends StatelessWidget {
  final int percentage;
  final double size;
  const _MatchArc({required this.percentage, this.size = 52});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ArcPainter(percentage / 100),
        child: Center(
          child: Text(
            '$percentage%',
            style: TextStyle(
              fontSize: size < 48 ? 9.5 : 11,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double progress;
  const _ArcPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 5) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track
    final trackPaint = Paint()
      ..color = const Color(0xFFEEEEEE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false, trackPaint);

    // Progress
    final progressPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.progress != progress;
}

// ─── Skeleton Cards ───────────────────────────────────────────────────────────

class _SkeletonCard extends StatelessWidget {
  final int index;
  final bool hero;
  const _SkeletonCard({required this.index, this.hero = false});

  @override
  Widget build(BuildContext context) {
    if (hero) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: _Bone(width: double.infinity, height: 300, radius: 20)
            .animate(delay: Duration(milliseconds: 60 * index))
            .fadeIn(duration: 300.ms),
      );
    }
    return Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEBEBEB)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: _Bone(width: 100, height: 120, radius: 0),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Bone(width: 130, height: 16, radius: 6),
                    const SizedBox(height: 8),
                    _Bone(width: 80, height: 12, radius: 5),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _Bone(width: 55, height: 20, radius: 10),
                        const SizedBox(width: 6),
                        _Bone(width: 72, height: 20, radius: 10),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _Bone(width: 40, height: 40, radius: 20),
              const SizedBox(width: 14),
            ],
          ),
        )
        .animate(delay: Duration(milliseconds: 60 * index))
        .fadeIn(duration: 300.ms);
  }
}

// ─── Shimmer bone ─────────────────────────────────────────────────────────────

class _Bone extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _Bone({
    required this.width,
    required this.height,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child:
          SizedBox(
                width: width,
                height: height,
                child: DecoratedBox(
                  decoration: const BoxDecoration(color: Color(0xFFE8E8E8)),
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .shimmer(
                duration: 1200.ms,
                color: const Color(0xFFF5F5F5),
                angle: 0.5,
              ),
    );
  }
}