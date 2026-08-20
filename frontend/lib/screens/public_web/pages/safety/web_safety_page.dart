import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class WebSafetyPage extends StatelessWidget {
  const WebSafetyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _SafetyHeroSection(),
        _SafetyPillarsSection(),
        _SafetyCommitmentSection(),
      ],
    );
  }
}

class _SafetyHeroSection extends StatelessWidget {
  const _SafetyHeroSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF0F172A), theme.scaffoldBackgroundColor]
              : [const Color(0xFFF1F5F9), theme.scaffoldBackgroundColor],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 100),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.shield_check,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Safety & Trust',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Trust should feel steady,\nnot dramatic.',
                textAlign: TextAlign.center,
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  letterSpacing: -1,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Text(
                  'LPA is designed around verification, privacy controls, reporting, blocking, moderation, and responsible data handling so members can stay in control while getting to know someone.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              const Wrap(
                spacing: 32,
                runSpacing: 24,
                alignment: WrapAlignment.center,
                children: [
                  _HeroHighlight(
                    icon: LucideIcons.id_card,
                    text: 'Protect identity',
                  ),
                  _HeroHighlight(
                    icon: LucideIcons.messages_square,
                    text: 'Protect conversations',
                  ),
                  _HeroHighlight(
                    icon: LucideIcons.users_round,
                    text: 'Protect community',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroHighlight extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroHighlight({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _SafetyPillarsSection extends StatelessWidget {
  const _SafetyPillarsSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      color: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF7F8F8),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Protection Model',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Safety is organized around\nthe places trust matters.',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Text(
                  'The public site explains practical controls without using fear-based messaging. Members should understand what is protected and how to take action.',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 64),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 800;

                  if (isDesktop) {
                    return const Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _IdentityCard()),
                            SizedBox(width: 32),
                            Expanded(child: _DataCard()),
                          ],
                        ),
                        SizedBox(height: 32),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _CommunityCard()),
                            SizedBox(width: 32),
                            Expanded(child: _ConversationsCard()),
                          ],
                        ),
                      ],
                    );
                  }

                  return const Column(
                    children: [
                      _IdentityCard(),
                      SizedBox(height: 24),
                      _ConversationsCard(),
                      SizedBox(height: 24),
                      _CommunityCard(),
                      SizedBox(height: 24),
                      _DataCard(),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
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

class _SafetyCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String body;
  final List<_SafetyItemData> items;

  const _SafetyCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.items,
  });

  @override
  State<_SafetyCard> createState() => _SafetyCardState();
}

class _SafetyCardState extends State<_SafetyCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surface : Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: _isHovered
                ? theme.colorScheme.primary.withValues(alpha: 0.5)
                : theme.dividerColor,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(
                alpha: _isHovered ? 0.08 : 0.0,
              ),
              blurRadius: _isHovered ? 32 : 0,
              offset: Offset(0, _isHovered ? 12 : 0),
            ),
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(
                  alpha: _isHovered ? 0.2 : 0.1,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                widget.icon,
                color: theme.colorScheme.primary,
                size: 36,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              widget.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                height: 1.2,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.body,
              style: theme.textTheme.titleMedium?.copyWith(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            const Divider(height: 1),
            const SizedBox(height: 40),
            ...widget.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.03),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item.icon,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.body,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Extracted classes for the specific cards to keep layout code clean
class _IdentityCard extends StatelessWidget {
  const _IdentityCard();

  @override
  Widget build(BuildContext context) {
    return const _SafetyCard(
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
    );
  }
}

class _ConversationsCard extends StatelessWidget {
  const _ConversationsCard();

  @override
  Widget build(BuildContext context) {
    return const _SafetyCard(
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
    );
  }
}

class _CommunityCard extends StatelessWidget {
  const _CommunityCard();

  @override
  Widget build(BuildContext context) {
    return const _SafetyCard(
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
    );
  }
}

class _DataCard extends StatelessWidget {
  const _DataCard();

  @override
  Widget build(BuildContext context) {
    return const _SafetyCard(
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
    );
  }
}

class _SafetyCommitmentSection extends StatelessWidget {
  const _SafetyCommitmentSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // We want this section to really stand out, maybe a primary colored block
    final backgroundColor = isDark
        ? theme.colorScheme.primary.withValues(alpha: 0.2)
        : theme.colorScheme.primary;
    final textColor = isDark ? Colors.white : theme.colorScheme.onPrimary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 120),
      decoration: BoxDecoration(color: backgroundColor),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              Icon(
                LucideIcons.quote,
                size: 56,
                color: textColor.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 40),
              Text(
                'The goal is not to make love feel clinical. The goal is to give sincere people enough trust and control to be open again.',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 48),
              Container(
                width: 60,
                height: 4,
                decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'LPA Safety Principle',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: textColor.withValues(alpha: 0.9),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  textBaseline: TextBaseline.alphabetic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
