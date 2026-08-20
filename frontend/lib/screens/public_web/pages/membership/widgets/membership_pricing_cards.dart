import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:life_partner_again/screens/public_web/widgets/responsive_web_container.dart';

class MembershipPricingCards extends StatefulWidget {
  const MembershipPricingCards({super.key});

  @override
  State<MembershipPricingCards> createState() => _MembershipPricingCardsState();
}

class _MembershipPricingCardsState extends State<MembershipPricingCards> {
  bool _isPremiumHovered = false;
  bool _isFreeHovered = false;

  @override
  Widget build(BuildContext context) {
    return ResponsiveWebContainer(
      maxWidth: 1000,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 760;

          if (isMobile) {
            return Column(
              children: [
                _buildFreeCard(context),
                const SizedBox(height: 24),
                _buildPremiumCard(context),
              ],
            );
          }

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildFreeCard(context)),
                const SizedBox(width: 32),
                Expanded(child: _buildPremiumCard(context)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFreeCard(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = _isFreeHovered
        ? theme.colorScheme.primary.withValues(alpha: 0.5)
        : theme.dividerColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _isFreeHovered = true),
      onExit: (_) => setState(() => _isFreeHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: _isFreeHovered
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.user,
                color: theme.colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Free',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'For entering the community thoughtfully and browsing profiles.',
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.7,
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildFeatureList(context, [
              const _FeatureItem('Basic profile access only'),
              const _FeatureItem('Send interests', isAvailable: false),
              const _FeatureItem('Start chatting', isAvailable: false),
              const _FeatureItem('Video & audio calls', isAvailable: false),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumCard(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isPremiumHovered = true),
      onExit: (_) => setState(() => _isPremiumHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? theme.canvasColor
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.primary, width: 2),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(
                alpha: _isPremiumHovered ? 0.2 : 0.1,
              ),
              blurRadius: _isPremiumHovered ? 30 : 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.crown,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'RECOMMENDED',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Premium',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Unlock broader discovery and communication tools for serious relationship building.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: theme.textTheme.bodyMedium?.color?.withValues(
                      alpha: 0.7,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _buildFeatureList(context, [
                  const _FeatureItem('Access All Premium Features'),
                  const _FeatureItem('Send Interests to Any Profile'),
                  const _FeatureItem('Chat with Interested Members'),
                  const _FeatureItem('Unlimited Video Calls'),
                  const _FeatureItem('Unlimited Audio Calls'),
                ], isPremium: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureList(
    BuildContext context,
    List<_FeatureItem> features, {
    bool isPremium = false,
  }) {
    final theme = Theme.of(context);

    return Column(
      children: features.map((feature) {
        final iconColor = feature.isAvailable
            ? (isPremium ? theme.colorScheme.primary : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7))
            : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.3);
            
        final textColor = feature.isAvailable
            ? theme.textTheme.bodyMedium?.color
            : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4);

        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                feature.isAvailable ? LucideIcons.check : LucideIcons.x,
                color: iconColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  feature.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: feature.isAvailable ? FontWeight.w600 : FontWeight.normal,
                    height: 1.4,
                    color: textColor,
                    decoration: feature.isAvailable ? null : TextDecoration.lineThrough,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _FeatureItem {
  final String title;
  final bool isAvailable;
  
  const _FeatureItem(this.title, {this.isAvailable = true});
}
