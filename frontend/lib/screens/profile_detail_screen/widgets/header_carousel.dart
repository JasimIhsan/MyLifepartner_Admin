import 'package:flutter/material.dart';
import 'package:life_partner_again/core/app_colors.dart';

class HeaderCarousel extends StatefulWidget {
  final List<dynamic> images;

  const HeaderCarousel({super.key, required this.images});

  @override
  State<HeaderCarousel> createState() => _HeaderCarouselState();
}

class _HeaderCarouselState extends State<HeaderCarousel> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    if (images.isEmpty) return const SizedBox.shrink();

    return Stack(
      children: [
        PageView.builder(
          itemCount: images.length,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (_, i) {
            final img = images[i] as Map<String, dynamic>;
            final url = img['imageUrl'] as String?;
            if (url == null) return Container(color: AppColors.primaryLight);

            return Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: AppColors.primaryLight),
            );
          },
        ),
        // Gradient overlay
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
                  Colors.black.withValues(alpha: 0.9),
                  Colors.black.withValues(alpha: 0.4),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
          ),
        ),
        // Indicators
        if (images.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: _page == i ? 20 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: _page == i
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}
