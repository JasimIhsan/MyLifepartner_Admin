import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/screens/public_web/layouts/public_web_layout.dart';
import 'package:life_partner_again/screens/public_web/public_web_routes.dart';

class WebNotFoundPage extends StatelessWidget {
  const WebNotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the screen height and subtract a reasonable amount for the header and footer
    // to ensure this takes up most of the viewport, pushing the footer down.
    final screenHeight = MediaQuery.of(context).size.height;
    final minHeight = screenHeight > 600 ? screenHeight - 200 : 400.0;

    return PublicWebLayout(
      currentRoute: PublicWebRoutes.home,
      showGlobalDownloadCta: false,
      child: Container(
        constraints: BoxConstraints(minHeight: minHeight),
        width: double.infinity,
        decoration: const BoxDecoration(color: AppColors.background),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background large 404 text
            // const Positioned(
            //   child: Opacity(
            //     opacity: 0.05,
            //     child: Text(
            //       '404',
            //       style: TextStyle(
            //         fontSize: 240,
            //         fontWeight: FontWeight.w900,
            //         color: AppColors.primaryDark,
            //         height: 1,
            //       ),
            //     ),
            //   ),
            // ),

            // Foreground content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '404',
                    style: TextStyle(
                      fontSize: 240,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryDark,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Page Not Found',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Text(
                      'Oops! The page you are looking for seems to have wandered off. Let\'s get you back on track to finding your perfect match.',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 48),
                  ElevatedButton.icon(
                    onPressed: () => context.go(PublicWebRoutes.home),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 20,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    icon: const Icon(Icons.home_rounded),
                    label: const Text(
                      'Return to Homepage',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
