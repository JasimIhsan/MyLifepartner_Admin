import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class PublicWebRoutes {
  static const String home = '/';
  static const String about = '/about';
  static const String membership = '/membership';
  static const String findYourself = '/find-yourself';
  static const String safety = '/safety';
  static const String faq = '/faq';
  static const String privacy = '/privacy';
  static const String terms = '/terms';

  static const List<String> routes = [
    home,
    about,
    membership,
    findYourself,
    safety,
    faq,
    privacy,
    terms,
  ];

  static bool isPublicWebsiteRoute(String location) {
    final path = Uri.tryParse(location)?.path ?? location;
    return routes.contains(path);
  }

  static String titleFor(String route) {
    switch (route) {
      case about:
        return 'About | Life Partner Again';
      case membership:
        return 'Membership | Life Partner Again';
      case findYourself:
        return 'Find Yourself | Life Partner Again';
      case safety:
        return 'Safety & Trust | Life Partner Again';
      case faq:
        return 'FAQ | Life Partner Again';
      case privacy:
        return 'Privacy Policy | Life Partner Again';
      case terms:
        return 'Terms & Conditions | Life Partner Again';
      case home:
      default:
        return 'Life Partner Again';
    }
  }
}

class PublicWebNavItem {
  final String label;
  final String route;
  final IconData icon;

  const PublicWebNavItem({
    required this.label,
    required this.route,
    required this.icon,
  });
}

const List<PublicWebNavItem> publicWebNavItems = [
  PublicWebNavItem(
    label: 'Home',
    route: PublicWebRoutes.home,
    icon: LucideIcons.house,
  ),
  PublicWebNavItem(
    label: 'About Us',
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
];
