import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:life_partner_again/screens/public_web/widgets/responsive_web_container.dart';

class GuidedQuestionsSection extends StatelessWidget {
  const GuidedQuestionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = PublicWebBreakpoints.isMobile(width);

    return Container(
      width: double.infinity,
      color: theme.colorScheme.primary.withValues(alpha: 0.03),
      padding: const EdgeInsets.symmetric(vertical: 100),
      child: ResponsiveWebContainer(
        maxWidth: 1200,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final content = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.message_circle,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'GUIDED QUESTIONS',
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
                  'Gentle prompts before important choices.',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'The onboarding journey includes questions around relationship goals, emotional readiness, basic details, family context, location, education, profession, languages, and habits.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                    height: 1.6,
                  ),
                ),
              ],
            );

            final bubblesList = Column(
              children: [
                _buildThoughtBubble(
                  context,
                  'What kind of relationship are you ready for now?',
                  0,
                ),
                const SizedBox(height: 24),
                _buildThoughtBubble(
                  context,
                  'Which values are non-negotiable for your next chapter?',
                  1,
                ),
                const SizedBox(height: 24),
                _buildThoughtBubble(
                  context,
                  'How do family, children, location, and lifestyle shape compatibility?',
                  2,
                ),
                const SizedBox(height: 24),
                _buildThoughtBubble(
                  context,
                  'What does fruitful communication look like for you?',
                  3,
                ),
              ],
            );

            if (isMobile || constraints.maxWidth < 860) {
              return Column(
                children: [
                  content,
                  const SizedBox(height: 64),
                  bubblesList,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 10, child: content),
                const SizedBox(width: 64),
                Expanded(flex: 12, child: bubblesList),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildThoughtBubble(BuildContext context, String text, int index) {
    final theme = Theme.of(context);
    // Alternate alignment for a more natural conversational look
    final isRightAligned = index.isOdd;

    return Row(
      mainAxisAlignment:
          isRightAligned ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(24),
                topRight: const Radius.circular(24),
                bottomLeft: isRightAligned
                    ? const Radius.circular(24)
                    : const Radius.circular(4),
                bottomRight: isRightAligned
                    ? const Radius.circular(4)
                    : const Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Text(
              text,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.9),
                height: 1.4,
              ),
            ),
          ),
        ),
        if (isRightAligned) const SizedBox(width: 40) else const SizedBox(width: 40),
      ],
    );
  }
}
