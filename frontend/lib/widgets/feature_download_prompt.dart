import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/screens/public_web/widgets/download_app_buttons.dart';

class FeatureDownloadPrompt {
  /// Checks if the user is on the web and if so, shows a prompt to download the app.
  /// Returns [true] if the action was intercepted (meaning the prompt was shown).
  /// Returns [false] if the user is NOT on the web (meaning the feature can proceed).
  static bool intercept(BuildContext context, {required String featureName}) {
    if (!kIsWeb) {
      return false;
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 600;

    if (isDesktop) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: _PromptContent(featureName: featureName, isDesktop: true),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).canvasColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            child: _PromptContent(featureName: featureName, isDesktop: false),
          ),
        ),
      );
    }

    return true;
  }
}

class _PromptContent extends StatelessWidget {
  final String featureName;
  final bool isDesktop;

  const _PromptContent({required this.featureName, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    if (isDesktop) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: Container(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                child: Image.asset(
                  'assets/images/illustrations/download_app.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.all(48.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'App Exclusive Feature',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color:
                            Theme.of(context).textTheme.bodyLarge?.color ??
                            AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'To use "$featureName", please download the Life Partner Again app. Enjoy the full experience on your mobile device!',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        height: 1.6,
                        color:
                            Theme.of(context).textTheme.bodyMedium?.color ??
                            AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 36),
                    const DownloadAppButtons(alignment: WrapAlignment.start),
                    const SizedBox(height: 36),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Close',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color ??
                                AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Mobile layout
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Image.asset(
            'assets/images/illustrations/download_app.png',
            height: 180,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 24),
          Text(
            'App Exclusive Feature',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color:
                  Theme.of(context).textTheme.bodyLarge?.color ??
                  AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'To use "$featureName", please download the Life Partner Again app. Enjoy the full experience on your mobile device!',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 16,
              height: 1.5,
              color:
                  Theme.of(context).textTheme.bodyMedium?.color ??
                  AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          const DownloadAppButtons(alignment: WrapAlignment.center),
        ],
      ),
    );
  }
}
