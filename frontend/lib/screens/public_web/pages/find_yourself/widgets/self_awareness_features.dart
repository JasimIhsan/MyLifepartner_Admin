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
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: ResponsiveWebContainer(
        maxWidth: 1200,
        child: Column(
          children: [
            Text(
              'A meaningful relationship starts with a clearer you.',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Text(
                'When members understand what they need, what they can offer, and what patterns they want to avoid, every introduction becomes more thoughtful.',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 64),
            if (isMobile)
              Column(
                children: [
                  _buildFeatureCard(
                    context,
                    LucideIcons.brain,
                    'Know your readiness',
                    'Reflect on whether you are emotionally prepared for a new relationship.',
                  ),
                  const SizedBox(height: 24),
                  _buildFeatureCard(
                    context,
                    LucideIcons.compass,
                    'Name your direction',
                    'Clarify what kind of partnership would feel healthy and realistic now.',
                  ),
                  const SizedBox(height: 24),
                  _buildFeatureCard(
                    context,
                    LucideIcons.messages_square,
                    'Improve conversations',
                    'Turn reflection into more honest introductions and better questions.',
                  ),
                ],
              )
            else
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _buildFeatureCard(
                      context,
                      LucideIcons.brain,
                      'Know your readiness',
                      'Reflect on whether you are emotionally prepared for a new relationship.',
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    child: _buildFeatureCard(
                      context,
                      LucideIcons.compass,
                      'Name your direction',
                      'Clarify what kind of partnership would feel healthy and realistic now.',
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    child: _buildFeatureCard(
                      context,
                      LucideIcons.messages_square,
                      'Improve conversations',
                      'Turn reflection into more honest introductions and better questions.',
                    ),
                  ),
                ],
              ),
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
  ) {
    return _HoverCard(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              body,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HoverCard extends StatefulWidget {
  final Widget child;

  const _HoverCard({required this.child});

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isHovered
                ? theme.colorScheme.primary.withValues(alpha: 0.5)
                : theme.dividerColor.withValues(alpha: 0.5),
          ),
          boxShadow: [
            if (_isHovered)
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.05),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}
