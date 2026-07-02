import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mylifepartner/core/app_colors.dart';
import 'package:mylifepartner/providers/call_provider.dart';
import 'package:mylifepartner/providers/chat_provider.dart';
import 'package:mylifepartner/providers/match_provider.dart';
import 'package:mylifepartner/screens/chat_screen/chat_screen.dart';
import 'package:mylifepartner/screens/discover_screen/discover_screen.dart';
import 'package:mylifepartner/screens/likes_screen/likes_screen.dart';
import 'package:mylifepartner/screens/lpa_guide_screen/lpa_guide_screen.dart';
import 'package:mylifepartner/screens/notification_screen/notification_screen.dart';
import 'package:mylifepartner/screens/profile_screen/profile_screen.dart';
import 'package:mylifepartner/services/user_repository.dart';
import 'package:mylifepartner/services/zego_service.dart';
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
  bool _showNotifications = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initZegoAndChat();
      //_checkProfileCompletion();
    });
  }

  Future<void> _initZegoAndChat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      if (userId == null || !mounted) return;

      final userIdStr = userId.toString();

      String userName = 'User $userId';
      try {
        final profile = await UserRepository().getUser();
        if (profile.name != null && profile.name!.trim().isNotEmpty) {
          userName = profile.name!;
        }
      } catch (_) {
        // Fallback to default if fetching fails
      }

      if (!ZegoService.instance.isLoggedIn) {
        debugPrint(
          "😂 ZegoService.instance.isLoggedIn ${ZegoService.instance.isLoggedIn}",
        );
        await ZegoService.instance.login(userIdStr, userName);
      }

      if (mounted) {
        context.read<ChatProvider>().setCurrentUserId(userId);
        context.read<ChatProvider>().startListening();
        context.read<ChatProvider>().loadConversations();

        final callProvider = context.read<CallProvider>();
        callProvider.configure(userId: userIdStr, userName: userName);
        callProvider.loadUserAvatar();
        callProvider.startListening();
      }
    } catch (e) {
      debugPrint('[HomePage] Zego init failed: $e');
    }
  }

  // ─── Navigation helpers ────────────────────────────────────────────────────

  void _onTabTapped(int index) {
    setState(() => _selectedIndex = index);
    _showNotifications = false;
    if (index == 0) {
      final provider = context.read<MatchProvider>();
      if (provider.profiles.isEmpty) {
        provider.loadRecommendations();
      }
    }
  }

  Future<void> _handleBackPress() async {
    if (_showNotifications) {
      setState(() {
        _showNotifications = false;
      });
      return;
    }
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
      });
      return;
    }

    if (!mounted) return;

    await CustomBottomSheet.show(
      context: context,
      type: BottomSheetType.confirmation,
      title: 'Exit App',
      message: 'Are you sure you want to exit the app?',
      primaryButtonText: 'Exit',
      onPrimaryPressed: () {
        SystemNavigator.pop();
      },
      secondaryButtonText: 'Cancel',
      onSecondaryPressed: () {
        Navigator.of(context).pop();
      },
      imagePath: 'assets/images/illustrations/exit.png',
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackPress();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: SafeArea(child: _buildBody()),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
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
          icon: Image.asset(
            'assets/icons/lpa_assist.png',
            width: 24,
            height: 24,
          ),
          tooltip: 'LPA Assist',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const Scaffold(body: SafeArea(child: LpaGuideScreen())),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(
            Icons.notifications_active_outlined,
            color: AppColors.textPrimary,
          ),
          onPressed: () {
            setState(() {
              _showNotifications = true;
            });
          },
        ),
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
    if (_showNotifications) {
      return NotificationScreen(
        onBack: () {
          setState(() {
            _showNotifications = false;
          });
        },
      );
    }
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
