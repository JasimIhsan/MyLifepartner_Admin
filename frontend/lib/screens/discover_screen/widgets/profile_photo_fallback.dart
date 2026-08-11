import 'package:flutter/material.dart';
import 'package:life_partner_again/core/app_colors.dart';

class ProfilePhotoFallback extends StatelessWidget {
  final String profileName;
  final bool showLoading;
  final bool showMessage;

  const ProfilePhotoFallback({
    super.key,
    required this.profileName,
    this.showLoading = false,
    this.showMessage = true,
  });

  static const String _fallbackAsset =
      'assets/images/illustrations/empty_profile.png';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          _fallbackAsset,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackBackground(theme),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.primaryColor.withValues(alpha: 0.10),
                theme.colorScheme.surface.withValues(alpha: 0.20),
                Colors.black.withValues(alpha: 0.18),
              ],
            ),
          ),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FallbackAvatar(
                profileName: profileName,
                showLoading: showLoading,
              ),
              if (showMessage && !showLoading) ...[
                const SizedBox(height: 14),
                Text(
                  'Photo unavailable',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.86),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.30),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _fallbackBackground(ThemeData theme) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.primaryColor.withValues(alpha: 0.16),
            theme.colorScheme.surface,
            theme.disabledColor.withValues(alpha: 0.16),
          ],
        ),
      ),
    );
  }
}

class _FallbackAvatar extends StatelessWidget {
  final String profileName;
  final bool showLoading;

  const _FallbackAvatar({required this.profileName, required this.showLoading});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = profileName.trim().isNotEmpty
        ? profileName.trim()[0].toUpperCase()
        : '?';

    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.92),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: 0.18),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: showLoading
            ? CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              )
            : Text(
                initial,
                style: TextStyle(
                  color: theme.primaryColor,
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}
