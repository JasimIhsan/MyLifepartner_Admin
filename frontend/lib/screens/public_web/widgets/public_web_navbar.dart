import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';
import 'package:life_partner_again/core/app_routes.dart';
import 'package:life_partner_again/providers/auth_provider.dart';
import 'package:life_partner_again/screens/public_web/public_web_routes.dart';
import 'package:life_partner_again/screens/public_web/widgets/responsive_web_container.dart';
import 'package:provider/provider.dart';

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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = MediaQuery.sizeOf(context).width;
              final isCompact =
                  PublicWebBreakpoints.isMobile(width) || width < 1280;

              if (isCompact) {
                return Row(
                  children: [
                    _Brand(onTap: () => context.go(PublicWebRoutes.home)),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Open navigation menu',
                      icon: const Icon(LucideIcons.menu),
                      onPressed: () => _showMobileMenu(context),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  // Left Zone: Brand Logo
                  _Brand(onTap: () => context.go(PublicWebRoutes.home)),

                  // Center Zone: Navigation Links
                  Expanded(
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final item in publicWebNavItems)
                            _NavLink(
                              item: item,
                              isActive: currentRoute == item.route,
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Right Zone: Download Action Buttons
                  const _AuthActionButtons(compact: true),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showMobileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.85,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final item in publicWebNavItems)
                    _MobileNavLink(
                      item: item,
                      isActive: currentRoute == item.route,
                    ),
                  const SizedBox(height: 18),
                  const _AuthActionButtons(
                    compact: true,
                    alignment: WrapAlignment.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AuthActionButtons extends StatelessWidget {
  final bool compact;
  final WrapAlignment alignment;

  const _AuthActionButtons({
    this.compact = false,
    this.alignment = WrapAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final buttonStyle = FilledButton.styleFrom(
      minimumSize: const Size(100, 44),
      padding: EdgeInsets.symmetric(horizontal: compact ? 20 : 24),
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 0,
    );

    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoggedIn) {
          return TextButton.icon(
            onPressed: () => context.go(AppRoutes.discover),
            icon: const Icon(LucideIcons.user, size: 18),
            label: const Text('My Profile'),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16),
              minimumSize: const Size(0, 44),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          );
        }

        return TextButton.icon(
          onPressed: () => context.go(AppRoutes.login),
          icon: const Icon(LucideIcons.log_in, size: 18),
          label: const Text('Login'),
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16),
            minimumSize: const Size(0, 44),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
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
              const _Logo(size: 90),
              // const SizedBox(width: 10),
              // ConstrainedBox(
              //   constraints: const BoxConstraints(maxWidth: 190),
              //   child: Text(
              //     'Life Partner Again',
              //     overflow: TextOverflow.ellipsis,
              //     style: theme.textTheme.titleMedium?.copyWith(
              //       color: theme.colorScheme.primary,
              //       fontWeight: FontWeight.w900,
              //       letterSpacing: 0,
              //     ),
              //   ),
              // ),
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
        size: size * 1.2,
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
    final foreground = widget.isActive
        ? theme.colorScheme.primary
        : _isHovered
        ? theme.colorScheme.primary.withValues(alpha: 0.85)
        : theme.textTheme.bodyLarge?.color;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: InkWell(
          onTap: () => context.go(widget.item.route),
          borderRadius: BorderRadius.circular(8),
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: SizedBox(
            height: 66,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    widget.item.label,
                    style: TextStyle(
                      color: foreground,
                      fontWeight: widget.isActive
                          ? FontWeight.w900
                          : FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    height: widget.isActive ? 3.5 : 0,
                    decoration: BoxDecoration(
                      color: widget.isActive
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
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
