import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mylifepartner/core/app_colors.dart';
import 'package:mylifepartner/screens/login_screen/login_screen.dart';
import 'package:mylifepartner/screens/profile_screen/profile_screen.dart';
import 'package:mylifepartner/screens/questionaire_screen/questionaire_screen.dart';
import 'package:mylifepartner/services/profile_repository.dart';
import 'package:mylifepartner/shared/widgets/custom_bottom_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/custom_bottom_bar.dart';
import '../../shared/widgets/custom_button.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final ProfileRepository _profileRepository = ProfileRepository();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkProfileCompletion();
    });
  }

  Future<void> _checkProfileCompletion() async {
    try {
      final status = await _profileRepository.getCompletionStatus();
      if (status['isCompleted'] == false) {
        if (mounted) {
          CustomBottomSheet.show(
            context: context,
            type: BottomSheetType.info,
            title: "Complete Your Profile",
            message:
                "You have pending profile questions. Complete them to find better matches.",
            primaryButtonText: "Continue",
            onPrimaryPressed: () {
              Navigator.pop(context); // Close bottom sheet
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuestionaireScreen(
                    isPrimaryFlow: false,
                    initialSectionOrder: status['nextPendingSectionOrder'],
                  ),
                ),
              );
            },
            secondaryButtonText: "Later",
            onSecondaryPressed: () {
              Navigator.pop(context);
            },
          );
        }
      }
    } catch (e) {
      debugPrint("Error checking profile completion: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWeb = constraints.maxWidth > 900;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: isWeb ? _buildWebAppBar() : _buildMobileAppBar(),
          body: Row(
            children: [
              if (isWeb) _buildNavigationRail(),
              Expanded(
                child: SafeArea(
                  child: _selectedIndex == 3
                      ? const ProfileScreen()
                      : SingleChildScrollView(
                          child: Padding(
                            padding: EdgeInsets.all(isWeb ? 40.0 : 20.0),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 1200,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildHeader(isWeb),
                                    const SizedBox(height: 32),
                                    _buildPremiumCard(isWeb),
                                    const SizedBox(height: 48),
                                    _buildMatchesSection(isWeb),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: isWeb ? null : _buildBottomNavigationBar(),
        );
      },
    );
  }

  PreferredSizeWidget _buildMobileAppBar() {
    return CustomAppBar(
      title: 'My Life Partner',
      showLeading: false,
      actions: [
        IconButton(
          icon: const Icon(
            Icons.exit_to_app_outlined,
            color: AppColors.textPrimary,
          ),
          onPressed: () async {
            final sharedPrefs = await SharedPreferences.getInstance();
            sharedPrefs.clear();
            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                ModalRoute.withName('/'),
              );
            }
          },
        ),
      ],
    );
  }

  PreferredSizeWidget _buildWebAppBar() {
    return CustomAppBar(
      title: 'My Life Partner',
      showLeading: false,
      toolbarHeight: 80,
      elevation: 0.5,
      titleStyle: GoogleFonts.poppins(
        fontWeight: FontWeight.bold,
        fontSize: 24,
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.notifications_outlined,
            color: AppColors.textPrimary,
          ),
          onPressed: () {},
        ),
        const SizedBox(width: 20),
        const CircleAvatar(
          radius: 20,
          backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=me'),
        ),
        const SizedBox(width: 40),
      ],
      leading: const Padding(padding: EdgeInsets.only(left: 20)),
    );
  }

  Widget _buildNavigationRail() {
    return NavigationRail(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (int index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      labelType: NavigationRailLabelType.all,
      backgroundColor: AppColors.background,
      selectedIconTheme: IconThemeData(color: AppColors.primary),
      unselectedIconTheme: const IconThemeData(color: AppColors.unselectedIcon),
      selectedLabelTextStyle: GoogleFonts.poppins(
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: GoogleFonts.poppins(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.home_filled),
          label: Text('Home'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.favorite_border),
          label: Text('Matches'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.message_outlined),
          label: Text('Chat'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.person_outline),
          label: Text('Profile'),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return CustomBottomBar(
      selectedIndex: _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
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

  Widget _buildHeader(bool isWeb) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Find your\nPerfect Match",
          style: GoogleFonts.poppins(
            fontSize: isWeb ? 48 : 32,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Someone special is waiting for you.",
          style: GoogleFonts.poppins(
            fontSize: isWeb ? 18 : 16,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumCard(bool isWeb) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isWeb ? 40 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Premium Membership",
                  style: GoogleFonts.poppins(
                    color: AppColors.onPrimary,
                    fontSize: isWeb ? 28 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Unlock all features and find your match faster with priority listing.",
                  style: GoogleFonts.poppins(
                    color: AppColors.onPrimary.withValues(alpha: 0.8),
                    fontSize: isWeb ? 18 : 14,
                  ),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  onPressed: () {
                    CustomBottomSheet.show(
                      context: context,
                      type: BottomSheetType.confirmation,
                      title: "Upgrade Now",
                      message: "Thank you for doing this",
                      primaryButtonText: "Continue",
                      onPrimaryPressed: () {
                        Navigator.pop(context);
                      },
                    );
                  },
                  text: "Upgrade Now",
                  type: CustomButtonType.secondary,
                  backgroundColor: AppColors.surface,
                  textColor: AppColors.primary,
                  width: null,
                  height: 48,
                  borderRadius: 12,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ],
            ),
          ),
          if (isWeb) const SizedBox(width: 40),
          Icon(
            Icons.workspace_premium_rounded,
            color: AppColors.textWhite,
            size: isWeb ? 120 : 60,
          ),
        ],
      ),
    );
  }

  Widget _buildMatchesSection(bool isWeb) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                "Recommended Matches",
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                "See all",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        isWeb ? _buildWebGrid() : _buildMobileList(),
      ],
    );
  }

  Widget _buildWebGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: 0.8,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => _buildMatchCard(index, true),
    );
  }

  Widget _buildMobileList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) => _buildMatchCard(index, false),
    );
  }

  Widget _buildMatchCard(int index, bool isWeb) {
    final names = [
      "Sarah Johnson",
      "Michael Chen",
      "Emma Wilson",
      "David Smith",
      "Sophia Lee",
      "James Brown",
    ];
    final ages = ["26", "29", "25", "31", "27", "30"];
    final locations = [
      "New York, NY",
      "San Francisco, CA",
      "London, UK",
      "Austin, TX",
      "Seattle, WA",
      "Chicago, IL",
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Image.network(
              'https://i.pravatar.cc/300?u=$index',
              height: isWeb ? 220 : 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${names[index % names.length]}, ${ages[index % ages.length]}",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Icon(
                      Icons.favorite_border,
                      color: AppColors.unselectedIcon,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: AppColors.unselectedIcon,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      locations[index % locations.length],
                      style: GoogleFonts.poppins(
                        color: AppColors.unselectedIcon,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    onPressed: () {},
                    text: "View Profile",
                    type: CustomButtonType.secondary,
                    height: 48,
                    borderRadius: 12,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
