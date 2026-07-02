import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/models/match_recommendation.dart';

class ProfileImageCarousel extends StatefulWidget {
  final List<MatchImage> images;
  final double height;

  const ProfileImageCarousel({
    super.key,
    required this.images,
    this.height = 420,
  });

  @override
  State<ProfileImageCarousel> createState() => _ProfileImageCarouselState();
}

class _ProfileImageCarouselState extends State<ProfileImageCarousel> {
  int _currentIndex = 0;

  List<MatchImage> get _sortedImages {
    final sorted = [...widget.images];
    sorted.sort((a, b) => (b.isPrimary ? 1 : 0) - (a.isPrimary ? 1 : 0));
    return sorted;
  }

  void _goNext() {
    final images = _sortedImages;
    if (_currentIndex < images.length - 1) {
      setState(() => _currentIndex++);
    }
  }

  void _goPrev() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = _sortedImages;
    if (images.isEmpty) {
      return Container(
        height: widget.height,
        color: Colors.black,
        child: const Center(
          child: Icon(Icons.person, size: 80, color: Colors.white24),
        ),
      );
    }

    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          // Main image
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: CachedNetworkImage(
              key: ValueKey(_currentIndex),
              imageUrl: images[_currentIndex].imageUrl,
              width: double.infinity,
              height: widget.height,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: Colors.black,
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.surface),
                ),
              ),
              errorWidget: (_, __, ___) => Container(
                color: Colors.black,
                child: const Icon(
                  Icons.person,
                  size: 80,
                  color: Colors.white24,
                ),
              ),
            ),
          ),

          // Progress bar at top (story style)
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Row(
              children: List.generate(
                images.length.clamp(1, 4),
                (i) => Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    height: 3,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: i <= _currentIndex
                          ? AppColors.surface
                          : AppColors.surface.withValues(alpha: 0.35),
                    ),
                  ).animate().fadeIn(duration: 200.ms),
                ),
              ),
            ),
          ),

          // Tap zones
          Positioned.fill(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _goPrev,
                    behavior: HitTestBehavior.translucent,
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _goNext,
                    behavior: HitTestBehavior.translucent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
