import 'package:life_partner_again/core/app_routes.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:life_partner_again/main.dart';
import 'package:life_partner_again/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:life_partner_again/core/app_colors.dart';

import '../../../widgets/bottomsheet/logout_bottom_sheet.dart';
import '../../../widgets/custom_button.dart';
import '../widgets/profile_controller.dart';

class MobileProfileScreen extends StatefulWidget {
  const MobileProfileScreen({super.key});

  @override
  State<MobileProfileScreen> createState() => _MobileProfileScreenState();
}

class _MobileProfileScreenState extends State<MobileProfileScreen>
    with RouteAware, ProfileControllerState<MobileProfileScreen> {
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

  Widget _buildSkeleton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 12.0,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.borderColor,
                              width: 2,
                            ),
                            color: Colors.grey.shade300,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          width: 140,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 200,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 40),
                        _skeletonSection(),
                        _skeletonSection(),
                        _skeletonSection(),
                        _skeletonSection(),
                        const SizedBox(height: 24),
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _skeletonSection() {
    return Column(
      children: [
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
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(width: 16),
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
    if (isLoading || user == null) {
      return _buildSkeleton();
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
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
                    primaryImage != null
                        ? ClipOval(
                            child: CachedNetworkImage(
                              width: 140,
                              height: 140,
                              imageUrl: primaryImage!.imageUrl,
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
              user!.name ?? "Your Name",
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user!.email ?? "your.email@example.com",
              style: const TextStyle(
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
                  if (user != null) {
                    final result = await context.push(
                      AppRoutes.editProfile,
                      extra: user,
                    );
                    if (result == true) {
                      fetchProfileData();
                    }
                  }
                },
              ),
              _buildActionItem(
                icon: Icons.photo_library_outlined,
                title: "Manage Profile Pictures",
                showDivider: false,
                onTap: () async {
                  final result = await context.push(
                    AppRoutes.manageProfilePictures,
                  );
                  if (result == true) {
                    fetchProfileData();
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
                  context.push(AppRoutes.subscription);
                },
              ),
            ]),
            _buildSectionHeader("Privacy & Security"),
            _buildActionGroup([
              _buildSwitchItem(
                icon: Icons.shield_outlined,
                title: "Private Account",
                subtitle: "Only approved matches can see your photos",
                value: user?.privacyEnabled ?? false,
                isItemLoading: isUpdatingPrivacy,
                onChanged: (value) => togglePrivacy(value),
                showDivider: true,
              ),
              _buildActionItem(
                icon: Icons.lock_open_outlined,
                title: "Image Access Requests",
                showDivider: false,
                onTap: () {
                  context.push(AppRoutes.imageAccessRequests);
                },
              ),
            ]),

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
                        await context.read<AuthProvider>().logout();
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
            const SizedBox(height: 100),
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
          style: const TextStyle(
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
                    style: const TextStyle(
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
            indent: 56,
            color: AppColors.divider,
          ),
      ],
    );
  }

  Widget _buildSwitchItem({
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
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
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                  activeThumbColor: AppColors.primary,
                ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 1,
            indent: 56,
            color: AppColors.divider,
          ),
      ],
    );
  }
}
