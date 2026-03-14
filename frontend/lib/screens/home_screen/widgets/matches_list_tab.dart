import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mylifepartner/core/app_colors.dart';
import 'package:mylifepartner/models/match_recommendation.dart';
import 'package:mylifepartner/providers/match_provider.dart';
import 'package:mylifepartner/screens/home_screen/widgets/match_percentage_badge.dart';
import 'package:mylifepartner/screens/profile_detail_screen/profile_detail_screen.dart';
import 'package:provider/provider.dart';

/// A comprehensive list view for displaying match profiles.
/// Used in both the Discover and Matches tabs.
///
/// When [showActions] is true, each card shows interested / not-interested
/// buttons (for the Discover tab). When false, it's a read-only list.
class MatchesListTab extends StatelessWidget {
  final String title;
  final bool showActions;

  const MatchesListTab({
    super.key,
    this.title = 'Your Matches',
    this.showActions = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<MatchProvider>(
      builder: (context, provider, _) {
        if (provider.state == MatchLoadState.loading) {
          return _buildLoading();
        }
        if (provider.state == MatchLoadState.error) {
          return _buildError(provider);
        }
        if (provider.profiles.isEmpty) {
          return _buildEmpty(provider);
        }
        return _buildList(context, provider);
      },
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text(
            'Finding your matches…',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildError(MatchProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Could not load matches',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: provider.loadRecommendations,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(MatchProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.people_outline_rounded,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No matches right now',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back soon for new profiles',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: provider.loadRecommendations,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, MatchProvider provider) {
    final profiles = provider.profiles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${profiles.length} profiles',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: provider.loadRecommendations,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              itemCount: profiles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _MatchListCard(
                      profile: profiles[index],
                      showActions: showActions,
                      onInterested: showActions
                          ? () => provider.swipeRight()
                          : null,
                      onNotInterested: showActions
                          ? () => provider.swipeLeft()
                          : null,
                      onSkip: showActions ? () => provider.swipeUp() : null,
                    )
                    .animate()
                    .fadeIn(
                      duration: 350.ms,
                      delay: Duration(milliseconds: 50 * index.clamp(0, 10)),
                    )
                    .slideY(begin: 0.04, end: 0);
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Individual match card ────────────────────────────────────────────────────

class _MatchListCard extends StatelessWidget {
  final MatchRecommendation profile;
  final bool showActions;
  final VoidCallback? onInterested;
  final VoidCallback? onNotInterested;
  final VoidCallback? onSkip;

  const _MatchListCard({
    required this.profile,
    this.showActions = false,
    this.onInterested,
    this.onNotInterested,
    this.onSkip,
  });

  String? get _primaryImageUrl {
    final primary = profile.images.where((img) => img.isPrimary);
    if (primary.isNotEmpty) return primary.first.imageUrl;
    if (profile.images.isNotEmpty) return profile.images.first.imageUrl;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
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
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: avatar + name/location + chevron
                Row(
                  children: [
                    _buildAvatar(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${profile.name}, ${profile.age}',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (profile.city != null)
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 13,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    profile.city!,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    MatchPercentageBadge(percentage: profile.matchPercentage),
                  ],
                ),

                // Detail chips
                const SizedBox(height: 10),
                _buildInfo(),

                // Compatibility highlights
                if (profile.compatibilityHighlights.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildHighlights(),
                ],

                // Action buttons for Discover
                if (showActions) ...[
                  const SizedBox(height: 8),
                  _buildActionButtons(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final imageUrl = _primaryImageUrl;

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.primaryLight,
        image: imageUrl != null
            ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
            : null,
      ),
      child: imageUrl == null
          ? const Center(
              child: Icon(
                Icons.person_rounded,
                size: 28,
                color: AppColors.primary,
              ),
            )
          : null,
    );
  }

  Widget _buildInfo() {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        if (profile.religion != null)
          _detailChip(Icons.auto_awesome_outlined, profile.religion!),
        if (profile.occupation != null)
          _detailChip(Icons.work_outline_rounded, profile.occupation!),
        if (profile.heightCm != null)
          _detailChip(
            Icons.straighten_rounded,
            _formatHeight(profile.heightCm!),
          ),
      ],
    );
  }

  Widget _detailChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primaryDark),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlights() {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: profile.compatibilityHighlights.take(3).map((h) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.15),
              width: 0.8,
            ),
          ),
          child: Text(
            h,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons() {
    Widget btn(
      IconData icon,
      String label,
      Color color,
      Color bg,
      VoidCallback? onTap,
    ) {
      return Expanded(
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        btn(
          Icons.close_rounded,
          'Pass',
          Colors.black,
          Colors.black.withValues(alpha: 0.08),
          onNotInterested,
        ),
        const SizedBox(width: 8),
        btn(
          Icons.fast_forward_rounded,
          'Skip',
          AppColors.textSecondary,
          AppColors.primary,
          onSkip,
        ),
        const SizedBox(width: 8),
        btn(
          Icons.favorite_rounded,
          'Interested',
          Colors.black,
          Colors.black.withValues(alpha: 0.08),
          onInterested,
        ),
      ],
    );
  }

  String _formatHeight(int cm) {
    final feet = cm ~/ 30.48;
    final inches = ((cm % 30.48) / 2.54).round();
    return '$feet\'$inches" ($cm cm)';
  }
}
