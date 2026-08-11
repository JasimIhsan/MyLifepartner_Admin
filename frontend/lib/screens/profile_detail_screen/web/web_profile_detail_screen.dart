import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/core/country_helper.dart';
import 'package:life_partner_again/screens/profile_detail_screen/widgets/body_photo_carousel.dart';
import 'package:life_partner_again/screens/profile_detail_screen/widgets/header_carousel.dart';
import 'package:life_partner_again/screens/profile_detail_screen/widgets/profile_action_bar.dart';
import 'package:life_partner_again/screens/profile_detail_screen/widgets/profile_detail_controller.dart';
import 'package:life_partner_again/screens/profile_detail_screen/widgets/profile_details_grid.dart';
import 'package:life_partner_again/screens/profile_detail_screen/widgets/profile_name_row.dart';
import 'package:life_partner_again/screens/profile_detail_screen/widgets/profile_skeleton.dart';

class WebProfileDetailScreen extends StatefulWidget {
  const WebProfileDetailScreen({super.key});

  @override
  State<WebProfileDetailScreen> createState() => _WebProfileDetailScreenState();
}

class _WebProfileDetailScreenState extends State<WebProfileDetailScreen>
    with ProfileDetailControllerState<WebProfileDetailScreen> {
  @override
  Widget build(BuildContext context) {
    if (!hasApiData) {
      return Scaffold(
        backgroundColor: Theme.of(context).canvasColor,
        body: Center(child: SizedBox(width: 800, child: ProfileSkeleton())),
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

    return Stack(
      children: [
        // Background decorative elements
        Positioned(
          top: -100,
          right: -50,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
            ),
          ),
        ),

        Center(
          child: Container(
            width: 1000, // Max width for web
            margin: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left Column: Main Image & Carousel
                Expanded(
                  flex: 5,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (images.isEmpty)
                        Container(
                          color: Theme.of(context).primaryColorLight,
                          child: const Center(
                            child: Icon(
                              Icons.person_rounded,
                              size: 100,
                              color: Color(0xFFCCCCCC),
                            ),
                          ),
                        )
                      else
                        HeaderCarousel(images: images),

                      if (images.isNotEmpty &&
                          images.first['isBlurred'] == true)
                        Align(
                          alignment: Alignment.center,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 32),
                            padding: const EdgeInsets.all(24),
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
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.lock_outline_rounded,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  (p['viewerPrivacyEnabled'] == true)
                                      ? 'Your profile is private'
                                      : 'Photos are private',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  (p['viewerPrivacyEnabled'] == true)
                                      ? "You need access to see ${p['name'] ?? 'this user'}'s photos."
                                      : "Request access to see ${p['name'] ?? 'this user'}'s photos.",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                RequestAccessButton(
                                  userId: p['userId'],
                                  imageAccessRequestStatus:
                                      p['imageAccessRequestStatus'],
                                ),
                              ],
                            ),
                          ),
                        ),
                      // Gradient overlay at bottom for name
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.8),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 24,
                        left: 24,
                        right: 24,
                        child: ProfileNameRow(profile: p, isOverlay: true),
                      ),
                    ],
                  ),
                ),
                // Right Column: Details & Actions
                Expanded(
                  flex: 6,
                  child: Container(
                    color: Colors.transparent,
                    child: Column(
                      children: [
                        // Scrollable details
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Profile Details',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary,
                                      ),
                                    ),
                                    if (p['country'] != null &&
                                        CountryHelper.getCode(p['country']) !=
                                            null)
                                      Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.1,
                                              ),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: ClipOval(
                                          child: CountryFlag.fromCountryCode(
                                            CountryHelper.getCode(
                                              p['country'],
                                            )!,
                                            width: 44,
                                            height: 44,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                if (p['bio'] != null &&
                                    (p['bio'] as String).isNotEmpty) ...[
                                  Text(
                                    'About',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: AppColors.inputBackground,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      p['bio'],
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary,
                                        height: 1.6,
                                      ),
                                    ),
                                  ).animate().fadeIn(
                                    duration: 300.ms,
                                    delay: 100.ms,
                                  ),
                                  const SizedBox(height: 32),
                                ],
                                ProfileDetailsGrid(profile: p),
                                const SizedBox(height: 32),
                                if (images.isNotEmpty) ...[
                                  Text(
                                    'Photos (${images.length})',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  BodyPhotoCarousel(images: images),
                                  const SizedBox(height: 24),
                                ],
                              ],
                            ),
                          ),
                        ),
                        // Action Bar at the bottom
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, -5),
                              ),
                            ],
                          ),
                          child: ProfileActionBar(profile: p),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}