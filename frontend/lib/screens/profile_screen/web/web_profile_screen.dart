import 'package:life_partner_again/core/app_routes.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/main.dart';
import 'package:life_partner_again/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../widgets/bottomsheet/logout_bottom_sheet.dart';
import '../../../widgets/custom_button.dart';
import '../widgets/profile_controller.dart';

class WebProfileScreen extends StatefulWidget {
  const WebProfileScreen({super.key});

  @override
  State<WebProfileScreen> createState() => _WebProfileScreenState();
}

class _WebProfileScreenState extends State<WebProfileScreen>
    with RouteAware, ProfileControllerState<WebProfileScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    subscribeToRoute(routeObserver);
  }

  @override
  void dispose() {
    unsubscribeFromRoute(routeObserver);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || user == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Profile Card
              Container(
                width: 340,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 40,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(
                    color: AppColors.borderColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          width: 4,
                        ),
                        color: AppColors.surface,
                      ),
                      child: ClipOval(
                        child: primaryImage != null
                            ? CachedNetworkImage(
                                imageUrl: primaryImage!.imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    const CircularProgressIndicator(
                                      color: AppColors.primary,
                                    ),
                                errorWidget: (context, url, error) =>
                                    const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: AppColors.textSecondary,
                                    ),
                              )
                            : const Icon(
                                Icons.person,
                                size: 80,
                                color: AppColors.textSecondary,
                              ),
                      ),
                    ).animate().scale(
                      duration: 400.ms,
                      curve: Curves.easeOutBack,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      user!.name ?? "Your Name",
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        user!.email ?? "your.email@example.com",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 48),
                    CustomButton(
                      onPressed: () {
                        LogoutBottomSheet.show(
                          context: context,
                          onLogoutConfirm: () async {
                            final sharedPrefs =
                                await SharedPreferences.getInstance();
                            await sharedPrefs.clear();
                            if (context.mounted) {
                              await context.read<AuthProvider>().logout();
                            }
                          },
                        );
                      },
                      text: "Logout",
                      type: CustomButtonType.outline,
                      textColor:
                          Colors.red, // Use red for logout to make it distinct
                      height: 52,
                      borderRadius: 16,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ).animate().fadeIn(delay: 300.ms),
                  ],
                ),
              ),
              const SizedBox(width: 40),
              // Right Column: Settings
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -1.0,
                        ),
                      ).animate().fadeIn().slideX(begin: 0.1),
                      const SizedBox(height: 32),

                      _buildSettingsCard(
                        title: "Account",
                        children: [
                          _buildWebActionItem(
                            icon: Icons.person_outline,
                            title: "Edit Profile Info",
                            subtitle: "Update your personal details and bio",
                            onTap: () async {
                              if (user != null) {
                                final result = await context.push(
                                  AppRoutes.editProfile,
                                  extra: user,
                                );
                                if (result == true) fetchProfileData();
                              }
                            },
                          ),
                          _buildWebActionItem(
                            icon: Icons.photo_library_outlined,
                            title: "Manage Profile Pictures",
                            subtitle: "Add or remove photos from your gallery",
                            showDivider: false,
                            onTap: () async {
                              final result = await context.push(
                                AppRoutes.manageProfilePictures,
                              );
                              if (result == true) fetchProfileData();
                            },
                          ),
                        ],
                      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

                      const SizedBox(height: 24),

                      _buildSettingsCard(
                        title: "Subscription",
                        children: [
                          _buildWebActionItem(
                            icon: Icons.star_outline,
                            title: "My Subscription",
                            subtitle: "Manage your premium plan",
                            showDivider: false,
                            onTap: () {
                              context.push(AppRoutes.subscription);
                            },
                          ),
                        ],
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                      const SizedBox(height: 24),

                      _buildSettingsCard(
                        title: "Privacy & Security",
                        children: [
                          _buildWebSwitchItem(
                            icon: Icons.shield_outlined,
                            title: "Private Account",
                            subtitle:
                                "Only approved matches can see your photos",
                            value: user?.privacyEnabled ?? false,
                            isItemLoading: isUpdatingPrivacy,
                            onChanged: (value) => togglePrivacy(value),
                            showDivider: true,
                          ),
                          _buildWebActionItem(
                            icon: Icons.lock_open_outlined,
                            title: "Image Access Requests",
                            subtitle: "Manage who can view your private photos",
                            showDivider: false,
                            onTap: () {
                              context.push(AppRoutes.imageAccessRequests);
                            },
                          ),
                        ],
                      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

                      const SizedBox(height: 24),

                      _buildSettingsCard(
                        title: "Support",
                        children: [
                          _buildWebActionItem(
                            icon: Icons.help_outline,
                            title: "Help & Support",
                            subtitle: "Get assistance and view FAQs",
                            showDivider: false,
                            onTap: () {},
                          ),
                        ],
                      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: AppColors.borderColor.withValues(alpha: 0.5),
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildWebActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          hoverColor: AppColors.primary.withValues(alpha: 0.03),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: AppColors.textSecondary.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: 84, // aligns with text
            endIndent: 24,
            color: AppColors.borderColor.withValues(alpha: 0.5),
          ),
      ],
    );
  }

  Widget _buildWebSwitchItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required bool isItemLoading,
    required ValueChanged<bool> onChanged,
    bool showDivider = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isItemLoading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Switch(
                  value: value,
                  onChanged: onChanged,
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
                  activeThumbColor: AppColors.primary,
                ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: 84, // aligns with text
            endIndent: 24,
            color: AppColors.borderColor.withValues(alpha: 0.5),
          ),
      ],
    );
  }
}
