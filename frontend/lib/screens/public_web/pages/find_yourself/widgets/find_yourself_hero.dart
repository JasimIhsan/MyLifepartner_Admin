import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:life_partner_again/screens/public_web/widgets/responsive_web_container.dart';

class FindYourselfHero extends StatefulWidget {
  const FindYourselfHero({super.key});

  @override
  State<FindYourselfHero> createState() => _FindYourselfHeroState();
}

class _FindYourselfHeroState extends State<FindYourselfHero>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = PublicWebBreakpoints.isMobile(width);

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      color: theme.canvasColor,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ResponsiveWebContainer(
            maxWidth: 1200,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 24.0 : 40.0,
              vertical: isMobile ? 80.0 : 120.0,
            ),
            child: isMobile
                ? _buildMobileLayout(context)
                : _buildDesktopLayout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTextContent(BuildContext context, bool isMobile) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Tagline
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.sparkles,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'YOUR JOURNEY STARTS WITHIN',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        // Headline
        Text(
          'Find yourself before finding your partner again.',
          style:
              (isMobile
                      ? theme.textTheme.displaySmall
                      : theme.textTheme.displayMedium)
                  ?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                    letterSpacing: -1,
                  ),
        ),
        const SizedBox(height: 24),
        // Subtitle
        Text(
          'Self-awareness is the foundation of a healthy relationship. We help you reflect on your readiness, values, and expectations before you rush into a new connection.',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 48),
        // Feature Badges
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildGlassBadge(context, 'Guided Reflection', LucideIcons.compass),
            _buildGlassBadge(context, 'Emotional Clarity', LucideIcons.brain),
            _buildGlassBadge(
              context,
              'Better Matches',
              LucideIcons.heart_handshake,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGlassBadge(BuildContext context, String text, IconData icon) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Text(
                text,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: theme.canvasColor,
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            Image.asset(
              'assets/images/onboarding/emotional_readiness.png',
              fit: BoxFit.cover,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        _buildTextContent(context, true),
        const SizedBox(height: 64),
        _buildImage(context),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(flex: 6, child: _buildTextContent(context, false)),
        const SizedBox(width: 80),
        Expanded(flex: 5, child: _buildImage(context)),
      ],
    );
  }
}
