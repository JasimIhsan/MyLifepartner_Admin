import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:life_partner_again/screens/public_web/layouts/public_web_layout.dart';
import 'package:life_partner_again/screens/public_web/pages/about/web_about_page.dart';
import 'package:life_partner_again/screens/public_web/pages/faq/web_faq_page.dart';
import 'package:life_partner_again/screens/public_web/pages/find_yourself/web_find_yourself_page.dart';
import 'package:life_partner_again/screens/public_web/pages/home/web_home_page.dart';
import 'package:life_partner_again/screens/public_web/pages/membership/web_membership_page.dart';
import 'package:life_partner_again/screens/public_web/pages/privacy/web_privacy_page.dart';
import 'package:life_partner_again/screens/public_web/pages/safety/web_safety_page.dart';
import 'package:life_partner_again/screens/public_web/pages/terms/web_terms_page.dart';
import 'package:life_partner_again/screens/public_web/public_web_routes.dart';

Widget buildPublicWebLayout(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  final currentRoute = _currentPublicRoute(state);
  return PublicWebLayout(
    currentRoute: currentRoute,
    showGlobalDownloadCta: _showGlobalDownloadCta(currentRoute),
    child: child,
  );
}

List<RouteBase> buildPublicWebRoutes() {
  return [
    _publicRoute(path: PublicWebRoutes.home, child: const WebHomePage()),
    _publicRoute(path: PublicWebRoutes.about, child: const WebAboutPage()),
    _publicRoute(
      path: PublicWebRoutes.membership,
      child: const WebMembershipPage(),
    ),
    _publicRoute(
      path: PublicWebRoutes.findYourself,
      child: const WebFindYourselfPage(),
    ),
    _publicRoute(path: PublicWebRoutes.safety, child: const WebSafetyPage()),
    GoRoute(
      path: PublicWebRoutes.faq,
      pageBuilder: (context, state) {
        final section = state.uri.queryParameters['question'];
        return CustomTransitionPage(
          key: state.pageKey,
          child: WebFaqPage(initialExpandedId: section),
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final fadeAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            return FadeTransition(
              opacity: fadeAnimation,
              child: ColoredBox(
                color: Theme.of(context).colorScheme.surface,
                child: child,
              ),
            );
          },
        );
      },
    ),
    _publicRoute(path: PublicWebRoutes.privacy, child: const WebPrivacyPage()),
    _publicRoute(path: PublicWebRoutes.terms, child: const WebTermsPage()),
  ];
}

GoRoute _publicRoute({required String path, required Widget child}) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) {
      return CustomTransitionPage(
        key: state.pageKey,
        child: child,
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fadeAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );

          return FadeTransition(
            opacity: fadeAnimation,
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surface,
              child: child,
            ),
          );
        },
      );
    },
  );
}

String _currentPublicRoute(GoRouterState state) {
  final path = state.uri.path.isEmpty ? PublicWebRoutes.home : state.uri.path;
  if (PublicWebRoutes.routes.contains(path)) return path;
  if (PublicWebRoutes.routes.contains(state.matchedLocation)) {
    return state.matchedLocation;
  }
  return PublicWebRoutes.home;
}

bool _showGlobalDownloadCta(String route) {
  return route != PublicWebRoutes.privacy && route != PublicWebRoutes.terms;
}
