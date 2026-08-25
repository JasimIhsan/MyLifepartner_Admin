import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:life_partner_again/screens/public_web/services/app_download_promotion_service.dart';
import 'package:life_partner_again/screens/public_web/widgets/download_app_buttons.dart';

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
            Center(
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
                    // ConstrainedBox sets a maximum width for large screens.
                    // SingleChildScrollView allows the card to scroll if the
                    // screen is too small (e.g., in landscape on mobile).
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: SingleChildScrollView(
                        child: _PromotionHeroCard(
                          audience: audience,
                          onDismiss: onDismiss,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
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

  const _PromotionHeroCard({required this.audience, required this.onDismiss});

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

              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 768;

                  if (isWide) {
                    return Padding(
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
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                    child: _PromotionContentSide(
                      audience: audience,
                      onDismiss: onDismiss,
                      isMobile: true,
                    ),
                  );
                },
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
  final bool isMobile;

  const _PromotionContentSide({
    super.key,
    required this.audience,
    required this.onDismiss,
    this.isMobile = false,
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
              padding: EdgeInsets.all(isMobile ? 4 : 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.asset(
                'assets/icons/app_logo.png',
                width: isMobile ? 24 : 40,
                height: isMobile ? 24 : 40,
                errorBuilder: (context, error, stackTrace) => Icon(
                  LucideIcons.heart,
                  color: theme.colorScheme.primary,
                  size: isMobile ? 16 : 24,
                ),
              ),
            ),
            SizedBox(width: isMobile ? 8 : 12),
            Text(
              'Life Partner Again',
              style:
                  (isMobile
                          ? theme.textTheme.titleSmall
                          : theme.textTheme.titleMedium)
                      ?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 24 : 40),
        RichText(
          text: TextSpan(
            style:
                (isMobile
                        ? theme.textTheme.headlineMedium
                        : theme.textTheme.displaySmall)
                    ?.copyWith(
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
        SizedBox(height: isMobile ? 12 : 16),
        Text(
          'Trusted by thousands.\nDesigned for you.',
          style:
              (isMobile
                      ? theme.textTheme.titleMedium
                      : theme.textTheme.titleLarge)
                  ?.copyWith(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
        ),
        SizedBox(height: isMobile ? 24 : 36),
        _BenefitItem(
          icon: LucideIcons.shield_check,
          text: 'Verified profiles you can trust',
          isMobile: isMobile,
        ),
        _BenefitItem(
          icon: LucideIcons.message_square_text,
          text: 'Secure in-app messaging',
          isMobile: isMobile,
        ),
        _BenefitItem(
          icon: LucideIcons.aperture,
          text: 'Advanced matching',
          isMobile: isMobile,
        ),
        _BenefitItem(
          icon: LucideIcons.lock,
          text: 'Your privacy, our priority',
          isMobile: isMobile,
        ),
        SizedBox(height: isMobile ? 32 : 48),
        DownloadAppButtons(
          mode: mode,
          compact: isMobile,
          alignment: WrapAlignment.start,
        ),
        SizedBox(height: isMobile ? 16 : 24),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: onDismiss,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white.withValues(alpha: 0.75),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 8 : 16,
                vertical: 8,
              ),
            ),
            child: Text(
              'Maybe Later',
              style: TextStyle(
                fontSize: isMobile ? 14 : 15,
                fontWeight: FontWeight.w500,
              ),
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
  final bool isMobile;

  const _BenefitItem({
    super.key,
    required this.icon,
    required this.text,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 12 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 6 : 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: isMobile ? 16 : 20),
          ),
          SizedBox(width: isMobile ? 12 : 16),
          Expanded(
            child: Text(
              text,
              style:
                  (isMobile
                          ? theme.textTheme.titleSmall
                          : theme.textTheme.titleMedium)
                      ?.copyWith(
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
  const _PromotionImageSide({super.key});

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
