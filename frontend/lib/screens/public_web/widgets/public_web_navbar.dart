import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';
import 'package:life_partner_again/screens/public_web/public_web_routes.dart';
import 'package:life_partner_again/screens/public_web/widgets/download_app_buttons.dart';
import 'package:life_partner_again/screens/public_web/widgets/responsive_web_container.dart';

class PublicWebNavbar extends StatelessWidget {
  final String currentRoute;
  final bool isScrolled;

  const PublicWebNavbar({
    super.key,
    required this.currentRoute,
    this.isScrolled = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(
          alpha: isScrolled ? 0.96 : 0.88,
        ),
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(
              alpha: isScrolled ? 0.9 : 0.32,
            ),
          ),
        ),
        boxShadow: [
          if (isScrolled)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.055),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: ResponsiveWebContainer(
        maxWidth: 1480,
        child: SizedBox(
          height: 66,
          child: Row(
            children: [
              _Brand(onTap: () => context.go(PublicWebRoutes.home)),
              const Spacer(),
              LayoutBuilder(
                builder: (context, _) {
                  final width = MediaQuery.sizeOf(context).width;
                  if (PublicWebBreakpoints.isMobile(width) || width < 1320) {
                    return IconButton(
                      tooltip: 'Open navigation menu',
                      icon: const Icon(LucideIcons.menu),
                      onPressed: () => _showMobileMenu(context),
                    );
                  }

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final item in publicWebNavItems)
                        _NavLink(
                          item: item,
                          isActive: currentRoute == item.route,
                        ),
                      const SizedBox(width: 14),
                      const DownloadAppButtons(compact: true),
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

  void _showMobileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        final theme = Theme.of(context);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const _Logo(size: 36),
                    const SizedBox(width: 12),
                    Text(
                      'Life Partner Again',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                for (final item in publicWebNavItems)
                  _MobileNavLink(
                    item: item,
                    isActive: currentRoute == item.route,
                  ),
                const SizedBox(height: 18),
                const DownloadAppButtons(
                  compact: true,
                  alignment: WrapAlignment.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Brand extends StatelessWidget {
  final VoidCallback onTap;

  const _Brand({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _Logo(size: 38),
              const SizedBox(width: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 190),
                child: Text(
                  'Life Partner Again',
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
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

class _Logo extends StatelessWidget {
  final double size;

  const _Logo({required this.size});

  @override
  Widget build(BuildContext context) {
    final asset = Theme.of(context).brightness == Brightness.dark
        ? 'assets/icons/app_logo_dark.png'
        : 'assets/icons/app_logo.png';

    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Icon(
        LucideIcons.heart,
        color: Theme.of(context).colorScheme.primary,
        size: size * 0.72,
      ),
    );
  }
}

class _NavLink extends StatefulWidget {
  final PublicWebNavItem item;
  final bool isActive;

  const _NavLink({required this.item, required this.isActive});

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHighlighted = widget.isActive || _isHovered;
    final foreground = widget.isActive
        ? theme.colorScheme.primary
        : theme.textTheme.bodyLarge?.color;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: InkWell(
          onTap: () => context.go(widget.item.route),
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 11),
            decoration: BoxDecoration(
              color: widget.isActive
                  ? theme.colorScheme.primary.withValues(alpha: 0.08)
                  : _isHovered
                  ? theme.colorScheme.primary.withValues(alpha: 0.045)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.isActive
                    ? theme.colorScheme.primary.withValues(alpha: 0.16)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.item.icon,
                  size: 15,
                  color: isHighlighted
                      ? theme.colorScheme.primary
                      : theme.iconTheme.color?.withValues(alpha: 0.72),
                ),
                const SizedBox(width: 7),
                Text(
                  widget.item.label,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: widget.isActive
                        ? FontWeight.w900
                        : FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileNavLink extends StatelessWidget {
  final PublicWebNavItem item;
  final bool isActive;

  const _MobileNavLink({required this.item, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        leading: Icon(
          item.icon,
          color: isActive
              ? theme.colorScheme.primary
              : theme.textTheme.bodyMedium?.color,
        ),
        title: Text(
          item.label,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        selected: isActive,
        selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.08),
        onTap: () {
          Navigator.of(context).pop();
          context.go(item.route);
        },
      ),
    );
  }
}
