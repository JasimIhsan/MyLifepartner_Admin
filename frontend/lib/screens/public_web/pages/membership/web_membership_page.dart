import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:life_partner_again/screens/public_web/sections/public_web_shared_sections.dart';
import 'package:life_partner_again/screens/public_web/widgets/web_section_header.dart';

class WebMembershipPage extends StatelessWidget {
  const WebMembershipPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        const PublicHeroSection(
          eyebrow: 'Membership',
          title: 'A membership model for people who are serious.',
          body:
              'Create a profile for free, complete verification, and upgrade when you are ready for deeper access to the LPA experience.',
          imageAsset: 'assets/images/landing_couple_3.png',
          highlights: [
            'Free profile creation',
            'Founding member access',
            'Premium features',
          ],
        ),
        PublicWebSection(
          backgroundColor: theme.brightness == Brightness.dark
              ? theme.scaffoldBackgroundColor
              : const Color(0xFFFFFBFB),
          child: const _FoundingMemberOffer(),
        ),
        const PublicWebSection(
          child: Column(
            children: [
              WebSectionHeader(
                eyebrow: 'Registration',
                title: 'How registration works',
                body:
                    'The journey is intentionally paced so members can build a thoughtful profile before starting meaningful conversations.',
              ),
              SizedBox(height: 36),
              _RegistrationTimeline(),
            ],
          ),
        ),
        PublicWebSection(
          backgroundColor: theme.brightness == Brightness.dark
              ? theme.scaffoldBackgroundColor
              : const Color(0xFFF8F8F8),
          child: const Column(
            children: [
              WebSectionHeader(
                eyebrow: 'Plans',
                title: 'Free and Premium both have a purpose.',
                body:
                    'Free membership lets people enter the community thoughtfully. Premium helps committed members communicate and search with fewer limitations.',
              ),
              SizedBox(height: 34),
              PublicSimpleGrid(
                minTileWidth: 340,
                children: [
                  _PlanSummary(
                    icon: LucideIcons.user_check,
                    title: 'Free Membership',
                    body:
                        'Create your profile, browse members, receive messages, and express interest within free plan limits.',
                    items: [
                      'Profile creation',
                      'Basic browsing',
                      'Receive messages',
                      'Limited interest actions',
                    ],
                  ),
                  _PlanSummary(
                    icon: LucideIcons.crown,
                    title: 'Premium Membership',
                    body:
                        'Unlock broader discovery and communication tools designed for serious relationship building.',
                    items: [
                      'Send conversation requests',
                      'Unlimited profile browsing',
                      'Advanced search filters',
                      'Priority support',
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const PublicWebSection(child: _MembershipComparison()),
      ],
    );
  }
}

class _FoundingMemberOffer extends StatelessWidget {
  const _FoundingMemberOffer();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 760;
          final icon = Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              LucideIcons.gift,
              color: theme.colorScheme.primary,
              size: 30,
            ),
          );
          final text = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Founding Member Offer',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'The app already recognizes founding members with complete free premium access. This section gives the website a clear place to explain that offer as product details evolve.',
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
              ),
            ],
          );

          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [icon, const SizedBox(height: 18), text],
            );
          }

          return Row(
            children: [
              icon,
              const SizedBox(width: 24),
              Expanded(child: text),
            ],
          );
        },
      ),
    );
  }
}

class _RegistrationTimeline extends StatelessWidget {
  const _RegistrationTimeline();

  static const _steps = [
    'Create your profile',
    'Complete verification',
    'Find yourself before finding your partner',
    'Discover compatible people',
    'Start fruitful conversations',
    'Build a meaningful relationship',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 820;

        if (isMobile) {
          return Column(
            children: [
              for (var index = 0; index < _steps.length; index++)
                _TimelineStep(
                  number: index + 1,
                  title: _steps[index],
                  isLast: index == _steps.length - 1,
                  isMobile: true,
                ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < _steps.length; index++) ...[
              Expanded(
                child: _TimelineStep(
                  number: index + 1,
                  title: _steps[index],
                  isLast: index == _steps.length - 1,
                  isMobile: false,
                ),
              ),
              if (index != _steps.length - 1)
                Container(
                  width: 24,
                  height: 1,
                  margin: const EdgeInsets.only(top: 22),
                  color: theme.dividerColor,
                ),
            ],
          ],
        );
      },
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final int number;
  final String title;
  final bool isLast;
  final bool isMobile;

  const _TimelineStep({
    required this.number,
    required this.title,
    required this.isLast,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final marker = Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$number',
        style: TextStyle(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );

    if (isMobile) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              marker,
              if (!isLast)
                Container(width: 1, height: 34, color: theme.dividerColor),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 24),
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        marker,
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _PlanSummary extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final List<String> items;

  const _PlanSummary({
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
            ),
          ),
          const SizedBox(height: 10),
          Text(body, style: theme.textTheme.bodyLarge?.copyWith(height: 1.55)),
          const SizedBox(height: 20),
          PublicBulletList(items: items),
        ],
      ),
    );
  }
}

class _MembershipComparison extends StatelessWidget {
  const _MembershipComparison();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const WebSectionHeader(
          eyebrow: 'Comparison',
          title: 'A calm comparison, not a pressure tactic.',
          body:
              'Use Free to begin thoughtfully. Choose Premium when you are ready for a fuller path to connection.',
        ),
        const SizedBox(height: 34),
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 760;
            final rows = const [
              _ComparisonRow('Create profile', 'Included', 'Included'),
              _ComparisonRow('Browse profiles', 'Limited', 'Unlimited'),
              _ComparisonRow('Conversation requests', 'Limited', 'Included'),
              _ComparisonRow('Advanced filters', 'Basic', 'Expanded'),
              _ComparisonRow('Priority support', 'Standard', 'Priority'),
            ];

            if (isMobile) {
              return Column(
                children: [
                  for (final row in rows) _MobileComparisonRow(row: row),
                ],
              );
            }

            return _DesktopComparisonTable(rows: rows);
          },
        ),
      ],
    );
  }
}

class _ComparisonRow {
  final String feature;
  final String free;
  final String premium;

  const _ComparisonRow(this.feature, this.free, this.premium);
}

class _DesktopComparisonTable extends StatelessWidget {
  final List<_ComparisonRow> rows;

  const _DesktopComparisonTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _ComparisonLine(
            cells: const ['Feature', 'Free', 'Premium'],
            isHeader: true,
            isLast: rows.isEmpty,
          ),
          for (var index = 0; index < rows.length; index++)
            _ComparisonLine(
              cells: [
                rows[index].feature,
                rows[index].free,
                rows[index].premium,
              ],
              isLast: index == rows.length - 1,
            ),
        ],
      ),
    );
  }
}

class _ComparisonLine extends StatelessWidget {
  final List<String> cells;
  final bool isHeader;
  final bool isLast;

  const _ComparisonLine({
    required this.cells,
    this.isHeader = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Row(
        children: [
          for (var index = 0; index < cells.length; index++)
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: isHeader
                      ? theme.colorScheme.primary.withValues(alpha: 0.06)
                      : null,
                  border: Border(
                    right: index == cells.length - 1
                        ? BorderSide.none
                        : BorderSide(color: theme.dividerColor),
                  ),
                ),
                child: Text(
                  cells[index],
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: isHeader || index == 0
                        ? FontWeight.w900
                        : FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MobileComparisonRow extends StatelessWidget {
  final _ComparisonRow row;

  const _MobileComparisonRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            row.feature,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text('Free: ${row.free}'),
          const SizedBox(height: 6),
          Text('Premium: ${row.premium}'),
        ],
      ),
    );
  }
}
