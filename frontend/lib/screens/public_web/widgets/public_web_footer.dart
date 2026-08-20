import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';
import 'package:life_partner_again/screens/public_web/public_web_routes.dart';
import 'package:life_partner_again/screens/public_web/services/app_download_promotion_service.dart';
import 'package:life_partner_again/screens/public_web/widgets/download_app_buttons.dart';
import 'package:life_partner_again/screens/public_web/widgets/responsive_web_container.dart';

class PublicWebFooter extends StatelessWidget {
  const PublicWebFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? theme.colorScheme.surface
            : const Color(0xFF111111),
      ),
      child: ResponsiveWebContainer(
        maxWidth: 1400,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 56),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 760;
                  final columns = [
                    const _BrandColumn(),
                    const _FooterLinkColumn(
                      title: 'Navigation',
                      links: [
                        PublicWebNavItem(
                          label: 'About',
                          route: PublicWebRoutes.about,
                          icon: LucideIcons.heart_handshake,
                        ),
                        PublicWebNavItem(
                          label: 'Membership',
                          route: PublicWebRoutes.membership,
                          icon: LucideIcons.crown,
                        ),
                        PublicWebNavItem(
                          label: 'Find Yourself',
                          route: PublicWebRoutes.findYourself,
                          icon: LucideIcons.sparkles,
                        ),
                        PublicWebNavItem(
                          label: 'Safety & Trust',
                          route: PublicWebRoutes.safety,
                          icon: LucideIcons.shield_check,
                        ),
                        PublicWebNavItem(
                          label: 'FAQ',
                          route: PublicWebRoutes.faq,
                          icon: LucideIcons.message_circle_question_mark,
                        ),
                      ],
                    ),
                    const _DownloadColumn(),
                    const _ContactColumn(),
                    const _FooterLinkColumn(
                      title: 'Legal',
                      links: [
                        PublicWebNavItem(
                          label: 'Privacy Policy',
                          route: PublicWebRoutes.privacy,
                          icon: LucideIcons.file_text,
                        ),
                        PublicWebNavItem(
                          label: 'Terms & Conditions',
                          route: PublicWebRoutes.terms,
                          icon: LucideIcons.scale,
                        ),
                      ],
                    ),
                  ];

                  if (isMobile) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final column in columns) ...[
                          column,
                          const SizedBox(height: 28),
                        ],
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 4, child: columns[0]),
                      const SizedBox(width: 32),
                      Expanded(flex: 2, child: columns[1]),
                      const SizedBox(width: 24),
                      Expanded(flex: 3, child: columns[2]),
                      const SizedBox(width: 24),
                      Expanded(flex: 3, child: columns[3]),
                      const SizedBox(width: 24),
                      Expanded(flex: 2, child: columns[4]),
                    ],
                  );
                },
              ),
              const SizedBox(height: 36),
              Divider(color: Colors.white.withValues(alpha: 0.14)),
              const SizedBox(height: 22),
              Text(
                '© ${DateTime.now().year} Life Partner Again. All rights reserved.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.62)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandColumn extends StatelessWidget {
  const _BrandColumn();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Image.asset(
              'assets/icons/app_logo_dark.png',
              width: 44,
              height: 44,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(LucideIcons.heart, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 12),
            const Flexible(
              child: Text(
                'Life Partner Again',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'A Canadian relationship platform for emotionally mature people seeking genuine companionship, trust, and long-term commitment.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.68),
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

class _FooterLinkColumn extends StatelessWidget {
  final String title;
  final List<PublicWebNavItem> links;

  const _FooterLinkColumn({required this.title, required this.links});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FooterTitle(title),
        const SizedBox(height: 14),
        for (final link in links)
          _FooterTextButton(
            label: link.label,
            onPressed: () => context.go(link.route),
          ),
      ],
    );
  }
}

class _DownloadColumn extends StatelessWidget {
  const _DownloadColumn();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FooterTitle('Download'),
        SizedBox(height: 18),
        DownloadAppButtons(compact: true),
      ],
    );
  }
}

class _ContactColumn extends StatelessWidget {
  const _ContactColumn();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FooterTitle('Contact'),
        const SizedBox(height: 14),
        _FooterInfoRow(
          icon: LucideIcons.mail,
          text: AppStoreLinks.supportEmail,
        ),
        if (AppStoreLinks.supportPhone != null)
          _FooterInfoRow(
            icon: LucideIcons.phone,
            text: AppStoreLinks.supportPhone!,
          ),
        if (AppStoreLinks.businessName != null)
          _FooterInfoRow(
            icon: LucideIcons.building,
            text: AppStoreLinks.businessName!,
          ),
      ],
    );
  }
}

class _FooterTitle extends StatelessWidget {
  final String text;

  const _FooterTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w900,
        fontSize: 14,
        letterSpacing: 0,
      ),
    );
  }
}

class _FooterTextButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _FooterTextButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: Colors.white.withValues(alpha: 0.68),
          padding: const EdgeInsets.symmetric(vertical: 6),
          minimumSize: const Size(0, 36),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(label),
      ),
    );
  }
}

class _FooterInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FooterInfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 17),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.68),
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
