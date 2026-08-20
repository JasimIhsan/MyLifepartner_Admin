import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:life_partner_again/screens/public_web/sections/public_web_shared_sections.dart';
import 'package:life_partner_again/screens/public_web/widgets/web_feature_card.dart';
import 'package:life_partner_again/screens/public_web/widgets/web_section_header.dart';

class WebFindYourselfPage extends StatelessWidget {
  const WebFindYourselfPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        const PublicHeroSection(
          eyebrow: 'Find Yourself',
          title: 'Find yourself before finding your partner again.',
          body:
              'Self-awareness is one of LPA\'s important differentiators. The app helps people reflect on readiness, values, and relationship expectations before rushing into connection.',
          imageAsset: 'assets/images/onboarding/emotional_readiness.png',
          highlights: [
            'Guided reflection',
            'Better conversations',
            'Emotional clarity',
          ],
        ),
        const PublicWebSection(
          child: Column(
            children: [
              WebSectionHeader(
                eyebrow: 'Self-awareness',
                title: 'A meaningful relationship starts with a clearer you.',
                body:
                    'When members understand what they need, what they can offer, and what patterns they want to avoid, every introduction becomes more thoughtful.',
              ),
              SizedBox(height: 34),
              PublicSimpleGrid(
                children: [
                  WebFeatureCard(
                    icon: LucideIcons.brain,
                    title: 'Know your readiness',
                    body:
                        'Reflect on whether you are emotionally prepared for a new relationship.',
                  ),
                  WebFeatureCard(
                    icon: LucideIcons.compass,
                    title: 'Name your direction',
                    body:
                        'Clarify what kind of partnership would feel healthy and realistic now.',
                  ),
                  WebFeatureCard(
                    icon: LucideIcons.messages_square,
                    title: 'Improve conversations',
                    body:
                        'Turn reflection into more honest introductions and better questions.',
                  ),
                ],
              ),
            ],
          ),
        ),
        PublicWebSection(
          backgroundColor: theme.brightness == Brightness.dark
              ? theme.scaffoldBackgroundColor
              : const Color(0xFFF8F8F8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 860;
              final header = const WebSectionHeader(
                eyebrow: 'Guided Questions',
                title: 'Gentle prompts before important choices.',
                body:
                    'The onboarding journey includes questions around relationship goals, emotional readiness, basic details, family context, location, education, profession, languages, and habits.',
                textAlign: TextAlign.left,
              );
              final bullets = const PublicBulletList(
                items: [
                  'What kind of relationship are you ready for now?',
                  'Which values are non-negotiable for your next chapter?',
                  'How do family, children, location, and lifestyle shape compatibility?',
                  'What does fruitful communication look like for you?',
                ],
              );

              if (isMobile) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [header, const SizedBox(height: 24), bullets],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: header),
                  const SizedBox(width: 54),
                  Expanded(child: bullets),
                ],
              );
            },
          ),
        ),
        const PublicWebSection(
          child: Column(
            children: [
              WebSectionHeader(
                eyebrow: '10 Golden Results',
                title: 'What a clearer beginning can create.',
                body:
                    'These outcomes are presented as intentions for the journey, not guarantees. They help frame why self-reflection belongs inside LPA.',
              ),
              SizedBox(height: 34),
              _GoldenResultsGrid(),
            ],
          ),
        ),
      ],
    );
  }
}

class _GoldenResultsGrid extends StatelessWidget {
  const _GoldenResultsGrid();

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

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / 330)
            .floor()
            .clamp(1, 3)
            .toInt();
        final width = (constraints.maxWidth - (18 * (columns - 1))) / columns;

        return Wrap(
          spacing: 18,
          runSpacing: 18,
          children: [
            for (var index = 0; index < _results.length; index++)
              SizedBox(
                width: width,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.42,
                        ),
                        width: 2,
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${index + 1}'.padLeft(2, '0'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          _results[index],
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
