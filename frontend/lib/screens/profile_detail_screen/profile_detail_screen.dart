import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/core/country_helper.dart';
import 'package:life_partner_again/screens/profile_detail_screen/widgets/body_photo_carousel.dart';
import 'package:life_partner_again/screens/profile_detail_screen/widgets/header_carousel.dart';
import 'package:life_partner_again/screens/profile_detail_screen/widgets/profile_action_bar.dart';
import 'package:life_partner_again/screens/profile_detail_screen/widgets/profile_details_grid.dart';
import 'package:life_partner_again/screens/profile_detail_screen/widgets/profile_name_row.dart';
import 'package:life_partner_again/screens/profile_detail_screen/widgets/profile_skeleton.dart';
import 'package:life_partner_again/services/match_service.dart';

class ProfileDetailScreen extends StatefulWidget {
  final int profileId;
  final String profileName;

  const ProfileDetailScreen({
    super.key,
    required this.profileId,
    required this.profileName,
  });

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  Map<String, dynamic>? _apiProfile;

  @override
  void initState() {
    super.initState();
    _enrichFromApi();
  }

  Future<void> _enrichFromApi() async {
    try {
      final data = await MatchService.getProfileDetail(widget.profileId);
      if (mounted && data != null) {
        setState(() => _apiProfile = data);
      }
    } catch (_) {}
  }

  Map<String, dynamic> get _resolvedProfile {
    return _apiProfile ?? {};
  }

  bool get _hasApiData => _apiProfile != null;

  @override
  Widget build(BuildContext context) {
    if (!_hasApiData) {
      return const Scaffold(
        backgroundColor: AppColors.textWhite,
        body: ProfileSkeleton(),
      );
    }
    return Scaffold(backgroundColor: AppColors.textWhite, body: _buildBody());
  }

  Widget _buildBody() {
    final p = _resolvedProfile;
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
                              color: AppColors.primaryLight,
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
                      const Text(
                        'About',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.inputBackground,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          p['bio'],
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
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
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        if (p['country'] != null && CountryHelper.getCode(p['country']) != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: CountryFlag.fromCountryCode(
                  CountryHelper.getCode(p['country'])!,
                  width: 38,
                  height: 38,
                ),
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
