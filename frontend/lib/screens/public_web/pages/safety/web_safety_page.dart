import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:life_partner_again/screens/public_web/sections/public_web_shared_sections.dart';
import 'package:life_partner_again/screens/public_web/widgets/web_section_header.dart';

class WebSafetyPage extends StatelessWidget {
  const WebSafetyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        const PublicHeroSection(
          eyebrow: 'Safety & Trust',
          title: 'Trust should feel steady, not dramatic.',
          body:
              'LPA is designed around verification, privacy controls, reporting, blocking, moderation, and responsible data handling so members can stay in control while getting to know someone.',
          imageAsset: 'assets/images/illustrations/privacy.png',
          highlights: [
            'Protect identity',
            'Protect conversations',
            'Protect community',
          ],
        ),
        PublicWebSection(
          backgroundColor: theme.brightness == Brightness.dark
              ? theme.scaffoldBackgroundColor
              : const Color(0xFFF7F8F8),
          child: const Column(
            children: [
              WebSectionHeader(
                eyebrow: 'Protection Model',
                title: 'Safety is organized around the places trust matters.',
                body:
                    'The public site explains practical controls without using fear-based messaging. Members should understand what is protected and how to take action.',
              ),
              SizedBox(height: 36),
              _SafetyCategoryGrid(),
            ],
          ),
        ),
        const PublicWebSection(
          maxWidth: 1040,
          child: EditorialQuote(
            body:
                'The goal is not to make love feel clinical. The goal is to give sincere people enough trust and control to be open again.',
            attribution: 'LPA safety principle',
          ),
        ),
      ],
    );
  }
}

class _SafetyCategoryGrid extends StatelessWidget {
  const _SafetyCategoryGrid();

  @override
  Widget build(BuildContext context) {
    return const PublicSimpleGrid(
      minTileWidth: 420,
      spacing: 18,
      children: [
        _SafetyCategory(
          icon: LucideIcons.id_card,
          title: 'Protecting Your Identity',
          body:
              'Members should feel confident that profiles are real enough to begin a thoughtful conversation.',
          items: [
            _SafetyItemData(
              icon: LucideIcons.scan_face,
              title: 'Verification',
              body:
                  'Email OTP, selfie verification, and profile review support stronger identity trust.',
            ),
            _SafetyItemData(
              icon: LucideIcons.lock_keyhole,
              title: 'Privacy controls',
              body:
                  'Visibility controls help members decide how much they share and when.',
            ),
          ],
        ),
        _SafetyCategory(
          icon: LucideIcons.messages_square,
          title: 'Protecting Your Conversations',
          body:
              'Communication tools should help people connect without rushing into personal contact sharing.',
          items: [
            _SafetyItemData(
              icon: LucideIcons.message_square_lock,
              title: 'Secure communication',
              body:
                  'In-app messaging, voice, and video help members stay inside LPA while trust develops.',
            ),
            _SafetyItemData(
              icon: LucideIcons.flag,
              title: 'Reporting',
              body:
                  'Members can report inappropriate behaviour from inside the app for review.',
            ),
            _SafetyItemData(
              icon: LucideIcons.ban,
              title: 'Blocking',
              body:
                  'Blocking gives members an immediate way to stop unwanted contact.',
            ),
          ],
        ),
        _SafetyCategory(
          icon: LucideIcons.users_round,
          title: 'Protecting The Community',
          body:
              'A serious relationship community needs safeguards for fake profiles and harmful behaviour.',
          items: [
            _SafetyItemData(
              icon: LucideIcons.search_check,
              title: 'Fraud detection',
              body:
                  'Suspicious profile and activity patterns can be surfaced through platform safeguards.',
            ),
            _SafetyItemData(
              icon: LucideIcons.file_check,
              title: 'Manual review',
              body:
                  'Reports and verification signals can be reviewed when human judgment is needed.',
            ),
            _SafetyItemData(
              icon: LucideIcons.shield_check,
              title: 'Moderation',
              body:
                  'Moderation supports respectful conduct and helps preserve a serious environment.',
            ),
          ],
        ),
        _SafetyCategory(
          icon: LucideIcons.database,
          title: 'Protecting Your Data',
          body:
              'Personal data deserves plain-language protection, careful handling, and transparent legal pages.',
          items: [
            _SafetyItemData(
              icon: LucideIcons.key_round,
              title: 'Encryption',
              body:
                  'Account data and app communication rely on secured platform services and protected connections.',
            ),
            _SafetyItemData(
              icon: LucideIcons.landmark,
              title: 'Compliance',
              body:
                  'Privacy communication is written for a Canadian context, including PIPEDA-aware expectations.',
            ),
          ],
        ),
      ],
    );
  }
}

class _SafetyCategory extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final List<_SafetyItemData> items;

  const _SafetyCategory({
    required this.icon,
    required this.title,
    required this.body,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(26),
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
              height: 1.14,
            ),
          ),
          const SizedBox(height: 9),
          Text(body, style: theme.textTheme.bodyLarge?.copyWith(height: 1.55)),
          const SizedBox(height: 22),
          for (final item in items) _SafetyItem(item: item),
        ],
      ),
    );
  }
}

class _SafetyItemData {
  final IconData icon;
  final String title;
  final String body;

  const _SafetyItemData({
    required this.icon,
    required this.title,
    required this.body,
  });
}

class _SafetyItem extends StatelessWidget {
  final _SafetyItemData item;

  const _SafetyItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, color: theme.colorScheme.primary, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  item.body,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
