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
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: onDismiss,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.26),
                  ),
                ),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = PublicWebBreakpoints.isMobile(
                  constraints.maxWidth,
                );
                final cardWidth = (constraints.maxWidth - 32).clamp(
                  280.0,
                  isMobile ? 560.0 : 660.0,
                );
                final maxHeight = constraints.maxHeight > 64
                    ? constraints.maxHeight - 32
                    : constraints.maxHeight;

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
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, (1 - value) * 18),
                            child: Transform.scale(
                              scale: 0.96 + (0.04 * value),
                              child: child,
                            ),
                          );
                        },
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: maxHeight),
                          child: SingleChildScrollView(
                            child: SizedBox(
                              width: cardWidth.toDouble(),
                              child: _PromotionCard(
                                audience: audience,
                                isMobile: isMobile,
                                onDismiss: onDismiss,
                              ),
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

class _PromotionCard extends StatelessWidget {
  final AppDownloadAudience audience;
  final bool isMobile;
  final VoidCallback onDismiss;

  const _PromotionCard({
    required this.audience,
    required this.isMobile,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = _contentForAudience(audience);

    return Material(
      elevation: 24,
      color: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 18 : 22),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.dividerColor),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 570;
            final body = _PromotionBody(
              content: content,
              isMobile: isMobile,
              onDismiss: onDismiss,
            );

            if (!isWide) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PromotionHeader(onDismiss: onDismiss),
                  const SizedBox(height: 18),
                  body,
                ],
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PromotionHeader(onDismiss: onDismiss),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: 204, child: _PromotionVisual()),
                    const SizedBox(width: 24),
                    Expanded(child: body),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  _PromotionContent _contentForAudience(AppDownloadAudience audience) {
    switch (audience) {
      case AppDownloadAudience.android:
        return const _PromotionContent(
          title: 'Meet serious people inside the LPA app.',
          body:
              'Get the full Life Partner Again experience with verified profiles, private discovery, and safer messaging.',
          mode: DownloadButtonsMode.playStoreOnly,
        );
      case AppDownloadAudience.ios:
        return const _PromotionContent(
          title: 'Life Partner Again is better in the app.',
          body:
              'Create your profile, complete verification, and continue your next chapter from your phone.',
          mode: DownloadButtonsMode.appStoreOnly,
        );
      case AppDownloadAudience.desktop:
        return const _PromotionContent(
          title: 'Continue your journey on mobile.',
          body:
              'Choose the store for your phone and explore LPA with registration, verification, matching, and messaging in one place.',
          mode: DownloadButtonsMode.both,
        );
    }
  }
}

class _PromotionHeader extends StatelessWidget {
  final VoidCallback onDismiss;

  const _PromotionHeader({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Image.asset(
          'assets/icons/app_logo.png',
          width: 38,
          height: 38,
          errorBuilder: (context, error, stackTrace) =>
              Icon(LucideIcons.heart, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            'Life Partner Again',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Close download suggestion',
          icon: const Icon(LucideIcons.x, size: 19),
          onPressed: onDismiss,
        ),
      ],
    );
  }
}

class _PromotionVisual extends StatelessWidget {
  const _PromotionVisual();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AspectRatio(
      aspectRatio: 0.68,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black, width: 5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 22,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.asset(
            'profile_sample.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (context, error, stackTrace) => ColoredBox(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
            ),
          ),
        ),
      ),
    );
  }
}

class _PromotionBody extends StatelessWidget {
  final _PromotionContent content;
  final bool isMobile;
  final VoidCallback onDismiss;

  const _PromotionBody({
    required this.content,
    required this.isMobile,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          content.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            height: 1.14,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          content.body,
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.52),
        ),
        const SizedBox(height: 16),
        const _ModalBenefit(
          icon: LucideIcons.scan_face,
          text: 'Selfie verification and profile review',
        ),
        const _ModalBenefit(
          icon: LucideIcons.message_square_lock,
          text: 'Private in-app messaging before sharing contact details',
        ),
        const _ModalBenefit(
          icon: LucideIcons.shield_check,
          text: 'Report, block, and privacy controls',
        ),
        const SizedBox(height: 18),
        DownloadAppButtons(
          mode: content.mode,
          compact: true,
          alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
        ),
        const SizedBox(height: 10),
        Align(
          alignment: isMobile ? Alignment.center : Alignment.centerLeft,
          child: TextButton(
            onPressed: onDismiss,
            child: const Text('Maybe Later'),
          ),
        ),
      ],
    );
  }
}

class _ModalBenefit extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ModalBenefit({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 17),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromotionContent {
  final String title;
  final String body;
  final DownloadButtonsMode mode;

  const _PromotionContent({
    required this.title,
    required this.body,
    required this.mode,
  });
}
