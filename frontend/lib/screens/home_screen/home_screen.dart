import 'package:flutter/material.dart';
import 'package:mylifepartner/core/app_colors.dart';
import 'package:mylifepartner/providers/match_provider.dart';
import 'package:mylifepartner/screens/chat_screen/chat_screen.dart';
import 'package:mylifepartner/screens/discover_screen/discover_screen.dart';
import 'package:mylifepartner/screens/likes_screen/likes_screen.dart';
import 'package:mylifepartner/screens/login_screen/login_screen.dart';
import 'package:mylifepartner/screens/profile_screen/profile_screen.dart';
import 'package:mylifepartner/screens/questionaire_screen/questionaire_screen.dart';
import 'package:mylifepartner/services/profile_repository.dart';
import 'package:mylifepartner/shared/widgets/custom_app_bar.dart';
import 'package:mylifepartner/shared/widgets/custom_bottom_bar.dart';
import 'package:mylifepartner/shared/widgets/custom_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final ProfileRepository _profileRepository = ProfileRepository();
  bool _isSheetShowing = false;
  bool _isCheckingProfile = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkProfileCompletion();
    });
  }

  // ─── Profile completion check ──────────────────────────────────────────────

  Future<void> _checkProfileCompletion() async {
    if (!mounted || _isSheetShowing || _isCheckingProfile) return;

    _isCheckingProfile = true;

    try {
      final status = await _profileRepository.getCompletionStatus();

      if (!mounted) return;

      if (status['isCompleted'] == false) {
        _isSheetShowing = true;

        await CustomBottomSheet.show(
          context: context,
          type: BottomSheetType.info,
          isScrollControlled: true,
          isDismissible: false,
          title: "Complete Your Profile",
          message:
              "You have pending profile questions. Complete them to find better matches.",
          primaryButtonText: "Continue",
          onPrimaryPressed: () {
            Navigator.of(context).pop();

            Navigator.of(context)
                .push(
                  MaterialPageRoute(
                    builder: (_) => QuestionaireScreen(
                      isPrimaryFlow: false,
                      initialSectionOrder: status['nextPendingSectionOrder'],
                    ),
                  ),
                )
                .then((_) {
                  if (mounted) {
                    _checkProfileCompletion();
                  }
                });
          },
          secondaryButtonText: "Later",
          onSecondaryPressed: () {
            Navigator.of(context).pop();
          },
        );

        _isSheetShowing = false;
      }
    } catch (e) {
      debugPrint("Error checking profile completion: $e");
    } finally {
      _isCheckingProfile = false;
    }
  }

  // ─── Navigation helpers ────────────────────────────────────────────────────

  Future<void> _logout() async {
    final sharedPrefs = await SharedPreferences.getInstance();
    sharedPrefs.clear();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        ModalRoute.withName('/'),
      );
    }
  }

  void _onTabTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) {
      _checkProfileCompletion();
      final provider = context.read<MatchProvider>();
      if (provider.profiles.isEmpty) {
        provider.loadRecommendations();
      }
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: SafeArea(child: _buildBody()),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return CustomAppBar(
      titleWidget: Image.asset(
        'assets/icons/app_logo.png',
        height: 40,
        fit: BoxFit.contain,
      ),
      showLeading: false,
      actions: [
        IconButton(
          icon: const Icon(
            Icons.notifications_outlined,
            color: AppColors.textPrimary,
          ),
          onPressed: () {},
        ),
        // IconButton(
        //   icon: const Icon(
        //     Icons.exit_to_app_outlined,
        //     color: AppColors.textPrimary,
        //   ),
        //   onPressed: _logout,
        // ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return CustomBottomBar(
      selectedIndex: _selectedIndex,
      onTap: _onTabTapped,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.explore_outlined),
          label: 'Discover',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite_border),
          label: 'Matches',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.message_outlined),
          label: 'Chat',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const DiscoverScreen();
      case 1:
        return const LikedMatchesScreen();
      case 2:
        return const ChatPlaceholderScreen();
      case 3:
        return const ProfileScreen();
      default:
        return const DiscoverScreen();
    }
  }
}
