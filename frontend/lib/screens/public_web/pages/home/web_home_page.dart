import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';
import 'package:life_partner_again/screens/public_web/public_web_routes.dart';
import 'package:life_partner_again/screens/public_web/sections/public_web_shared_sections.dart';
import 'package:life_partner_again/screens/public_web/widgets/download_app_buttons.dart';
import 'package:life_partner_again/screens/public_web/widgets/web_feature_card.dart';
import 'package:life_partner_again/screens/public_web/widgets/web_section_header.dart';

class WebHomePage extends StatelessWidget {
  const WebHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        const PublicHeroSection(
          fullHeight: true,
          eyebrow: 'Life Partner Again',
          title: 'Because every\nnew beginning\ndeserves the\nright partner.',
          titleHighlight: 'right partner.',
          body: 'Thoughtful matches. Verified members. Serious relationships.',
          imageAsset: 'assets/images/landing_couple.png',
          actions: DownloadAppButtons(),
          highlights: [
            'Built in Canada',
            'Verified profiles',
            'Privacy-first controls',
          ],
        ),
        // PublicWebSection(
        //   topPadding: 38,
        //   bottomPadding: 42,
        //   backgroundColor: theme.colorScheme.surface,
        //   child: const _TrustBand(),
        // ),
        PublicWebSection(
          backgroundColor: theme.brightness == Brightness.dark
              ? theme.scaffoldBackgroundColor
              : const Color(0xFFF7F8F8),
          child: const _WhyLpaStory(),
        ),
        const PublicWebSection(child: _FeatureShowcase()),
        PublicWebSection(
          backgroundColor: theme.brightness == Brightness.dark
              ? theme.scaffoldBackgroundColor
              : const Color(0xFFFFFBFB),
          child: const _JourneySection(),
        ),
        const PublicWebSection(child: _PreviewGatewaySection()),
        PublicWebSection(
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.06),
          child: const _AppContextSection(),
        ),
      ],
    );
  }
}

class _WhyLpaStory extends StatelessWidget {
  const _WhyLpaStory();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;
        final text = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const WebSectionHeader(
              eyebrow: 'Why LPA',
              title: 'A calmer way to search for something lasting.',
              body:
                  'Many people come back to relationships with more self-knowledge, more responsibilities, and less patience for shallow discovery. LPA is built for that reality.',
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 40),
            const _WhyLpaFeature(
              icon: LucideIcons.user,
              title: 'Thoughtful Profiles',
              body:
                  'Create a thoughtful profile before starting discovery to ensure intent.',
            ),
            const _WhyLpaFeature(
              icon: LucideIcons.shield_check,
              title: 'Paced Discovery',
              body:
                  'Use verification and privacy controls to move at your pace safely.',
            ),
            const _WhyLpaFeature(
              icon: LucideIcons.search,
              title: 'Intentional Matching',
              body:
                  'Discover people through shared intent and values, not endless casual swipes.',
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.go(PublicWebRoutes.about),
              icon: const Icon(LucideIcons.arrow_right, size: 18),
              label: const Text('Learn about LPA'),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        );

