import 'package:flutter/material.dart';
import 'package:life_partner_again/screens/public_web/widgets/responsive_web_container.dart';

class GoldenResultsGrid extends StatelessWidget {
  const GoldenResultsGrid({super.key});

  static const _results = [
    'Clearer relationship intention',
    'More honest profile storytelling',
    'Stronger emotional readiness',
    'Better preference awareness',
    'Healthier conversation starters',
    'More respectful boundaries',
    'Improved compatibility signals',
    'Less rushed decision-making',
    'More confidence in the process',
    'A more meaningful next chapter',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = PublicWebBreakpoints.isMobile(width);

    return Container(
      width: double.infinity,
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 100),
      child: ResponsiveWebContainer(
        maxWidth: 1200,
        child: Column(
          children: [
            Text(
              '10 Golden Results',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'What a clearer beginning can create.',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Text(
                'These outcomes are presented as intentions for the journey, not guarantees. They help frame why self-reflection belongs inside LPA.',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withValues(
                    alpha: 0.7,
                  ),
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 64),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = isMobile
                    ? 1
                    : (constraints.maxWidth > 800 ? 3 : 2);
                final itemWidth =
                    (constraints.maxWidth - (24 * (columns - 1))) / columns;

                return Wrap(
                  spacing: 24,
                  runSpacing: 24,
                  children: [
                    for (var index = 0; index < _results.length; index++)
                      SizedBox(
                        width: itemWidth,
                        child: _buildResultCard(
                          context,
                          index,
                          _results[index],
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, int index, String text) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? theme.colorScheme.primary.withValues(alpha: 0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
        boxShadow: theme.brightness == Brightness.dark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${index + 1}'.padLeft(2, '0'),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.primary.withValues(alpha: 0.8),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            text,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
