import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:life_partner_again/screens/public_web/widgets/responsive_web_container.dart';

class FindYourselfHero extends StatelessWidget {
  const FindYourselfHero({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = PublicWebBreakpoints.isMobile(width);

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.02),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background soft shapes for a calm atmosphere
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withValues(alpha: 0.03),
              ),
            ),
          ),
          ResponsiveWebContainer(
            maxWidth: 1200,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 25.0 : 40.0,
              vertical: isMobile ? 60.0 : 100.0,
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
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 32, height: 2, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Text(
              'FIND YOURSELF',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Find yourself before finding your partner again.',
          style:
              (isMobile
                      ? theme.textTheme.displaySmall
                      : theme.textTheme.displayMedium)
                  ?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                    letterSpacing: -0.5,
                  ),
        ),
        const SizedBox(height: 24),
        Text(
          'Self-awareness is one of LPA\'s important differentiators. The app helps people reflect on readiness, values, and relationship expectations before rushing into connection.',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 40),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildHighlightBadge(
              context,
              'Guided reflection',
              LucideIcons.compass,
            ),
            _buildHighlightBadge(
              context,
              'Better conversations',
              LucideIcons.messages_square,
            ),
            _buildHighlightBadge(
              context,
              'Emotional clarity',
              LucideIcons.brain,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHighlightBadge(
    BuildContext context,
    String text,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.black.withValues(alpha: 0.1),
        //     blurRadius: 30,
        //     offset: const Offset(0, 15),
        //   ),
        // ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.asset(
          'assets/images/onboarding/emotional_readiness.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        _buildTextContent(context, true),
        const SizedBox(height: 48),
        _buildImage(context),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(flex: 5, child: _buildTextContent(context, false)),
        const SizedBox(width: 64),
        Expanded(flex: 4, child: _buildImage(context)),
      ],
    );
  }
}
