import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:life_partner_again/screens/public_web/services/app_download_promotion_service.dart';
import 'package:life_partner_again/screens/public_web/widgets/download_app_buttons.dart';
import 'package:life_partner_again/screens/public_web/widgets/responsive_web_container.dart';

class AppDownloadPromotion extends StatelessWidget {
  final bool visible;
  final AppDownloadAudience audience;
  final VoidCallback onDismiss;

  const AppDownloadPromotion({
    super.key,
    required this.visible,
    required this.audience,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: onDismiss,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: ColoredBox(color: Colors.black.withValues(alpha: 0.4)),
                ),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Focus(
                      autofocus: visible,
                      onKeyEvent: (node, event) {
                        if (event.logicalKey == LogicalKeyboardKey.escape) {
                          onDismiss();
                          return KeyEventResult.handled;
                        }
                        return KeyEventResult.ignored;
                      },
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(end: visible ? 1 : 0),
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, (1 - value) * 20),
                            child: Transform.scale(
                              scale: 0.95 + (0.05 * value),
                              child: child,
                            ),
                          );
                        },
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: SizedBox(
                            width: 1000, // Fixed width for consistent side-by-side layout
                            child: _PromotionHeroCard(
                              audience: audience,
                              onDismiss: onDismiss,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PromotionHeroCard extends StatelessWidget {
  final AppDownloadAudience audience;
  final VoidCallback onDismiss;

  const _PromotionHeroCard({
    required this.audience,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 32,
      color: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFF3F3F), // Primary
                Color(0xFFD63434), // Primary Dark
              ],
            ),
          ),
          child: Stack(
            children: [
              // Subtle abstract background shapes
              Positioned(
                top: -100,
                right: -50,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
              ),
              Positioned(
                bottom: -150,
                left: -100,
                child: Container(
                  width: 500,
                  height: 500,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.04),
                  ),
                ),
              ),

              // Close button
              Positioned(
                top: 20,
                right: 20,
                child: IconButton(
                  icon: const Icon(
                    LucideIcons.x,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: onDismiss,
                  tooltip: 'Close',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.1),
                    hoverColor: Colors.black.withValues(alpha: 0.2),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(56),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 11,
                      child: _PromotionContentSide(
                        audience: audience,
                        onDismiss: onDismiss,
                      ),
                    ),
                    const SizedBox(width: 48),
                    const Expanded(flex: 9, child: _PromotionImageSide()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromotionContentSide extends StatelessWidget {
  final AppDownloadAudience audience;
  final VoidCallback onDismiss;

  const _PromotionContentSide({
    required this.audience,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mode = audience == AppDownloadAudience.android
        ? DownloadButtonsMode.playStoreOnly
        : audience == AppDownloadAudience.ios
        ? DownloadButtonsMode.appStoreOnly
        : DownloadButtonsMode.both;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.asset(
                'assets/icons/app_logo.png',
                width: 40,
                height: 40,
                errorBuilder: (context, error, stackTrace) => Icon(
                  LucideIcons.heart,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Life Partner Again',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
        RichText(
          text: TextSpan(
            style: theme.textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
            children: const [
              TextSpan(text: 'A better way\nto find your\n'),
              TextSpan(
                text: 'life partner',
                style: TextStyle(color: Color(0xFFFFD185)), // Soft yellow/gold
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Trusted by thousands.\nDesigned for you.',
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white.withValues(alpha: 0.95),
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 36),
        const _BenefitItem(
          icon: LucideIcons.shield_check,
          text: 'Verified profiles you can trust',
        ),
        const _BenefitItem(
          icon: LucideIcons.message_square_text,
          text: 'Secure in-app messaging',
        ),
        const _BenefitItem(
          icon: LucideIcons.aperture,
          text: 'Advanced matching',
        ),
        const _BenefitItem(
          icon: LucideIcons.lock,
          text: 'Your privacy, our priority',
        ),
        const SizedBox(height: 48),
        DownloadAppButtons(
          mode: mode,
          compact: false,
          alignment: WrapAlignment.start,
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: onDismiss,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white.withValues(alpha: 0.75),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              'Maybe Later',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BenefitItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.95),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromotionImageSide extends StatelessWidget {
  const _PromotionImageSide();

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 1.45, // Increases the image size by 45%
      alignment: Alignment.centerRight, // Keeps it anchored to the right side
      child: Image.asset(
        'assets/images/promotion.png',
        fit: BoxFit.contain, // Prevents the image from stretching/distorting
        errorBuilder: (context, error, stackTrace) {
          return const SizedBox(
            height: 800,
            child: Center(
              child: Icon(LucideIcons.image, color: Colors.white54, size: 64),
            ),
          );
        },
      ),
    );
  }
}