        final image = Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: AspectRatio(
                  aspectRatio: 0.85,
                  child: Image.asset(
                    'assets/images/landing_couple_2.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -20,
              left: -30,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.heart_handshake,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meaningful',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Connections only',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              text,
              const SizedBox(height: 60),
              Padding(padding: const EdgeInsets.only(left: 30), child: image),
            ],
          );
        }

        return Row(
          children: [
            Expanded(flex: 10, child: text),
            const SizedBox(width: 80),
            Expanded(
              flex: 9,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20, left: 30),
                child: image,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _WhyLpaFeature extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _WhyLpaFeature({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: theme.textTheme.bodyMedium?.color?.withValues(
                      alpha: 0.8,
                    ),
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

class _FeatureShowcase extends StatelessWidget {
  const _FeatureShowcase();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        WebSectionHeader(
          eyebrow: 'What Makes LPA Different',
          title: 'The relationship tools sit around trust, not noise.',
          body:
              'Core product features support registration, verification, discovery, communication, safety, privacy, and membership without turning the journey into a game.',
        ),
        SizedBox(height: 38),
        _PrimaryFeatureGrid(),
        SizedBox(height: 22),
        PublicSimpleGrid(
          minTileWidth: 280,
          children: [
            WebFeatureCard(
              compact: true,
              icon: LucideIcons.video,
              title: 'Voice & Video Calling',
              body:
                  'Move from text to a more natural conversation when both people are ready.',
            ),
            WebFeatureCard(
              compact: true,
              icon: LucideIcons.lock_keyhole,
              title: 'Privacy Controls',
              body:
                  'Manage profile visibility and keep personal contact details private.',
            ),
            WebFeatureCard(
              compact: true,
              icon: LucideIcons.map_pin,
              title: 'Canadian Community',
              body:
                  'A serious relationship platform positioned for people in Canada.',
            ),
            WebFeatureCard(
              compact: true,
              icon: LucideIcons.gem,
              title: 'Premium Members',
              body:
                  'Membership helps support a more committed community with fewer distractions.',
            ),
          ],
        ),
      ],
    );
  }
}

class _PrimaryFeatureGrid extends StatelessWidget {
  const _PrimaryFeatureGrid();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth < 900 ? 1 : 3;
        final spacing = constraints.maxWidth < 900 ? 16.0 : 20.0;
        const panels = [
          _PrimaryFeaturePanel(
            icon: LucideIcons.brain_circuit,
            title: 'AI Assisted Matching',
            body:
                'Matching support helps surface people who may align with your values, preferences, and relationship goals.',
            detail: 'Preference signals, relationship intent, and discovery.',
          ),
          _PrimaryFeaturePanel(
            icon: LucideIcons.scan_face,
            title: 'Selfie Verification',
            body:
                'Verification steps help members approach the community with more confidence and less uncertainty.',
            detail: 'Identity trust before deeper connection.',
          ),
          _PrimaryFeaturePanel(
            icon: LucideIcons.message_square_lock,
            title: 'Safe Messaging',
            body:
                'Start conversations inside the app before sharing personal contact details too early.',
            detail: 'Report, block, and controlled communication.',
          ),
        ];

        final rows = <Widget>[];
        for (var i = 0; i < panels.length; i += count) {
          final rowPanels = panels.sublist(
            i,
            (i + count).clamp(0, panels.length),
          );
          final rowWidgets = <Widget>[];

          for (var j = 0; j < count; j++) {
            if (j < rowPanels.length) {
              rowWidgets.add(Expanded(child: rowPanels[j]));
            } else {
              rowWidgets.add(const Expanded(child: SizedBox.shrink()));
            }
            if (j < count - 1) {
              rowWidgets.add(SizedBox(width: spacing));
            }
          }

          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: rowWidgets,
              ),
            ),
          );
        }

        return Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              rows[i],
              if (i < rows.length - 1) SizedBox(height: spacing),
            ],
          ],
        );
      },
    );
  }
}

class _PrimaryFeaturePanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String detail;

  const _PrimaryFeaturePanel({
    required this.icon,
    required this.title,
    required this.body,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(minHeight: 260),
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 28),
          ),
          const SizedBox(height: 22),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.18,
            ),
          ),
          const SizedBox(height: 10),
          Text(body, style: theme.textTheme.bodyLarge?.copyWith(height: 1.55)),
          const SizedBox(height: 20),
          Text(
            detail,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneySection extends StatelessWidget {
  const _JourneySection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        WebSectionHeader(
          eyebrow: 'How The Journey Works',
          title: 'A paced path from self-understanding to connection.',
          body:
              'The app experience is designed to make members slow down just enough to be thoughtful without making the process feel heavy.',
        ),
        SizedBox(height: 34),
        _JourneySteps(),
      ],
    );
  }
}

class _JourneySteps extends StatelessWidget {
  const _JourneySteps();

  static const _steps = [
    _JourneyStepData(
      icon: LucideIcons.user_plus,
      title: 'Register',
      body: 'Create your account and begin a profile with real context.',
    ),
    _JourneyStepData(
      icon: LucideIcons.scan_face,
      title: 'Verify',
      body: 'Complete trust steps such as OTP and selfie verification.',
    ),
    _JourneyStepData(
      icon: LucideIcons.sparkles,
      title: 'Reflect',
      body: 'Use Find Yourself prompts to clarify readiness and values.',
    ),
    _JourneyStepData(
      icon: LucideIcons.search,
      title: 'Discover',
      body: 'Browse compatible profiles through preferences and intent.',
    ),
    _JourneyStepData(
      icon: LucideIcons.messages_square,
      title: 'Communicate',
      body: 'Start safely with messaging, voice, or video when ready.',
    ),
    _JourneyStepData(
      icon: LucideIcons.crown,
      title: 'Choose Access',
      body: 'Upgrade when premium tools match your relationship goals.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return PublicSimpleGrid(
      minTileWidth: 310,
      spacing: 16,
      children: [
        for (var index = 0; index < _steps.length; index++)
          _JourneyStep(number: index + 1, data: _steps[index]),
      ],
    );
  }
}

