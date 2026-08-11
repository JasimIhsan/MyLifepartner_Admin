import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/core/app_routes.dart';
import 'package:life_partner_again/screens/profile_detail_screen/widgets/body_photo_carousel.dart';
import 'package:life_partner_again/screens/profile_detail_screen/widgets/header_carousel.dart';
import 'package:life_partner_again/screens/profile_detail_screen/widgets/profile_action_bar.dart';
import 'package:life_partner_again/screens/profile_detail_screen/widgets/profile_detail_controller.dart';
import 'package:life_partner_again/screens/profile_detail_screen/widgets/profile_details_grid.dart';
import 'package:life_partner_again/screens/profile_detail_screen/widgets/profile_name_row.dart';
import 'package:life_partner_again/screens/profile_detail_screen/widgets/profile_skeleton.dart';
import 'package:life_partner_again/screens/profile_detail_screen/widgets/report_user_dialog.dart';
import 'package:life_partner_again/services/block_service.dart';
import 'package:life_partner_again/widgets/bottomsheet/block_confirmation_bottom_sheet.dart';

class MobileProfileDetailScreen extends StatefulWidget {
  const MobileProfileDetailScreen({super.key});

  @override
  State<MobileProfileDetailScreen> createState() =>
      _MobileProfileDetailScreenState();
}

class _MobileProfileDetailScreenState extends State<MobileProfileDetailScreen>
    with ProfileDetailControllerState<MobileProfileDetailScreen> {
  final BlockService _blockService = BlockService();

  @override
  Widget build(BuildContext context) {
    if (!hasApiData) {
      return Scaffold(
        backgroundColor: Theme.of(context).canvasColor,
        body: const ProfileSkeleton(),
      );
    }
    return Scaffold(
      backgroundColor: Theme.of(context).canvasColor,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final p = resolvedProfile;
    final images = (p['images'] as List<dynamic>? ?? []);

    final double actionBarAndGapHeight =
        90 + MediaQuery.of(context).padding.bottom;
    final double topSectionHeight =
        MediaQuery.of(context).size.height - actionBarAndGapHeight;

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(
                height: topSectionHeight,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: images.isEmpty
                          ? Container(
                              color: AppColors.black,
                              child: const Center(
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 80,
                                  color: Color(0xFFCCCCCC),
                                ),
                              ),
                            )
                          : HeaderCarousel(images: images),
                    ),
                    if (images.isNotEmpty && images.first['isBlurred'] == true)
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 32),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.lock_outline_rounded,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                (p['viewerPrivacyEnabled'] == true)
                                    ? 'Your profile is private'
                                    : 'Photos are private',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                (p['viewerPrivacyEnabled'] == true)
                                    ? "You need access to see ${p['name'] ?? 'this user'}'s photos."
                                    : "Request access to see ${p['name'] ?? 'this user'}'s photos.",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              RequestAccessButton(
                                userId: p['userId'],
                                imageAccessRequestStatus:
                                    p['imageAccessRequestStatus'],
                              ),
                            ],
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                        child: ProfileNameRow(profile: p, isOverlay: true),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 25),
                    if (p['bio'] != null &&
                        (p['bio'] as String).isNotEmpty) ...[
                      Text(
                        'About',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color:
                              Theme.of(context).textTheme.bodyLarge?.color ??
                              AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                            width: 0.6,
                          ),
                        ),
                        child: Text(
                          p['bio'],
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                Theme.of(context).textTheme.bodyLarge?.color ??
                                AppColors.textPrimary,
                            height: 1.6,
                          ),
                        ),
                      ).animate().fadeIn(duration: 300.ms, delay: 100.ms),
                      const SizedBox(height: 20),
                    ],
                    ProfileDetailsGrid(profile: p),
                    const SizedBox(height: 20),
                    if (images.isNotEmpty) ...[
                      Text(
                        'Photos (${images.length})',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color:
                              Theme.of(context).textTheme.bodyLarge?.color ??
                              AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      BodyPhotoCarousel(images: images),
                      const SizedBox(height: 20),
                    ],
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 12,
          child: GestureDetector(
            onTap: () {
              debugPrint("👉 can pop ${context.canPop()}");
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.home);
              }
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: 0.95),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color:
                    Theme.of(context).textTheme.bodyLarge?.color ??
                    AppColors.textPrimary,
              ),
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 12,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: 0.95),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                size: 20,
                color:
                    Theme.of(context).textTheme.bodyLarge?.color ??
                    AppColors.textPrimary,
              ),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              onSelected: (value) {
                if (value == 'report') {
                  ReportUserDialog.show(context, p);
                } else if (value == 'block') {
                  BlockConfirmationBottomSheet.show(
                    context: context,
                    isBlocking: true,
                    userName: p['name'] ?? 'this user',
                    onConfirm: () async {
                      await _blockService.blockUser(p['userId']);
                    },
                    onSuccess: () {
                      setState(() {
                        resolvedProfile['isBlocked'] = true;
                      });
                    },
                  );
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(
                        Icons.flag_outlined,
                        size: 20,
                        color:
                            Theme.of(context).textTheme.bodyLarge?.color ??
                            AppColors.textPrimary,
                      ),
                      SizedBox(width: 12),
                      Text('Report user'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'block',
                  child: Row(
                    children: [
                      Icon(
                        Icons.block_outlined,
                        size: 20,
                        color: Colors.redAccent,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Block user',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: ProfileActionBar(profile: p),
        ),
      ],
    );
  }
}
