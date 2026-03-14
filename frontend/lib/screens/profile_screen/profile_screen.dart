import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mylifepartner/core/app_colors.dart';
import 'package:mylifepartner/models/auth_response.dart';
import 'package:mylifepartner/models/user_image.dart';
import 'package:mylifepartner/screens/profile_screen/edit_profile_screen.dart';
import 'package:mylifepartner/services/profile_repository.dart';
import 'package:mylifepartner/services/user_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/widgets/custom_bottom_sheet.dart';
import '../../shared/widgets/custom_button.dart';
import '../login_screen/login_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: _primaryImage != null
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: _primaryImage!.imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  const CircularProgressIndicator(),
                              errorWidget: (context, url, error) => const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            size: 80,
                            color: Colors.grey,
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _user!.name ?? "Your Name",
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _user!.email ?? "your.email@example.com",
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
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
              onTap: () async {
                // Import manage_profile_pictures_screen.dart at the top of file
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
            _buildActionItem(
              icon: Icons.settings_outlined,
              title: "Settings",
              onTap: () {},
            ),
            _buildActionItem(
              icon: Icons.notifications_outlined,
              title: "Notifications",
              onTap: () {},
            ),
            _buildActionItem(
              icon: Icons.help_outline,
              title: "Help & Support",
              onTap: () {},
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                onPressed: () {
                  CustomBottomSheet.show(
                    context: context,
                    type: BottomSheetType.confirmation,
                    title: "Logout",
                    message: "Are you sure you want to logout?",
                    primaryButtonText: "Logout",
                    onPrimaryPressed: () async {
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
                type: CustomButtonType.secondary,
                backgroundColor: Colors.black.withValues(alpha: 0.1),
                textColor: Colors.black,
                height: 54,
                borderRadius: 16,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 18,
          color: AppColors.textSecondary,
        ),
        onTap: onTap,
      ),
    );
  }
}
