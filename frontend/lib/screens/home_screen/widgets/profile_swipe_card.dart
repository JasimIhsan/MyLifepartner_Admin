import 'package:flutter/material.dart';
import 'package:mylifepartner/models/match_recommendation.dart';
import 'package:mylifepartner/screens/home_screen/widgets/match_percentage_badge.dart';
import 'package:mylifepartner/screens/home_screen/widgets/profile_image_carousel.dart';

class ProfileSwipeCard extends StatelessWidget {
  final MatchRecommendation profile;
  final VoidCallback? onViewProfile;

  const ProfileSwipeCard({
    super.key,
    required this.profile,
    this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.of(context).size.height * 0.62;

        final hasHighlights = profile.compatibilityHighlights.isNotEmpty;

        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: double.infinity,
            height: cardHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 24,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── IMAGE SECTION (fills all remaining space) ──────
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ProfileImageCarousel(
                          images: profile.images,
                          height: double.infinity,
                        ),

                        // Match % badge – top right
                        Positioned(
                          top: 48,
                          right: 14,
                          child: MatchPercentageBadge(
                            percentage: profile.matchPercentage,
                          ),
                        ),

                        // Gradient + text overlay at bottom of image
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(16, 48, 16, 14),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Color(0xDD000000)],
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${profile.name}, ${profile.age}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _buildSubtitle(),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _buildReligionOccupation(),
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── COMPATIBILITY HIGHLIGHTS (flexible height) ─────────
                if (hasHighlights)
                  SizedBox(
                    width: double.infinity,
                    child: ColoredBox(
                      color: const Color(0xFFF8F9FA),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Why you match',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF9E9E9E),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: profile.compatibilityHighlights
                                  .take(3)
                                  .map(
                                    (h) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5E9),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        h,
                                        style: const TextStyle(
                                          color: Color(0xFF2E7D32),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // ── VIEW FULL PROFILE BUTTON (flexible height) ─────────
                SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: OutlinedButton.icon(
                      onPressed: onViewProfile,
                      icon: const Icon(Icons.person_outline, size: 16),
                      label: const Text('View Full Profile'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF7B2D8B),
                        side: const BorderSide(color: Color(0xFF7B2D8B)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _buildSubtitle() {
    final parts = <String>[];
    if (profile.heightCm != null) parts.add('${profile.heightCm} cm');
    if (profile.city != null) parts.add(profile.city!);
    return parts.join(' • ');
  }

  String _buildReligionOccupation() {
    final parts = <String>[];
    if (profile.religion != null) parts.add(profile.religion!);
    if (profile.occupation != null) parts.add(profile.occupation!);
    return parts.join(' • ');
  }
}