class _JourneyStepData {
  final IconData icon;
  final String title;
  final String body;

  const _JourneyStepData({
    required this.icon,
    required this.title,
    required this.body,
  });
}

class _JourneyStep extends StatelessWidget {
  final int number;
  final _JourneyStepData data;

  const _JourneyStep({required this.number, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number.toString().padLeft(2, '0'),
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(data.icon, color: theme.colorScheme.primary, size: 24),
                const SizedBox(height: 12),
                Text(
                  data.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  data.body,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewGatewaySection extends StatelessWidget {
  const _PreviewGatewaySection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const WebSectionHeader(
          eyebrow: 'Explore More',
          title: 'Three public pages explain the heart of the product.',
          body:
              'Find Yourself adds reflection, Safety & Trust explains protection, and Membership shows how free and premium access work together.',
        ),
        const SizedBox(height: 34),
        PublicSimpleGrid(
          minTileWidth: 330,
          children: [
            _PreviewPanel(
              icon: LucideIcons.sparkles,
              title: 'Find Yourself',
              body:
                  'Reflection prompts help members understand readiness, values, boundaries, and relationship expectations.',
              onTap: () => context.go(PublicWebRoutes.findYourself),
            ),
            _PreviewPanel(
              icon: LucideIcons.shield_check,
              title: 'Safety & Trust',
              body:
                  'Identity, conversations, community, and data protection are organized in one clear place.',
              onTap: () => context.go(PublicWebRoutes.safety),
            ),
            _PreviewPanel(
              icon: LucideIcons.crown,
              title: 'Membership',
              body:
                  'See how registration, founding member access, free membership, and premium tools fit together.',
              onTap: () => context.go(PublicWebRoutes.membership),
            ),
          ],
        ),
      ],
    );
  }
}

class _PreviewPanel extends StatefulWidget {
  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;

  const _PreviewPanel({
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
  });

  @override
  State<_PreviewPanel> createState() => _PreviewPanelState();
}

class _PreviewPanelState extends State<_PreviewPanel> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _isHovered ? -3 : 0, 0),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isHovered
                  ? theme.colorScheme.primary.withValues(alpha: 0.28)
                  : theme.dividerColor,
            ),
            boxShadow: [
              if (_isHovered)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(widget.icon, color: theme.colorScheme.primary, size: 30),
              const SizedBox(height: 18),
              Text(
                widget.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1.16,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.body,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.55),
              ),
              const SizedBox(height: 18),
              Text(
                'Explore page',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppContextSection extends StatelessWidget {
  const _AppContextSection();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;
        final text = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            WebSectionHeader(
              eyebrow: 'Why Download',
              title: 'The full relationship journey lives in the app.',
              body:
                  'The website explains the promise. The mobile app is where registration, verification, matching, discovery, communication, privacy, safety, and membership come together.',
              textAlign: TextAlign.left,
            ),
            SizedBox(height: 24),
            PublicBulletList(
              items: [
                'Register and verify with OTP and selfie checks.',
                'Create a fuller profile with preferences and context.',
                'Discover compatible people and communicate safely.',
                'Use premium tools when you are ready for deeper access.',
              ],
            ),
            SizedBox(height: 22),
            DownloadAppButtons(),
          ],
        );
        const visual = _ScreenshotRail();

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [text, const SizedBox(height: 32), visual],
          );
        }

        return Row(
          children: [
            Expanded(flex: 10, child: text),
            const SizedBox(width: 64),
            Expanded(flex: 8, child: visual),
          ],
        );
      },
    );
  }
}

class _ScreenshotRail extends StatelessWidget {
  const _ScreenshotRail();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 520;

        return SizedBox(
          height: isCompact ? 360 : 440,
          child: Stack(
            children: [
              Positioned(
                left: isCompact ? 0 : 24,
                top: isCompact ? 28 : 0,
                width: isCompact ? constraints.maxWidth * 0.54 : 220,
                bottom: 28,
                child: const _ScreenshotCard(
                  asset: 'assets/images/landing_couple_1.png',
                ),
              ),
              Positioned(
                right: 0,
                top: isCompact ? 0 : 36,
                width: isCompact ? constraints.maxWidth * 0.58 : 250,
                bottom: 0,
                child: const _ScreenshotCard(
                  asset: 'assets/images/landing_couple_3.png',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ScreenshotCard extends StatelessWidget {
  final String asset;

  const _ScreenshotCard({required this.asset});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black, width: 5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
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
