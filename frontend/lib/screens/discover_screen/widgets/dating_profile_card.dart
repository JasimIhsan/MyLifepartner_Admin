import 'package:flutter/material.dart';
import 'package:mylifepartner/core/app_colors.dart';
import 'package:mylifepartner/models/match_recommendation.dart';
import 'package:mylifepartner/screens/profile_detail_screen/profile_detail_screen.dart';

class DatingProfileCard extends StatelessWidget {
  final MatchRecommendation profile;
  final bool isSwiped;
  final VoidCallback onInterest;
  final VoidCallback onNotInterested;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final bool showPreviousButton;
  final bool showNextButton;

  const DatingProfileCard({
    super.key,
    required this.profile,
    required this.isSwiped,
    required this.onInterest,
    required this.onNotInterested,
    required this.onNext,
    required this.onPrevious,
    this.showPreviousButton = false,
    this.showNextButton = true,
  });

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
        margin: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.0),
          color: Colors.grey.shade900,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            _imageUrl != null
                ? Image.network(
                    _imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return _placeholder(); // or a shimmer
                    },
                  )
                : _placeholder(),

            // Dim overlay if swiped
            if (isSwiped)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(
                        "Action Recorded",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Bottom Gradient for Text Readability
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 350,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.95),
                        Colors.black.withValues(alpha: 0.8),
                        Colors.black.withValues(alpha: 0.4),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.3, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // Left Navigation Overlay Area
            if (showPreviousButton)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 80,
                child: GestureDetector(
                  onTap: onPrevious,
                  behavior: HitTestBehavior.opaque,
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 12.0),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white70,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),

            // Right Navigation Overlay Area
            if (showNextButton)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 80,
                child: GestureDetector(
                  onTap: onNext,
                  behavior: HitTestBehavior.opaque,
                  child: const Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.only(right: 12.0),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white70,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),

            // Info and Action Buttons (Bottom)
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and Age
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          '${profile.name}, ${profile.age}',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.1,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_isNewProfile(profile.createdAt))
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Location details
                  if (profile.city != null ||
                      profile.maritalStatus != null) ...[
                    Row(
                      children: [
                        if (profile.maritalStatus != null) ...[
                          const Icon(
                            Icons.favorite_border_rounded,
                            size: 14,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatEnum(profile.maritalStatus!),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (profile.city != null) ...[
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              profile.city!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],

                  // Last login details
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _formatLastLogin(profile.lastLoginAt),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons Layout
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Not Interested Button (X)
                      _ActionButton(
                        icon: Icons.close_rounded,
                        color: Colors.white,
                        backgroundColor: Colors.black.withValues(alpha: 0.6),
                        borderColor: Colors.white30,
                        label: "Not Interested",
                        onTap: isSwiped ? null : onNotInterested,
                      ),

                      // Interest Button (Heart)
                      _ActionButton(
                        icon: Icons.favorite_rounded,
                        color: Colors.white,
                        backgroundColor:
                            AppColors.primary, // Using primary theme color
                        borderColor: Colors.transparent,
                        label: "Interest",
                        onTap: isSwiped ? null : onInterest,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.person, size: 100, color: Colors.grey),
      ),
    );
  }

  String _formatEnum(String value) {
    return value
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .map(
          (w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '',
        )
        .join(' ');
  }

  String _formatLastLogin(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      final diff = DateTime.now().difference(date);
      if (diff.inDays == 0) {
        if (diff.inHours == 0) return 'Active just now';
        return 'Active ${diff.inHours}h ago';
      } else if (diff.inDays == 1) {
        return 'Active yesterday';
      } else {
        return 'Active ${diff.inDays}d ago';
      }
    } catch (_) {
      return '';
    }
  }

  bool _isNewProfile(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      final diff = DateTime.now().difference(date);
      return diff.inDays <= 7;
    } catch (_) {
      return false;
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final Color borderColor;
  final String label;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.borderColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: backgroundColor,
              border: Border.all(color: borderColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: backgroundColor.withValues(alpha: 0.4),
                  blurRadius: 15,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.8),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
