import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/core/app_routes.dart';
import 'package:life_partner_again/main.dart';
import 'package:life_partner_again/providers/auth_provider.dart';
import 'package:life_partner_again/providers/theme_provider.dart';
import 'package:life_partner_again/services/api_service.dart';
import 'package:life_partner_again/services/user_repository.dart';
import 'package:life_partner_again/widgets/founding_member_badge.dart';
import 'package:life_partner_again/widgets/verified_profile_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
                              color: Theme.of(context).dividerColor,
                              width: 2,
                            ),
                            color: Theme.of(
                              context,
                            ).disabledColor.withValues(alpha: 0.1),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          width: 140,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).disabledColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 200,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).disabledColor.withValues(alpha: 0.1),
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
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                            ),
                            color: Theme.of(
                              context,
                            ).disabledColor.withValues(alpha: 0.05),
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
              color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 1.2,
            ),
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
                            color: Theme.of(
                              context,
                            ).disabledColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            height: 14,
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).disabledColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).disabledColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (index == 0)
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: 56,
                      color: Theme.of(context).dividerColor,
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
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                    width: 2,
                  ),
                  color: Theme.of(context).colorScheme.surface,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    primaryImage != null
                        ? GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                PageRouteBuilder(
                                  opaque: false,
                                  pageBuilder: (BuildContext context, _, __) {
                                    return Scaffold(
                                      backgroundColor: Colors.black,
                                      appBar: AppBar(
                                        backgroundColor: Colors.black,
                                        elevation: 0,
                                        iconTheme: const IconThemeData(
                                          color: Colors.white,
                                        ),
                                      ),
                                      body: SafeArea(
                                        child: Center(
                                          child: InteractiveViewer(
                                            panEnabled: true,
                                            minScale: 0.5,
                                            maxScale: 4.0,
                                            child: CachedNetworkImage(
                                              imageUrl: primaryImage!.imageUrl,
                                              fit: BoxFit.contain,
                                              placeholder: (context, url) =>
                                                  CircularProgressIndicator(
                                                    color: Theme.of(
                                                      context,
                                                    ).primaryColor,
                                                  ),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      const Icon(
                                                        Icons.error,
                                                        color: Colors.white,
                                                      ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                            child: ClipOval(
                              child: CachedNetworkImage(
                                width: 140,
                                height: 140,
                                imageUrl: primaryImage!.imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    CircularProgressIndicator(
                                      color: Theme.of(context).primaryColor,
                                    ),
                                errorWidget: (context, url, error) => Icon(
                                  Icons.person,
                                  size: 50,
                                  color:
                                      Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color ??
                                      Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color ??
                                      AppColors.textSecondary,
                                ),
                              ),
                            ),
                          )
                        : Icon(
                            Icons.person,
                            size: 70,
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color ??
                                Theme.of(context).textTheme.bodyMedium?.color ??
                                AppColors.textSecondary,
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      user!.name ?? "Your Name",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        color:
                            Theme.of(context).textTheme.bodyLarge?.color ??
                            Theme.of(context).textTheme.bodyLarge?.color ??
                            AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (user!.isVerified) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (_) => VerifiedProfileBottomSheet(
                            profileName: user!.name ?? "Your Name",
                          ),
                        );
                      },
                      child: Image.asset(
                        'assets/icons/verified_icon.png',
                        width: 22,
                        height: 22,
                      ),
                    ),
                  ],
                  if (user!.isFoundingMember) ...[
                    const SizedBox(width: 6),
                    const FoundingMemberBadge(size: 22),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user!.email ?? "your.email@example.com",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color:
                    Theme.of(context).textTheme.bodyMedium?.color ??
                    Theme.of(context).textTheme.bodyMedium?.color ??
                    AppColors.textSecondary,
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
                icon: Icons.tune_rounded,
                title: "Edit Partner Preferences",
                onTap: () async {
                  final result = await context.push(
                    AppRoutes.editPartnerPreference,
                  );
                  if (result == true) {
                    fetchProfileData();
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
                showDivider: true,
                onTap: () {
                  context.push(AppRoutes.imageAccessRequests);
                },
              ),
              _buildActionItem(
                icon: Icons.block,
                title: "Blocked Users",
                showDivider: false,
                onTap: () {
                  context.push(AppRoutes.blockedUsers);
                },
              ),
            ]),

            _buildSectionHeader("Appearance"),
            _buildActionGroup([
              _buildSwitchItem(
                icon: Icons.dark_mode_outlined,
                title: "Dark Mode",
                subtitle: "Toggle dark theme for the app",
                value: context.watch<ThemeProvider>().isDarkMode,
                isItemLoading: false,
                onChanged: (value) =>
                    context.read<ThemeProvider>().toggleTheme(value),
                showDivider: false,
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
                textColor: Theme.of(context).primaryColor,
                height: 56,
                borderRadius: 16,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                onPressed: () => _showDeleteAccountBottomSheet(context),
                text: "Delete Account",
                type: CustomButtonType.outline,
                textColor: Colors.red,
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
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
            color:
                Theme.of(context).textTheme.bodyMedium?.color ??
                Theme.of(context).textTheme.bodyMedium?.color ??
                AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildActionGroup(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1.2),
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
                Icon(icon, color: Theme.of(context).primaryColor, size: 22),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color:
                          Theme.of(context).textTheme.bodyLarge?.color ??
                          Theme.of(context).textTheme.bodyLarge?.color ??
                          AppColors.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color:
                      Theme.of(context).textTheme.bodyMedium?.color ??
                      Theme.of(context).textTheme.bodyMedium?.color ??
                      AppColors.textSecondary.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: 56,
            color: Theme.of(context).dividerColor,
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
              Icon(icon, color: Theme.of(context).primaryColor, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color:
                            Theme.of(context).textTheme.bodyLarge?.color ??
                            Theme.of(context).textTheme.bodyLarge?.color ??
                            AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            Theme.of(context).textTheme.bodyMedium?.color ??
                            Theme.of(context).textTheme.bodyMedium?.color ??
                            AppColors.textSecondary,
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
                  activeTrackColor: Theme.of(
                    context,
                  ).primaryColor.withValues(alpha: 0.5),
                  activeThumbColor: Theme.of(context).primaryColor,
                ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: 56,
            color: Theme.of(context).dividerColor,
          ),
      ],
    );
  }

  void _showDeleteAccountBottomSheet(BuildContext context) {
    final reasonController = TextEditingController();
    const deletionReasons = [
      'Found my partner',
      'Privacy concerns',
      'Not useful for me',
      'Too many notifications',
      'Taking a break',
      'Other',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (BuildContext sheetContext) {
        bool isLoading = false;
        bool isSent = false;
        String? reasonError;
        String? selectedReason;

        return StatefulBuilder(
          builder: (context, setState) {
            final theme = Theme.of(context);
            final textColor =
                theme.textTheme.bodyLarge?.color ?? AppColors.textPrimary;
            final mutedTextColor =
                theme.textTheme.bodyMedium?.color ?? AppColors.textSecondary;
            final dangerColor = AppColors.error;
            final successColor = AppColors.success;
            return SafeArea(
              top: false,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 14,
                    bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 46,
                          height: 5,
                          decoration: BoxDecoration(
                            color: theme.dividerColor,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (isSent ? successColor : dangerColor)
                                .withValues(alpha: 0.12),
                          ),
                          child: Icon(
                            isSent
                                ? Icons.mark_email_read_rounded
                                : Icons.delete_forever_rounded,
                            color: isSent ? successColor : dangerColor,
                            size: 34,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        isSent ? 'Check your email' : 'Delete account?',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isSent
                            ? 'We sent a confirmation link to your email. Open it to verify your deletion request.'
                            : 'Tell us why you are leaving before we send the verification email.',
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.45,
                          color: mutedTextColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      if (isSent)
                        CustomButton(
                          text: 'OK',
                          height: 52,
                          borderRadius: 16,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          backgroundColor: theme.primaryColor,
                          onPressed: () async {
                            Navigator.of(sheetContext).pop();
                            await ApiService.logoutAndRedirect();
                          },
                        )
                      else ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: dangerColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: dangerColor.withValues(alpha: 0.16),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: dangerColor,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'This action cannot be undone. Your account will be reviewed after email verification.',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 13.5,
                                    height: 1.4,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          'Reason',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: deletionReasons.map((reason) {
                            final isSelected = selectedReason == reason;

                            return ChoiceChip(
                              label: Text(reason),
                              selected: isSelected,
                              onSelected: isLoading
                                  ? null
                                  : (selected) {
                                      setState(() {
                                        selectedReason = selected
                                            ? reason
                                            : null;
                                        reasonError = null;
                                      });
                                    },
                              labelStyle: TextStyle(
                                color: isSelected ? dangerColor : textColor,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: 13,
                              ),
                              selectedColor: dangerColor.withValues(
                                alpha: 0.12,
                              ),
                              backgroundColor: theme.colorScheme.surface,
                              side: BorderSide(
                                color: isSelected
                                    ? dangerColor.withValues(alpha: 0.55)
                                    : theme.dividerColor,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                              showCheckmark: false,
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: reasonController,
                          enabled: !isLoading,
                          minLines: 3,
                          maxLines: 5,
                          maxLength: 500,
                          textInputAction: TextInputAction.newline,
                          decoration: InputDecoration(
                            labelText: selectedReason == null
                                ? 'Tell us more'
                                : 'Add details (optional)',
                            hintText:
                                'A short note helps us understand what to improve',
                            errorText: reasonError,
                            alignLabelWithHint: true,
                            filled: true,
                            fillColor: theme.canvasColor.withValues(
                              alpha: theme.brightness == Brightness.dark
                                  ? 0.2
                                  : 0.7,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: theme.dividerColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: dangerColor,
                                width: 1.4,
                              ),
                            ),
                          ),
                          onChanged: (_) {
                            setState(() => reasonError = null);
                          },
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: dangerColor,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: dangerColor.withValues(
                                alpha: 0.45,
                              ),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: isLoading
                                ? null
                                : () async {
                                    final reason = _composeDeletionReason(
                                      selectedReason: selectedReason,
                                      details: reasonController.text,
                                    );

                                    if (reason.isEmpty) {
                                      setState(() {
                                        reasonError =
                                            'Please select or enter a reason';
                                      });
                                      return;
                                    }

                                    if (reason.length > 500) {
                                      setState(() {
                                        reasonError =
                                            'Please keep the reason under 500 characters';
                                      });
                                      return;
                                    }

                                    setState(() => isLoading = true);
                                    try {
                                      await UserRepository()
                                          .requestAccountDeletion(
                                            reason: reason,
                                          );
                                      if (context.mounted) {
                                        setState(() {
                                          isLoading = false;
                                          isSent = true;
                                        });
                                      }
                                    } catch (e) {
                                      setState(() => isLoading = false);
                                      if (sheetContext.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(content: Text('Error: $e')),
                                        );
                                      }
                                    }
                                  },
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.mail_outline_rounded,
                                        size: 19,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Send verification email',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 50,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: theme.dividerColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: isLoading
                                ? null
                                : () => Navigator.of(sheetContext).pop(),
                            child: Text(
                              'Keep my account',
                              style: TextStyle(
                                color: mutedTextColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(reasonController.dispose);
  }

  String _composeDeletionReason({
    required String? selectedReason,
    required String details,
  }) {
    final trimmedDetails = details.trim();

    if (selectedReason == null) {
      return trimmedDetails;
    }

    if (trimmedDetails.isEmpty) {
      return selectedReason;
    }

    return '$selectedReason: $trimmedDetails';
  }
}
