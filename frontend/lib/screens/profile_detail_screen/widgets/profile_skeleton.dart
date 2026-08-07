import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  Widget _skeletonCircle(BuildContext context, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _skeletonBox(BuildContext context, {double width = double.infinity, double height = 16}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  @override
  Widget build(BuildContext context) {
    final double actionBarAndGapHeight =
        90 + MediaQuery.of(context).padding.bottom;
    final double topSectionHeight =
        MediaQuery.of(context).size.height - actionBarAndGapHeight;

    return Stack(
      children: [
        // Scrollable skeleton (same structure as real UI)
        CustomScrollView(
          slivers: [
            // 🔝 HEADER (same as real)
            SliverToBoxAdapter(
              child: SizedBox(
                height: topSectionHeight,
                child: Stack(
                  children: [
                    // Image placeholder
                    Positioned.fill(
                      child: Container(color: Theme.of(context).disabledColor.withValues(alpha: 0.1)),
                    ),

                    // Gradient overlay (same as real)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 250,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.4),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Name row skeleton
                    Positioned(
                      bottom: 30,
                      left: 20,
                      right: 20,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _skeletonBox(context, width: 180, height: 28),
                                const SizedBox(height: 8),
                                _skeletonBox(context, width: 120, height: 16),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          _skeletonBox(context, width: 60, height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 🔽 BODY (same spacing & structure)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Compatibility section
                    _skeletonBox(context, width: 120, height: 18),
                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(
                        4,
                        (_) => _skeletonBox(context, width: 80, height: 28),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // About section
                    _skeletonBox(context, width: 100, height: 18),
                    const SizedBox(height: 12),
                    _skeletonBox(context, height: 80),

                    const SizedBox(height: 24),

                    // Details grid placeholder
                    _skeletonBox(context, height: 120),

                    const SizedBox(height: 24),

                    // Photos section
                    _skeletonBox(context, width: 140, height: 18),
                    const SizedBox(height: 12),
                    _skeletonBox(context, height: 260),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),

        // 🔙 Back button (same position)
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 12,
          child: _skeletonCircle(context, 44),
        ),

        // 🌍 Flag placeholder
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          right: 16,
          child: _skeletonCircle(context, 38),
        ),

        // ⬇️ Bottom action bar skeleton
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            color: Theme.of(context).colorScheme.surface,
            child: Row(
              children: [
                Expanded(child: _skeletonBox(context, height: 50)),
                const SizedBox(width: 12),
                Expanded(child: _skeletonBox(context, height: 50)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
