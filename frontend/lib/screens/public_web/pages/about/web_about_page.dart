import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:life_partner_again/screens/public_web/sections/public_web_shared_sections.dart';
import 'package:life_partner_again/screens/public_web/widgets/web_feature_card.dart';
import 'package:life_partner_again/screens/public_web/widgets/web_section_header.dart';

class WebAboutPage extends StatelessWidget {
  const WebAboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        const PublicHeroSection(
          eyebrow: 'About Us',
          title: 'For people who are ready to love again with intention.',
          body:
              'Life Partner Again is a Canadian premium relationship platform for mature individuals seeking genuine, long-term relationships and marriage.',
          imageAsset: 'assets/images/landing_couple_2.png',
          highlights: [
            'Serious relationships',
            'Respectful community',
            'Built for trust',
          ],
        ),
        const PublicWebSection(
          child: Column(
            children: [
              WebSectionHeader(
                eyebrow: 'Who LPA is for',
                title: 'A place for sincere people in a real chapter of life.',
                body:
                    'LPA welcomes adults who are genuinely looking for a serious relationship or marriage, including divorced individuals, widows, widowers, separated people, single parents, professionals, and people who simply want something meaningful.',
              ),
              SizedBox(height: 34),
              PublicSimpleGrid(
                children: [
                  WebFeatureCard(
                    icon: LucideIcons.heart_handshake,
                    title: 'Companionship',
                    body:
                        'For people who value emotional warmth, shared values, and steadier connection.',
                  ),
                  WebFeatureCard(
                    icon: LucideIcons.user_check,
                    title: 'Readiness',
                    body:
                        'For members who are prepared to be honest about who they are and what they seek.',
                  ),
                  WebFeatureCard(
                    icon: LucideIcons.shield_check,
                    title: 'Respect',
                    body:
                        'For a community where dignity and safety matter as much as attraction.',
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
              final blocks = const [
                _MissionBlock(
                  icon: LucideIcons.compass,
                  title: 'Mission',
                  body:
                      'To help sincere individuals find meaningful, lifelong relationships in a respectful and secure environment.',
                ),
                _MissionBlock(
                  icon: LucideIcons.landmark,
                  title: 'Vision',
                  body:
                      'To become a trusted relationship platform where another chance at companionship feels hopeful, safe, and dignified.',
                ),
              ];

              if (isMobile) {
                return const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MissionBlock(
                      icon: LucideIcons.compass,
                      title: 'Mission',
                      body:
                          'To help sincere individuals find meaningful, lifelong relationships in a respectful and secure environment.',
                    ),
                    SizedBox(height: 24),
                    _MissionBlock(
                      icon: LucideIcons.landmark,
                      title: 'Vision',
                      body:
                          'To become a trusted relationship platform where another chance at companionship feels hopeful, safe, and dignified.',
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var index = 0; index < blocks.length; index++) ...[
                    Expanded(child: blocks[index]),
                    if (index == 0) const SizedBox(width: 28),
                  ],
                ],
              );
            },
          ),
        ),
        const PublicWebSection(
          child: Column(
            children: [
              WebSectionHeader(
                eyebrow: 'Values',
                title: 'The tone of the platform matters.',
                body:
                    'The LPA experience is shaped by values that protect the person behind each profile.',
              ),
              SizedBox(height: 34),
              PublicSimpleGrid(
                minTileWidth: 300,
                children: [
                  WebFeatureCard(
                    icon: LucideIcons.scale,
                    title: 'Integrity',
                    body:
                        'Clear intentions, honest profiles, and responsible community behaviour.',
                  ),
                  WebFeatureCard(
                    icon: LucideIcons.gem,
                    title: 'Dignity',
                    body:
                        'A mature tone for people whose stories deserve care, not judgment.',
                  ),
                  WebFeatureCard(
                    icon: LucideIcons.shield,
                    title: 'Safety',
                    body:
                        'Verification, privacy, reporting, and moderation working together.',
                  ),
                ],
              ),
            ],
          ),
        ),
        PublicWebSection(
          backgroundColor: theme.brightness == Brightness.dark
              ? theme.scaffoldBackgroundColor
              : const Color(0xFFFFFBFB),
          child: const EditorialQuote(
            body:
                'Life Partner Again exists for people who still believe in companionship, but want to approach it with more wisdom, patience, and self-respect.',
            attribution: 'Founder message',
          ),
        ),
      ],
    );
  }
}

class _MissionBlock extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _MissionBlock({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 30),
          const SizedBox(height: 18),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(body, style: theme.textTheme.bodyLarge?.copyWith(height: 1.65)),
        ],
      ),
    );
  }
}
