import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';
import 'package:life_partner_again/screens/public_web/public_web_routes.dart';
import 'package:life_partner_again/screens/public_web/services/app_download_promotion_service.dart';
import 'package:life_partner_again/screens/public_web/widgets/download_app_buttons.dart';
import 'package:life_partner_again/screens/public_web/widgets/responsive_web_container.dart';
import 'package:url_launcher/url_launcher.dart';

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
                '© ${DateTime.now().year} Life Partner Again. All rights reserved. A product of Premium Global Corp., Canada.',
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/icons/app_logo_dark.png',
              width: 100,
              height: 48,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(LucideIcons.heart, color: Colors.white, size: 36),
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
          onTap: () {
            final emailUri = Uri.parse('mailto:${AppStoreLinks.supportEmail}');
            launchUrl(emailUri, mode: LaunchMode.externalApplication);
          },
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

class _FooterTextButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;

  const _FooterTextButton({required this.label, required this.onPressed});

  @override
  State<_FooterTextButton> createState() => _FooterTextButtonState();
}

class _FooterTextButtonState extends State<_FooterTextButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: InkWell(
          onTap: widget.onPressed,
          splashColor: Colors.transparent,
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 140),
              style: TextStyle(
                color: _isHovered
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.68),
                fontSize: 14,
                decoration: _isHovered
                    ? TextDecoration.underline
                    : TextDecoration.none,
                decorationColor: Colors.white,
                decorationThickness: 1.5,
              ),
              child: Text(widget.label),
            ),
          ),
        ),
      ),
    );
  }
}

class _FooterInfoRow extends StatefulWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  const _FooterInfoRow({required this.icon, required this.text, this.onTap});

  @override
  State<_FooterInfoRow> createState() => _FooterInfoRowState();
}

class _FooterInfoRowState extends State<_FooterInfoRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isInteractive = widget.onTap != null;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MouseRegion(
        cursor: isInteractive
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: InkWell(
          onTap: widget.onTap,
          splashColor: Colors.transparent,
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _isHovered
                      ? primaryColor.withValues(alpha: 0.22)
                      : primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  widget.icon,
                  color: _isHovered ? Colors.white : primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    widget.text,
                    style: TextStyle(
                      color: _isHovered
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.76),
                      fontSize: 14,
                      decoration: (isInteractive && _isHovered)
                          ? TextDecoration.underline
                          : TextDecoration.none,
                      decorationColor: Colors.white,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
