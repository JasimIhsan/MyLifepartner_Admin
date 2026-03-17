import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mylifepartner/core/app_colors.dart';
import 'package:mylifepartner/models/match_recommendation.dart';
import 'package:mylifepartner/providers/match_provider.dart';
import 'package:mylifepartner/screens/profile_detail_screen/profile_detail_screen.dart';
import 'package:provider/provider.dart';

/// Discover listing – clean card list, no action buttons here.
/// Actions (Interested / Pass) live on the profile detail page.
class MatchesListTab extends StatelessWidget {
  final String title;

  const MatchesListTab({
    super.key,
    this.title = 'Your Matches',
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Finding your matches…',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(MatchProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 56,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load matches',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection and try again',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            _buildRetryButton(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(MatchProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_outline_rounded,
                size: 42,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No matches right now',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back soon, new profiles are added daily',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 28),
            _buildRetryButton(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildRetryButton(MatchProvider provider) {
    return GestureDetector(
      onTap: provider.loadRecommendations,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          'Refresh',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, MatchProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                '${provider.profiles.length} profiles',
                style: GoogleFonts.poppins(
                  fontSize: 12,
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
            strokeWidth: 2,
            onRefresh: provider.loadRecommendations,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              itemCount: provider.profiles.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _MatchCard(profile: provider.profiles[index])
                      .animate()
                      .fadeIn(
                        duration: 400.ms,
                        delay: Duration(milliseconds: 40 * index.clamp(0, 12)),
                      )
                      .slideY(begin: 0.06, end: 0, curve: Curves.easeOut),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Card ─────────────────────────────────────────────────────────────────────

class _MatchCard extends StatelessWidget {
  final MatchRecommendation profile;

  const _MatchCard({required this.profile});

  String? get _primaryImageUrl {
    final primary = profile.images.where((img) => img.isPrimary);
    if (primary.isNotEmpty) return primary.first.imageUrl;
    if (profile.images.isNotEmpty) return profile.images.first.imageUrl;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProfileDetailScreen(
                profileId: profile.id,
                profileName: profile.name,
                seedProfile: profile,
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFEEEEEE),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildPhoto(),
              const SizedBox(width: 14),
              Expanded(child: _buildInfo()),
              _buildChevron(),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoto() {
    final url = _primaryImageUrl;
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        bottomLeft: Radius.circular(20),
      ),
      child: SizedBox(
        width: 90,
        height: 110,
        child: url != null
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _photoPlaceholder(),
              )
            : _photoPlaceholder(),
      ),
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      color: AppColors.primaryLight,
      child: const Center(
        child: Icon(Icons.person_rounded, size: 36, color: Color(0xFFBBBBBB)),
      ),
    );
  }

  Widget _buildInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Name + match badge
          Row(
            children: [
              Expanded(
                child: Text(
                  '${profile.name}, ${profile.age}',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildMatchBadge(),
            ],
          ),
          const SizedBox(height: 4),
          // Location
          if (profile.city != null)
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 12,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 3),
                Text(
                  profile.city!,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8),
          // Info chips
          _buildInfoRow(),
        ],
      ),
    );
  }

  Widget _buildMatchBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${profile.matchPercentage}%',
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildInfoRow() {
    final chips = <Widget>[];
    if (profile.religion != null) {
      chips.add(_chip(profile.religion!));
    }
    if (profile.occupation != null) {
      chips.add(_chip(profile.occupation!));
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 6, runSpacing: 4, children: chips);
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildChevron() {
    return const Icon(
      Icons.chevron_right_rounded,
      color: AppColors.textSecondary,
      size: 20,
    );
  }
}
