import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/core/app_routes.dart';
import 'package:life_partner_again/providers/call_provider.dart';
import 'package:life_partner_again/providers/chat_provider.dart';
import 'package:life_partner_again/providers/match_provider.dart';
import 'package:life_partner_again/providers/notification_provider.dart';
import 'package:life_partner_again/screens/chat_screen/chat_screen.dart';
import 'package:life_partner_again/screens/discover_screen/discover_screen.dart';
import 'package:life_partner_again/screens/likes_screen/likes_screen.dart';
import 'package:life_partner_again/screens/notification_screen/notification_screen.dart';
import 'package:life_partner_again/screens/profile_screen/profile_screen.dart';
import 'package:life_partner_again/services/user_repository.dart';
import 'package:life_partner_again/services/zego_service.dart';
import 'package:life_partner_again/widgets/bottomsheet/custom_bottom_sheet.dart';
import 'package:life_partner_again/widgets/custom_app_bar.dart';
import 'package:life_partner_again/widgets/custom_bottom_bar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  final int initialIndex;
  const HomePage({super.key, this.initialIndex = 0});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late int _selectedIndex;
  bool _isBottomNavVisible = true;
  bool _showNotifications = false;

  bool get _isPrefixedWebAppRoute {
    if (!kIsWeb) return false;
    final location = GoRouterState.of(context).matchedLocation;
    return location == '/app' || location.startsWith('/app/');
  }

  String _targetRoute(String route) {
    return _isPrefixedWebAppRoute ? '/app$route' : route;
  }

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initZegoAndChat();
      if (mounted) {
        context.read<NotificationProvider>().fetchUnreadCount();
      }
    });
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIndex != oldWidget.initialIndex) {
      setState(() {
        _selectedIndex = widget.initialIndex;
      });
    }
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

  void _onTabTapped(int index) {
    if (kIsWeb && MediaQuery.of(context).size.width >= 800) {
      String targetRoute = AppRoutes.home;
      if (index == 0) targetRoute = AppRoutes.discover;
      if (index == 1) targetRoute = AppRoutes.matches;
      if (index == 2) targetRoute = AppRoutes.chat;
      if (index == 3) targetRoute = AppRoutes.profile;

      _showNotifications = false;
      context.go(_targetRoute(targetRoute));
      return;
    }

    setState(() => _selectedIndex = index);
    _showNotifications = false;
    if (index == 0) {
      final provider = context.read<MatchProvider>();
      if (provider.profiles.isEmpty) {
        provider.loadRecommendations();
      }
      if (mounted) {
        context.read<NotificationProvider>().fetchUnreadCount();
      }
    }
  }

  Future<void> _handleBackPress() async {
    if (_showNotifications) {
      setState(() {
        _showNotifications = false;
      });
      if (mounted) {
        context.read<NotificationProvider>().fetchUnreadCount();
      }
      return;
    }
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
      });
      if (mounted) {
        context.read<NotificationProvider>().fetchUnreadCount();
      }
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
        context.pop();
      },
      imagePath: 'assets/images/illustrations/exit.png',
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = kIsWeb && MediaQuery.of(context).size.width >= 800;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackPress();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        extendBody: !isDesktop,
        appBar: isDesktop ? null : _buildAppBar(),
        body: _buildBody(),
        bottomNavigationBar: isDesktop
            ? null
            : AnimatedSlide(
                duration: const Duration(milliseconds: 300),
                offset: _isBottomNavVisible ? Offset.zero : const Offset(0, 2),
                child: _buildBottomNavigationBar(),
              ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return CustomAppBar(
      titleWidget: Image.asset(
        Theme.of(context).brightness == Brightness.dark
            ? 'assets/icons/app_logo_dark.png'
            : 'assets/icons/app_logo.png',
        height: 40,
        fit: BoxFit.contain,
      ),
      showLeading: false,
      actions: [
        IconButton(
          icon: Icon(
            Icons.search,
            color:
                Theme.of(context).textTheme.bodyLarge?.color ??
                AppColors.textPrimary,
          ),
          onPressed: () {
            context.push(_targetRoute(AppRoutes.browseProfiles));
          },
        ),
        Consumer<NotificationProvider>(
          builder: (context, notificationProvider, child) {
            final count = notificationProvider.unreadCount;
            return Badge(
              isLabelVisible: count > 0,
              alignment: Alignment.topRight,
              offset: const Offset(-4, 4),
              backgroundColor: Theme.of(context).primaryColor,
              label: Text(
                count > 99 ? '99+' : count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.notifications_active_outlined,
                  color:
                      Theme.of(context).textTheme.bodyLarge?.color ??
                      AppColors.textPrimary,
                ),
                onPressed: () {
                  setState(() {
                    _showNotifications = true;
                  });
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    if (kIsWeb && MediaQuery.of(context).size.width < 800) {
      // Mobile Web Navigation Items
      return CustomBottomBar(
        selectedIndex: _selectedIndex,
        onTap: _onTabTapped,
        onCenterTap: () {
          context.push(_targetRoute(AppRoutes.lpaGuide));
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            label: 'Discover',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      );
    }

    // Native Mobile Navigation Items
    return CustomBottomBar(
      selectedIndex: _selectedIndex,
      onTap: _onTabTapped,
      onCenterTap: () {
        context.push(_targetRoute(AppRoutes.lpaGuide));
      },
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
          icon: Icon(Icons.chat_bubble_outline),
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
    Widget content;
    if (_showNotifications) {
      content = NotificationScreen(
        onBack: () {
          setState(() {
            _showNotifications = false;
          });
        },
      );
    } else {
      if (kIsWeb && MediaQuery.of(context).size.width < 800) {
        // Mobile Web screens mapping (2 tabs)
        switch (_selectedIndex) {
          case 0:
            content = const DiscoverScreen();
            break;
          case 1:
            content = const ProfileScreen();
            break;
          default:
            content = const DiscoverScreen();
        }
      } else {
        // Native Mobile screens mapping (4 tabs)
        switch (_selectedIndex) {
          case 0:
            content = const DiscoverScreen();
            break;
          case 1:
            content = const LikedMatchesScreen();
            break;
          case 2:
            content = const ChatPlaceholderScreen();
            break;
          case 3:
            content = const ProfileScreen();
            break;
          default:
            content = const DiscoverScreen();
        }
      }
    }

    return NotificationListener<UserScrollNotification>(
      onNotification: (notification) {
        if (notification.direction == ScrollDirection.reverse) {
          if (_isBottomNavVisible) {
            setState(() => _isBottomNavVisible = false);
          }
        } else if (notification.direction == ScrollDirection.forward) {
          if (!_isBottomNavVisible) {
            setState(() => _isBottomNavVisible = true);
          }
        }
        return false;
      },
      child: content,
    );
  }
}
