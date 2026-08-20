import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:life_partner_again/screens/public_web/widgets/responsive_web_container.dart';

class MembershipComparisonTable extends StatelessWidget {
  const MembershipComparisonTable({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = PublicWebBreakpoints.isMobile(width);

    return ResponsiveWebContainer(
      maxWidth: 1000,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Compare Plans',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Find the right fit for your relationship journey.',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 48),
          if (isMobile)
            _buildMobileComparison(context)
          else
            _buildDesktopComparison(context),
        ],
      ),
    );
  }

  Widget _buildDesktopComparison(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        children: [
          _buildDesktopHeader(context),
          _buildDesktopRow(context, 'Basic profile access', 'Included', 'Included'),
          _buildDesktopRow(context, 'Send interests', 'Not Included', 'Unlimited'),
          _buildDesktopRow(context, 'Start chatting', 'Not Included', 'Unlimited'),
          _buildDesktopRow(context, 'Video & audio calls', 'Not Included', 'Unlimited'),
          _buildDesktopRow(context, 'Priority support', 'Standard', 'Priority', isLast: true),
        ],
      ),
    );
  }

  Widget _buildDesktopHeader(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'Features',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'Free',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'Premium',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopRow(
    BuildContext context, 
    String feature, 
    String free, 
    String premium, {
    bool isLast = false,
  }) {
    final theme = Theme.of(context);
    final isPremiumBetter = premium != free && premium != 'Standard' && premium != 'Basic';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              feature,
              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              free,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isPremiumBetter)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Icon(
                      LucideIcons.sparkles,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                Text(
                  premium,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: isPremiumBetter ? FontWeight.w800 : FontWeight.normal,
                    color: isPremiumBetter ? theme.colorScheme.primary : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileComparison(BuildContext context) {
    return Column(
      children: [
        _buildMobileRow(context, 'Basic profile access', 'Included', 'Included'),
        _buildMobileRow(context, 'Send interests', 'Not Included', 'Unlimited'),
        _buildMobileRow(context, 'Start chatting', 'Not Included', 'Unlimited'),
        _buildMobileRow(context, 'Video & audio calls', 'Not Included', 'Unlimited'),
        _buildMobileRow(context, 'Priority support', 'Standard', 'Priority'),
      ],
    );
  }

  Widget _buildMobileRow(
    BuildContext context, 
    String feature, 
    String free, 
    String premium,
  ) {
    final theme = Theme.of(context);
    final isPremiumBetter = premium != free && premium != 'Standard' && premium != 'Basic';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            feature,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Free',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                ),
              ),
              Text(
                free,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Premium',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                children: [
                  if (isPremiumBetter)
                    Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: Icon(
                        LucideIcons.sparkles,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  Text(
                    premium,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isPremiumBetter ? FontWeight.w800 : FontWeight.w600,
                      color: isPremiumBetter ? theme.colorScheme.primary : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
