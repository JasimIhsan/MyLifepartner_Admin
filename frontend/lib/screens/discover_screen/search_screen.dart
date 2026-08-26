import 'package:flutter/material.dart';
import '../../core/responsive/adaptive_screen.dart';
import 'mobile/browse_profiles_screen.dart';
import 'web/web_search_screen.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdaptiveScreen(
      mobile: BrowseProfilesScreen(),
      web: WebSearchScreen(),
    );
  }
}
