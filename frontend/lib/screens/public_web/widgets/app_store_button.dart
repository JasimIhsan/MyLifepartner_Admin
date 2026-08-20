import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:life_partner_again/screens/public_web/services/app_download_promotion_service.dart';

class AppStoreButton extends StatelessWidget {
  final bool compact;

  const AppStoreButton({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return _StoreButton(
      icon: Icons.apple,
      overline: 'Download on the',
      label: 'App Store',
      compact: compact,
      onPressed: () => _open(context),
      semanticLabel: 'Download Life Partner Again on the App Store',
    );
  }

  Future<void> _open(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await AppDownloadPromotionService().openStore(
      AppDownloadStore.appStore,
    );
    if (!context.mounted) return;

    switch (result) {
      case AppDownloadLaunchResult.opened:
        break;
      case AppDownloadLaunchResult.missingUrl:
        messenger.showSnackBar(
          const SnackBar(
            content: Text('The App Store link is not configured yet.'),
          ),
        );
        break;
      case AppDownloadLaunchResult.failed:
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Unable to open the App Store right now.'),
          ),
        );
        break;
    }
  }
}

class _StoreButton extends StatelessWidget {
  final IconData icon;
  final String overline;
  final String label;
  final String semanticLabel;
  final bool compact;
  final VoidCallback onPressed;

  const _StoreButton({
    required this.icon,
    required this.overline,
    required this.label,
    required this.semanticLabel,
    required this.compact,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: semanticLabel,
      child: Tooltip(
        message: semanticLabel,
        child: SizedBox(
          height: compact ? 48 : 56,
          child: ElevatedButton.icon(
            onPressed: onPressed,
            icon: SvgPicture.asset(
              'assets/store_badges/app_store.svg',
              width: compact ? 20 : 23,
              height: compact ? 20 : 23,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
              placeholderBuilder: (context) =>
                  Icon(icon, color: Colors.white, size: compact ? 20 : 23),
            ),
            label: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  overline,
                  style: TextStyle(
                    fontSize: compact ? 9 : 10,
                    fontWeight: FontWeight.w500,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: compact ? 14 : 16,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ],
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 14 : 18,
                vertical: 8,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: theme.brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.14)
                      : Colors.black,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
