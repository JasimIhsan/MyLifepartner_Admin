import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:life_partner_again/screens/public_web/widgets/download_app_buttons.dart';
import 'package:life_partner_again/screens/public_web/widgets/responsive_web_container.dart';
import 'package:life_partner_again/screens/public_web/widgets/web_section_header.dart';

class PublicWebSection extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final double topPadding;
  final double bottomPadding;
  final double maxWidth;

  const PublicWebSection({
    super.key,
    required this.child,
    this.backgroundColor,
    this.topPadding = 72,
    this.bottomPadding = 72,
    this.maxWidth = 1400,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).colorScheme.surface,
      ),
      child: ResponsiveWebContainer(
        maxWidth: maxWidth,
        child: Padding(
          padding: EdgeInsets.only(top: topPadding, bottom: bottomPadding),
          child: child,
        ),
      ),
    );
  }
}

class PublicHeroSection extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String body;
  final String imageAsset;
  final Widget? actions;
  final List<String> highlights;

  const PublicHeroSection({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.imageAsset,
    this.actions,
    this.highlights = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PublicWebSection(
      topPadding: 56,
      bottomPadding: 68,
      maxWidth: 1460,
      backgroundColor: theme.brightness == Brightness.dark
          ? theme.scaffoldBackgroundColor
          : const Color(0xFFFFFBFB),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 860;
          final text = _HeroText(
            eyebrow: eyebrow,
            title: title,
            body: body,
            actions: actions,
            highlights: highlights,
          );
          final image = _HeroImage(imageAsset: imageAsset);

          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [text, const SizedBox(height: 34), image],
            );
          }

          return Row(
            children: [
              Expanded(flex: 11, child: text),
              const SizedBox(width: 56),
              Expanded(flex: 9, child: image),
            ],
          );
        },
      ),
    );
  }
}

class _HeroText extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String body;
  final Widget? actions;
  final List<String> highlights;

  const _HeroText({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.actions,
    required this.highlights,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final titleStyle = width < 620
        ? theme.textTheme.displaySmall
        : theme.textTheme.displayMedium;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          style: titleStyle?.copyWith(
            fontWeight: FontWeight.w900,
            height: 1.05,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          body,
          style: theme.textTheme.titleMedium?.copyWith(
            height: 1.6,
            color: theme.textTheme.bodyMedium?.color,
          ),
        ),
        if (actions != null) ...[const SizedBox(height: 30), actions!],
        if (highlights.isNotEmpty) ...[
          const SizedBox(height: 30),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final item in highlights)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.check,
                        color: theme.colorScheme.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        item,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _HeroImage extends StatelessWidget {
  final String imageAsset;

  const _HeroImage({required this.imageAsset});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isProductVisual =
        imageAsset.startsWith('profile_sample') ||
        imageAsset.startsWith('flutter_');

    if (isProductVisual) {
      return const _ProductHeroVisual();
    }

    return AspectRatio(
      aspectRatio: 0.92,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              imageAsset,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (context, error, stackTrace) => Container(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                child: Icon(
                  LucideIcons.image_off,
                  color: theme.colorScheme.primary,
                  size: 42,
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductHeroVisual extends StatelessWidget {
  const _ProductHeroVisual();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 560;

        return AspectRatio(
          aspectRatio: 1.04,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.dividerColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 34,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/landing_couple_1.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      errorBuilder: (context, error, stackTrace) => ColoredBox(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.06,
                        ),
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          theme.colorScheme.surface.withValues(alpha: 0.92),
                          theme.colorScheme.surface.withValues(alpha: 0.72),
                          theme.colorScheme.surface.withValues(alpha: 0.04),
                        ],
                      ),
                    ),
                  ),
                  if (!isCompact)
                    Positioned(
                      left: 24,
                      bottom: 24,
                      width: 210,
                      child: _HeroTrustPanel(theme: theme),
                    ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FractionallySizedBox(
                      widthFactor: isCompact ? 0.64 : 0.54,
                      heightFactor: 0.9,
                      child: _PhoneScreenshot(asset: 'profile_sample_2.png'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeroTrustPanel extends StatelessWidget {
  final ThemeData theme;

  const _HeroTrustPanel({required this.theme});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.shield_check,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(height: 12),
            Text(
              'Verified, private, intentional',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Profile review, safer messaging, and controls before contact sharing.',
              style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhoneScreenshot extends StatelessWidget {
  final String asset;

  const _PhoneScreenshot({required this.asset});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.black, width: 6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          errorBuilder: (context, error, stackTrace) => ColoredBox(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
          ),
        ),
      ),
    );
  }
}

class PublicDownloadCtaSection extends StatelessWidget {
  final String title;
  final String body;

  const PublicDownloadCtaSection({
    super.key,
    this.title = 'Ready to begin with intention?',
    this.body =
        'Download Life Partner Again and continue your journey inside the full mobile app experience.',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PublicWebSection(
      topPadding: 56,
      bottomPadding: 56,
      maxWidth: 1400,
      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.06),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 760;
          final content = Column(
            crossAxisAlignment: isMobile
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                body,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.55),
              ),
            ],
          );

          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                content,
                const SizedBox(height: 22),
                const DownloadAppButtons(),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: content),
              const SizedBox(width: 32),
              const DownloadAppButtons(alignment: WrapAlignment.end),
            ],
          );
        },
      ),
    );
  }
}

class PublicSimpleGrid extends StatelessWidget {
  final List<Widget> children;
  final double minTileWidth;
  final double spacing;

  const PublicSimpleGrid({
    super.key,
    required this.children,
    this.minTileWidth = 260,
    this.spacing = 18,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = (constraints.maxWidth / minTileWidth)
            .floor()
            .clamp(1, 4)
            .toInt();
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(
                width: (constraints.maxWidth - (spacing * (count - 1))) / count,
                child: child,
              ),
          ],
        );
      },
    );
  }
}

class PublicBulletList extends StatelessWidget {
  final List<String> items;

  const PublicBulletList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  LucideIcons.circle_check,
                  color: theme.colorScheme.primary,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class EditorialQuote extends StatelessWidget {
  final String body;
  final String attribution;

  const EditorialQuote({
    super.key,
    required this.body,
    required this.attribution,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: theme.colorScheme.primary, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LucideIcons.quote,
            color: theme.colorScheme.primary.withValues(alpha: 0.7),
            size: 30,
          ),
          const SizedBox(height: 16),
          Text(
            body,
            style: theme.textTheme.titleLarge?.copyWith(
              height: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            attribution,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class LegalContentSection extends StatelessWidget {
  final String title;
  final String body;
  final List<LegalContentBlock> blocks;

  const LegalContentSection({
    super.key,
    required this.title,
    required this.body,
    required this.blocks,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PublicWebSection(
      topPadding: 58,
      maxWidth: 920,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WebSectionHeader(
            eyebrow: 'Legal',
            title: title,
            body: body,
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 42),
          for (final block in blocks) ...[
            Text(
              block.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              block.body,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.7),
            ),
            const SizedBox(height: 28),
          ],
        ],
      ),
    );
  }
}

class LegalContentBlock {
  final String title;
  final String body;

  const LegalContentBlock({required this.title, required this.body});
}
