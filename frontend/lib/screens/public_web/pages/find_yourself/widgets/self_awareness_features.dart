import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:life_partner_again/screens/public_web/widgets/responsive_web_container.dart';

class SelfAwarenessFeatures extends StatelessWidget {
  const SelfAwarenessFeatures({super.key});

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
        maxWidth: 1200,
        child: Column(
          children: [
            Text(
              'A clearer you',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'A meaningful relationship starts with self discovery.',
              textAlign: TextAlign.center,
              style: (isMobile ? theme.textTheme.headlineMedium : theme.textTheme.displaySmall)?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 24),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Text(
                'When members understand what they need, what they can offer, and what patterns they want to avoid, every introduction becomes more thoughtful and intentional.',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 80),
            if (isMobile)
              Column(
                children: [
                  _buildFeatureCard(
                    context,
                    LucideIcons.brain,
                    'Know your readiness',
                    'Reflect on whether you are emotionally prepared for a new relationship.',
                    0,
                  ),
                  const SizedBox(height: 24),
                  _buildFeatureCard(
                    context,
                    LucideIcons.compass,
                    'Name your direction',
                    'Clarify what kind of partnership would feel healthy and realistic now.',
                    1,
                  ),
                  const SizedBox(height: 24),
                  _buildFeatureCard(
                    context,
                    LucideIcons.messages_square,
                    'Improve conversations',
                    'Turn reflection into more honest introductions and better questions.',
                    2,
                  ),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 0),
                      child: _buildFeatureCard(
                        context,
                        LucideIcons.brain,
                        'Know your readiness',
                        'Reflect on whether you are emotionally prepared for a new relationship before taking the plunge.',
                        0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: _buildFeatureCard(
                        context,
                        LucideIcons.compass,
                        'Name your direction',
                        'Clarify what kind of partnership would feel healthy, grounded, and realistic for you right now.',
                        1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 80),
                      child: _buildFeatureCard(
                        context,
                        LucideIcons.messages_square,
                        'Improve conversations',
                        'Turn your personal reflection into more honest introductions and deeper, better questions on dates.',
                        2,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    IconData icon,
    String title,
    String body,
    int index,
  ) {
    return _HoverFeatureCard(
      icon: icon,
      title: title,
      body: body,
      index: index,
    );
  }
}

class _HoverFeatureCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String body;
  final int index;

  const _HoverFeatureCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.index,
  });

  @override
  State<_HoverFeatureCard> createState() => _HoverFeatureCardState();
}

class _HoverFeatureCardState extends State<_HoverFeatureCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Assign different subtle gradient colors based on index
    final colors = [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      theme.colorScheme.tertiary,
    ];
    final color = colors[widget.index % colors.length];

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isHovered ? -10 : 0, 0),
        padding: const EdgeInsets.all(40.0),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: _isHovered
                ? color.withValues(alpha: 0.5)
                : theme.dividerColor.withValues(alpha: 0.1),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: _isHovered ? 0.15 : 0.02),
              blurRadius: _isHovered ? 30 : 10,
              offset: Offset(0, _isHovered ? 15 : 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: _isHovered ? 0.2 : 0.1),
                    color.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                widget.icon,
                color: color,
                size: 36,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              widget.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.body,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
