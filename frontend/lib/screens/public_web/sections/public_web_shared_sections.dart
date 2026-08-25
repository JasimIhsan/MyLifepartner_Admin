import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:life_partner_again/screens/public_web/widgets/download_app_buttons.dart';
import 'package:life_partner_again/screens/public_web/widgets/responsive_web_container.dart';
import 'package:life_partner_again/screens/public_web/widgets/web_section_header.dart';

class PublicWebSection extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final double topPadding;
  final double bottomPadding;
  final double maxWidth;
  final double? minHeight;

  const PublicWebSection({
    super.key,
    required this.child,
    this.backgroundColor,
    this.topPadding = 72,
    this.bottomPadding = 72,
    this.maxWidth = 1400,
    this.minHeight,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = ResponsiveWebContainer(
      maxWidth: maxWidth,
      child: Padding(
        padding: EdgeInsets.only(top: topPadding, bottom: bottomPadding),
        child: child,
      ),
    );

    if (minHeight != null) {
      content = ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight!),
        child: Center(child: content),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).colorScheme.surface,
      ),
      child: content,
    );
  }
}

class PublicHeroSection extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String titleHighlight;
  final String body;
  final String imageAsset;
  final Widget? actions;
  final List<String> highlights;
  final bool fullHeight;

  const PublicHeroSection({
    super.key,
    required this.eyebrow,
    required this.title,
    this.titleHighlight = '',
    required this.body,
    required this.imageAsset,
    this.actions,
    this.highlights = const [],
    this.fullHeight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final minHeroHeight = fullHeight
        ? (screenHeight - 66).clamp(520.0, double.infinity)
        : null;

    final bg = theme.brightness == Brightness.dark
        ? theme.canvasColor
        : const Color(0xFFFFFBFB);

    Widget content = LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 860;

        final textCol = _HeroText(
          eyebrow: eyebrow,
          title: title,
          titleHighlight: titleHighlight,
          body: body,
          actions: actions,
          highlights: highlights,
        );

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              textCol,
              const SizedBox(height: 48),
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  imageAsset,
                  width: double.infinity,
                  height: 380,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
            ],
          );
        }

        final mosaic = _HeroImageMosaic(backgroundColor: bg);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(flex: 10, child: textCol),
            const SizedBox(width: 48),
            Expanded(flex: 11, child: mosaic),
          ],
        );
      },
    );

    if (minHeroHeight != null) {
      content = ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeroHeight),
        child: Center(child: content),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(color: bg),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -150,
            top: -100,
            child: CustomPaint(
              size: const Size(600, 600),
              painter: _BlobPainter(
                color: theme.colorScheme.primary.withValues(alpha: 0.04),
              ),
            ),
          ),
          ResponsiveWebContainer(
            maxWidth: 1460,
            child: Padding(
              padding: EdgeInsets.only(
                top: fullHeight ? 32 : 56,
                bottom: fullHeight ? 32 : 68,
              ),
              child: content,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroText extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String titleHighlight;
  final String body;
  final Widget? actions;
  final List<String> highlights;

  const _HeroText({
    required this.eyebrow,
    required this.title,
    required this.titleHighlight,
    required this.body,
    required this.actions,
    required this.highlights,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final titleStyle =
        (width < 620
                ? theme.textTheme.displaySmall
                : theme.textTheme.displayMedium)
            ?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.08,
              letterSpacing: 0,
            );

    // Build title as RichText with highlighted portion in primary color
    Widget titleWidget;
    if (titleHighlight.isNotEmpty && title.contains(titleHighlight)) {
      final parts = title.split(titleHighlight);
      titleWidget = Text.rich(
        TextSpan(
          style: titleStyle,
          children: [
            TextSpan(text: parts.first),
            TextSpan(
              text: titleHighlight,
              style: titleStyle?.copyWith(color: theme.colorScheme.primary),
            ),
            if (parts.length > 1)
              TextSpan(text: parts.sublist(1).join(titleHighlight)),
          ],
        ),
      );
    } else {
      titleWidget = Text(title, style: titleStyle);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Eyebrow with decorative line
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 32, height: 2, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Text(
              eyebrow.toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Title with highlighted phrase
        titleWidget,

        const SizedBox(height: 16),

        // Body
        Text(
          body,
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.6,
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.70),
          ),
        ),

        if (actions != null) ...[const SizedBox(height: 40), actions!],

        if (highlights.isNotEmpty) ...[
          const SizedBox(height: 40),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final item in highlights)
                Builder(
                  builder: (context) {
                    IconData icon = LucideIcons.sparkles;
                    final lower = item.toLowerCase();
                    if (lower.contains('verif')) {
                      icon = LucideIcons.shield_check;
                    } else if (lower.contains('privac')) {
                      icon = LucideIcons.lock;
                    } else if (lower.contains('match')) {
                      icon = LucideIcons.heart;
                    } else if (lower.contains('canada')) {
                      icon = LucideIcons.map_pin;
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.08,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.15,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon,
                            color: theme.colorScheme.primary,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            item,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ],

        // Social proof row
        const SizedBox(height: 28),
        // _HeroSocialProof(theme: theme),
      ],
    );
  }
}

class _HeroImageMosaic extends StatelessWidget {
  final Color backgroundColor;

  const _HeroImageMosaic({required this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return AspectRatio(
      aspectRatio: 1.15,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          // Dimensions for the dynamic layout
          final mainW = w * 0.45;
          final mainH = h * 0.60;

          final trW = w * 0.32;
          final trH = h * 0.38;

          final cardW = w * 0.36;
          final cardH = cardW;

          final botW = w * 0.28;
          final botH = h * 0.24;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Background soft blob
              Positioned(
                left: -w * 0.05,
                top: -h * 0.05,
                child: CustomPaint(
                  size: Size(w * 1.1, h * 1.1),
                  painter: _BlobPainter(color: primary.withValues(alpha: 0.08)),
                ),
              ),

              // Plus Grid - Top Right
              Positioned(
                right: -15,
                top: h * 0.15,
                child: CustomPaint(
                  size: Size(w * 0.15, h * 0.3),
                  painter: _PlusGridPainter(
                    color: primary.withValues(alpha: 0.3),
                  ),
                ),
              ),

              // Plus Grid - Bottom Center
              Positioned(
                right: w * 0.15,
                bottom: -20,
                child: CustomPaint(
                  size: Size(w * 0.2, h * 0.15),
                  painter: _PlusGridPainter(
                    color: primary.withValues(alpha: 0.3),
                  ),
                ),
              ),

              // Top Right Image
              Positioned(
                right: w * 0.08,
                top: h * 0.02,
                width: trW,
                height: trH,
                child: const _MosaicImage(
                  asset: 'assets/images/landing_couple_1.png',
                  borderRadius: 24,
                ),
              ),

              // Main Image (Center Left)
              Positioned(
                left: w * 0.08,
                top: h * 0.15,
                width: mainW,
                height: mainH,
                child: const _MosaicImage(
                  asset: 'assets/images/landing_couple.png',
                  borderRadius: 24,
                ),
              ),

              // Pink Connection Card
              Positioned(
                right: w * 0.04,
                top: h * 0.44,
                width: cardW,
                height: cardH,
                child: _ConnectionCard(primary: primary, theme: theme),
              ),

              // Bottom Center Image
              Positioned(
                left: w * 0.30,
                bottom: h * 0.05,
                width: botW,
                height: botH,
                child: const _MosaicImage(
                  asset: 'assets/images/landing_couple_3.png',
                  borderRadius: 16,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MosaicImage extends StatelessWidget {
  final String asset;
  final double borderRadius;

  const _MosaicImage({required this.asset, this.borderRadius = 16});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          errorBuilder: (context, error, stackTrace) => ColoredBox(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.07),
          ),
        ),
      ),
    );
  }
}

class _ConnectionCard extends StatelessWidget {
  final Color primary;
  final ThemeData theme;

  const _ConnectionCard({required this.primary, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(primary, Colors.white, 0.3) ?? primary, primary],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background decorative icon
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(
              LucideIcons.heart_handshake,
              size: 80,
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.heart, color: primary, size: 16),
                ),
                const Spacer(),
                Text(
                  'Made for\nmeaningful\nconnections',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  final Color color;
  const _BlobPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);

    final path = Path();
    path.moveTo(size.width * 0.2, size.height * 0.2);
    path.quadraticBezierTo(
      size.width * 0.6,
      0,
      size.width * 0.8,
      size.height * 0.2,
    );
    path.quadraticBezierTo(
      size.width,
      size.height * 0.5,
      size.width * 0.8,
      size.height * 0.8,
    );
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height,
      size.width * 0.2,
      size.height * 0.8,
    );
    path.quadraticBezierTo(
      0,
      size.height * 0.5,
      size.width * 0.2,
      size.height * 0.2,
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BlobPainter old) => old.color != color;
}

class _PlusGridPainter extends CustomPainter {
  final Color color;
  const _PlusGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    const cols = 4;
    const rows = 6;
    final xStep = size.width / (cols - 1);
    final yStep = size.height / (rows - 1);
    const halfLen = 3.5;

    for (int c = 0; c < cols; c++) {
      for (int r = 0; r < rows; r++) {
        final cx = c * xStep;
        final cy = r * yStep;
        canvas.drawLine(
          Offset(cx - halfLen, cy),
          Offset(cx + halfLen, cy),
          paint,
        );
        canvas.drawLine(
          Offset(cx, cy - halfLen),
          Offset(cx, cy + halfLen),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PlusGridPainter old) => old.color != color;
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
  final String? body;
  final List<LegalContentBlock>? blocks;
  final String? markdownContent;

  const LegalContentSection({
    super.key,
    required this.title,
    this.body,
    this.blocks,
    this.markdownContent,
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
          if (markdownContent != null)
            MarkdownBody(
              data: markdownContent!,
              styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                p: theme.textTheme.bodyLarge?.copyWith(height: 1.7),
                h1: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1.4,
                ),
                h2: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1.4,
                ),
                h3: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1.4,
                ),
                listBullet: theme.textTheme.bodyLarge?.copyWith(height: 1.7),
              ),
            ),
          if (blocks != null)
            for (final block in blocks!) ...[
              if (block.title.isNotEmpty) ...[
                Text(
                  block.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
              ],
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
