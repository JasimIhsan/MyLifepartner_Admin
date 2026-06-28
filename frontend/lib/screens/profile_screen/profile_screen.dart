import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mylifepartner/core/app_colors.dart';
import 'package:mylifepartner/models/auth_response.dart';
import 'package:mylifepartner/models/user_image.dart';
import 'package:mylifepartner/screens/profile_screen/edit_profile_screen.dart';
import 'package:mylifepartner/services/profile_repository.dart';
import 'package:mylifepartner/services/user_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/logout_bottom_sheet.dart';
import '../login_screen/login_screen.dart';
import '../subscription_screen/subscription_screen.dart';
import 'manage_profile_pictures_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserRepository _userRepository = UserRepository();
  final ProfileRepository _profileRepository = ProfileRepository();

  User? _user;
  UserImage? _primaryImage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final user = await _userRepository.getUser();
      final images = await _profileRepository.getUserImages();

      UserImage? primaryImg;
      try {
        primaryImg = images.firstWhere((img) => img.isPrimary);
      } catch (_) {
        if (images.isNotEmpty) {
          primaryImg = images.first;
        }
      }

      setState(() {
        _user = user;
        _primaryImage = primaryImg;
      });
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Column(
          children: [
            const SizedBox(height: 20),

            /// 🔵 Profile Image (exact match)
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderColor, width: 2),
                color: Colors.grey.shade300,
              ),
            ),

            const SizedBox(height: 24),

            /// 🔤 Name
            Container(
              width: 140,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
            ),

            const SizedBox(height: 6),

            /// 📧 Email
            Container(
              width: 200,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
            ),

            const SizedBox(height: 40),

            /// 🧩 Section 1 (Account)
            _skeletonSection(),

            /// 🧩 Section 2 (Subscription)
            _skeletonSection(),

            /// 🧩 Section 3 (Preferences)
            _skeletonSection(),

            /// 🧩 Section 4 (Support)
            _skeletonSection(),

            const SizedBox(height: 24),

            /// 🔘 Logout button
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderColor),
                color: Colors.grey.shade200,
              ),
            ),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _skeletonSection() {
    return Column(
      children: [
        /// Section title
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 100,
            height: 12,
            margin: const EdgeInsets.only(bottom: 8, left: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),

        /// Card container (matches your real container)
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderColor, width: 1.2),
          ),
          child: Column(
            children: List.generate(2, (index) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        /// Icon placeholder
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(width: 16),

                        /// Text placeholder
                        Expanded(
                          child: Container(
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),

                        const SizedBox(width: 16),

                        /// Arrow placeholder
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (index == 0)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      indent: 56,
                      color: AppColors.divider,
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _user == null) {
      return _buildSkeleton();
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderColor, width: 2),
                  color: AppColors.surface,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _primaryImage != null
                        ? ClipOval(
                            child: CachedNetworkImage(
                              width: 140,
                              height: 140,
                              imageUrl: _primaryImage!.imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  const CircularProgressIndicator(
                                    color: AppColors.primary,
                                  ),
                              errorWidget: (context, url, error) => const Icon(
                                Icons.person,
                                size: 50,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            size: 70,
                            color: AppColors.textSecondary,
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _user!.name ?? "Your Name",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _user!.email ?? "your.email@example.com",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 40),

            _buildSectionHeader("Account"),
            _buildActionGroup([
              _buildActionItem(
                icon: Icons.person_outline,
                title: "Edit Profile Info",
                onTap: () async {
                  if (_user != null) {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfileScreen(user: _user!),
                      ),
                    );
                    if (result == true) {
                      _fetchProfileData(); // Refresh data after update
                    }
                  }
                },
              ),
              _buildActionItem(
                icon: Icons.photo_library_outlined,
                title: "Manage Profile Pictures",
                showDivider: false,
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ManageProfilePicturesScreen(),
                    ),
                  );
                  if (result == true) {
                    _fetchProfileData(); // Refresh data after update
                  }
                },
              ),
            ]),

            _buildSectionHeader("Subscription"),
            _buildActionGroup([
              _buildActionItem(
                icon: Icons.star_outline,
                title: "My Subscription",
                showDivider: false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SubscriptionScreen(),
                    ),
                  );
                },
              ),
            ]),

            // _buildSectionHeader("Preferences"),
            // _buildActionGroup([
            //   _buildActionItem(
            //     icon: Icons.settings_outlined,
            //     title: "Settings",
            //     onTap: () {},
            //   ),
            //   _buildActionItem(
            //     icon: Icons.notifications_outlined,
            //     title: "Notifications",
            //     showDivider: false,
            //     onTap: () {},
            //   ),
            // ]),
            _buildSectionHeader("Support"),
            _buildActionGroup([
              _buildActionItem(
                icon: Icons.help_outline,
                title: "Help & Support",
                showDivider: false,
                onTap: () {},
              ),
            ]),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                onPressed: () {
                  LogoutBottomSheet.show(
                    context: context,
                    onLogoutConfirm: () async {
                      final sharedPrefs = await SharedPreferences.getInstance();
                      await sharedPrefs.clear();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                          (route) => false,
                        );
                      }
                    },
                  );
                },
                text: "Logout",
                type: CustomButtonType.outline,
                textColor: AppColors.primary,
                height: 56,
                borderRadius: 16,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildActionGroup(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor, width: 1.2),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 22),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 1,
            indent: 56, // aligns with text
            color: AppColors.divider,
          ),
      ],
    );
  }
}
