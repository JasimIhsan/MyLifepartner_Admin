import 'package:flutter/material.dart';
import '../../core/responsive/adaptive_screen.dart';
import 'mobile/mobile_likes_screen.dart';
import 'web/web_likes_screen.dart';

class LikedMatchesScreen extends StatelessWidget {
  const LikedMatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdaptiveScreen(
      mobile: MobileLikedMatchesScreen(),
      web: WebLikedMatchesScreen(),
    );
  }
}
