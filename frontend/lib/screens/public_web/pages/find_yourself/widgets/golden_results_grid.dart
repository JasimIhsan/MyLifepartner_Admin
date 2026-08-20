import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
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
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 120),
      child: ResponsiveWebContainer(
        maxWidth: 1400,
        child: Column(
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                '10 GOLDEN RESULTS',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.tertiary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'What a clearer beginning can create.',
              textAlign: TextAlign.center,
              style:
                  (isMobile
                          ? theme.textTheme.headlineMedium
                          : theme.textTheme.displayMedium)
                      ?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
            ),
            const SizedBox(height: 24),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Text(
                'These outcomes are presented as intentions for the journey, not guarantees. They help frame why deep self-reflection belongs inside LPA.',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withValues(
                    alpha: 0.7,
                  ),
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 80),
            // Grid Section
            if (isMobile)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _results.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) =>
                    _buildResultCard(context, index, _results[index]),
              )
            else
              MasonryGridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: width > 1024 ? 3 : 2,
                mainAxisSpacing: 24,
                crossAxisSpacing: 24,
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  return _buildResultCard(context, index, _results[index]);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, int index, String text) {
    return _HoverResultCard(index: index, text: text);
  }
}

class _HoverResultCard extends StatefulWidget {
  final int index;
  final String text;

  const _HoverResultCard({required this.index, required this.text});

  @override
  State<_HoverResultCard> createState() => _HoverResultCardState();
}

class _HoverResultCardState extends State<_HoverResultCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Create an alternating height effect for the masonry layout
    final isTall = widget.index % 3 == 0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isHovered ? -8 : 0, 0),
        height: isTall ? 280 : 220,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: _isHovered
                ? theme.colorScheme.tertiary.withValues(alpha: 0.5)
                : theme.dividerColor.withValues(alpha: 0.1),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.tertiary.withValues(
                alpha: _isHovered ? 0.1 : 0.02,
              ),
              blurRadius: _isHovered ? 24 : 10,
              offset: Offset(0, _isHovered ? 12 : 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            children: [
              // Background Watermark Number
              Positioned(
                right: 5,
                bottom: -5,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _isHovered ? 0.15 : 0.05,
                  child: Text(
                    '${widget.index + 1}'.padLeft(2, '0'),
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontSize: 140,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.tertiary,
                      height: 1,
                    ),
                  ),
                ),
              ),
              // Content
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _isHovered
                              ? theme.colorScheme.tertiary.withValues(
                                  alpha: 0.1,
                                )
                              : theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: theme.colorScheme.tertiary.withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ),
                        child: Text(
                          'Result ${widget.index + 1}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.tertiary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        widget.text,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
