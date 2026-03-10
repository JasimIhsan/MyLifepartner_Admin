import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mylifepartner/core/app_colors.dart';
import 'package:mylifepartner/models/match_recommendation.dart';
import 'package:mylifepartner/providers/match_provider.dart';
import 'package:mylifepartner/screens/login_screen/login_screen.dart';
import 'package:mylifepartner/screens/home_screen/widgets/profile_swipe_card.dart';
import 'package:mylifepartner/screens/home_screen/widgets/swipe_action_buttons.dart';
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

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  final ProfileRepository _profileRepository = ProfileRepository();
  bool _isSheetShowing = false;

  // Swipe overlay animation
  late AnimationController _overlayController;
  late Animation<double> _overlayOpacity;
  _OverlayType? _overlayType;

  @override
  void initState() {
    super.initState();

    _overlayController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _overlayOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _overlayController, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkProfileCompletion();
      context.read<MatchProvider>().loadRecommendations();
    });
  }

  @override
  void dispose() {
    _overlayController.dispose();
    super.dispose();
  }

  // ─── Profile completion check (from original home screen) ──────────────────

  Future<void> _checkProfileCompletion() async {
    if (_isSheetShowing) return;
    try {
      final status = await _profileRepository.getCompletionStatus();
      if (status['isCompleted'] == false) {
        if (mounted && !_isSheetShowing) {
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
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuestionaireScreen(
                    isPrimaryFlow: false,
                    initialSectionOrder: status['nextPendingSectionOrder'],
                  ),
                ),
              ).then((_) => _checkProfileCompletion());
            },
            secondaryButtonText: "Later",
            onSecondaryPressed: () => Navigator.pop(context),
          );
          _isSheetShowing = false;
        }
      }
    } catch (e) {
      debugPrint("Error checking profile completion: $e");
    }
  }

  // ─── Swipe overlay helpers ─────────────────────────────────────────────────

  Future<void> _showOverlayAndSwipe(
    _OverlayType type,
    Future<void> Function() swipeFn,
  ) async {
    setState(() => _overlayType = type);
    await _overlayController.forward();
    await swipeFn();
    await _overlayController.reverse();
    if (mounted) setState(() => _overlayType = null);
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
    if (index == 0) _checkProfileCompletion();
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
      title: 'Life Partner Again',
      showLeading: false,
      actions: [
        IconButton(
          icon: const Icon(
            Icons.notifications_outlined,
            color: AppColors.textPrimary,
          ),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(
            Icons.exit_to_app_outlined,
            color: AppColors.textPrimary,
          ),
          onPressed: _logout,
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
    switch (_selectedIndex) {
      case 3:
        return const ProfileScreen();
      case 0:
      default:
        return _buildDiscoverTab();
    }
  }

  // ─── Discover Tab (Swipe UI) ───────────────────────────────────────────────

  Widget _buildDiscoverTab() {
    return Consumer<MatchProvider>(
      builder: (context, provider, _) {
        if (provider.state == MatchLoadState.loading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 16),
                Text(
                  'Finding your matches…',
                  style: TextStyle(color: Color(0xFF9E9E9E)),
                ),
              ],
            ),
          );
        }

        if (provider.state == MatchLoadState.error) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  size: 64,
                  color: Color(0xFF9E9E9E),
                ),
                const SizedBox(height: 16),
                Text(
                  'Could not load matches',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: provider.loadRecommendations,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          );
        }

        if (!provider.hasProfiles) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.search_off_rounded,
                  size: 64,
                  color: Color(0xFF9E9E9E),
                ),
                const SizedBox(height: 16),
                Text(
                  'No more matches right now',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Check back soon for new profiles',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: provider.loadRecommendations,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return _buildSwipeStack(provider);
      },
    );
  }

  Widget _buildSwipeStack(MatchProvider provider) {
    final profiles = provider.profiles;
    final currentIndex = provider.currentIndex;
    final visibleCount = (profiles.length - currentIndex).clamp(0, 3);

    // Responsive vertical padding for the action buttons row:
    // give a little more breathing room on tall screens.
    final screenHeight = MediaQuery.of(context).size.height;
    final buttonsPadding = (screenHeight * 0.022).clamp(10.0, 24.0);

    return Column(
      children: [
        // ── Section header ───────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Discover',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${profiles.length - currentIndex} profiles',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        // ── Card stack ───────────────────────────────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                for (int i = visibleCount - 1; i >= 1; i--)
                  _buildBehindCard(profiles[currentIndex + i], i),

                _buildDraggableCard(profiles[currentIndex], provider),

                if (_overlayType != null) _buildActionOverlay(),
              ],
            ),
          ),
        ),

        // ── Action buttons ───────────────────────────────────────────
        Padding(
          padding: EdgeInsets.symmetric(vertical: buttonsPadding),
          child: SwipeActionButtons(
            onNotInterested: () =>
                _showOverlayAndSwipe(_OverlayType.left, provider.swipeLeft),
            onSkip: () =>
                _showOverlayAndSwipe(_OverlayType.up, provider.swipeUp),
            onInterested: () =>
                _showOverlayAndSwipe(_OverlayType.right, provider.swipeRight),
          ),
        ),
      ],
    );
  }

  Widget _buildBehindCard(MatchRecommendation profile, int depth) {
    return Transform.translate(
      offset: Offset(0, depth * 12.0),
      child: Transform.scale(
        scale: 1.0 - depth * 0.04,
        child: IgnorePointer(
          child: Opacity(
            opacity: 0.7,
            child: ProfileSwipeCard(profile: profile),
          ),
        ),
      ),
    );
  }

  Widget _buildDraggableCard(
    MatchRecommendation profile,
    MatchProvider provider,
  ) {
    return Dismissible(
      key: ValueKey(profile.id),
      direction: DismissDirection.horizontal,
      resizeDuration: null,
      dismissThresholds: const {
        DismissDirection.startToEnd: 0.35,
        DismissDirection.endToStart: 0.35,
      },
      background: _swipeBackground(isRight: true),
      secondaryBackground: _swipeBackground(isRight: false),
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          _showOverlayAndSwipe(_OverlayType.right, provider.swipeRight);
        } else {
          _showOverlayAndSwipe(_OverlayType.left, provider.swipeLeft);
        }
      },
      child: ProfileSwipeCard(
        profile: profile,
        onViewProfile: () {
          // TODO: Navigate to ProfileDetailsScreen(profileId: profile.id)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Opening ${profile.name}\'s profile')),
          );
        },
      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.04, end: 0),
    );
  }

  Widget _swipeBackground({required bool isRight}) {
    return Container(
      alignment: isRight ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isRight
            ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
            : const Color(0xFFFF5252).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Icon(
        isRight ? Icons.favorite : Icons.close,
        color: isRight ? const Color(0xFF4CAF50) : const Color(0xFFFF5252),
        size: 44,
      ),
    );
  }

  Widget _buildActionOverlay() {
    final isLeft = _overlayType == _OverlayType.left;
    final isRight = _overlayType == _OverlayType.right;

    IconData icon = isLeft
        ? Icons.close
        : isRight
        ? Icons.favorite
        : Icons.skip_next_rounded;
    Color color = isLeft
        ? const Color(0xFFFF5252)
        : isRight
        ? const Color(0xFF4CAF50)
        : const Color(0xFF9E9E9E);
    String label = isLeft
        ? 'Not Interested'
        : isRight
        ? 'Interested!'
        : 'Skipped';

    return AnimatedBuilder(
      animation: _overlayOpacity,
      builder: (_, __) => Opacity(
        opacity: _overlayOpacity.value,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 56),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _OverlayType { left, right, up }
