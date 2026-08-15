import 'package:go_router/go_router.dart';
import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/core/country_helper.dart';
import 'package:life_partner_again/models/match_recommendation.dart';
import 'package:life_partner_again/providers/match_provider.dart';

import 'package:life_partner_again/widgets/custom_button.dart';
import 'package:life_partner_again/widgets/founding_member_badge.dart';
import 'package:life_partner_again/widgets/verified_profile_bottom_sheet.dart';
import 'package:provider/provider.dart';

import '../widgets/discover_components.dart';
import '../widgets/discover_controller.dart';

class WebDiscoverScreen extends StatefulWidget {
  const WebDiscoverScreen({super.key});

  @override
  State<WebDiscoverScreen> createState() => _WebDiscoverScreenState();
}

class _WebDiscoverScreenState extends State<WebDiscoverScreen>
    with DiscoverControllerState {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Consumer<MatchProvider>(
        builder: (context, provider, _) {
          if (provider.state == MatchLoadState.loading &&
              localProfiles.isEmpty) {
            return _buildLoading();
          }

          if (provider.state == MatchLoadState.error && localProfiles.isEmpty) {
            return _buildError(provider);
          }

          if (localProfiles.isEmpty) {
            return _buildEmpty();
          }

          final selectedProfile = localProfiles[currentIndex];

          return Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: Card(
                            elevation: 6,
                            shadowColor: Theme.of(
                              context,
                            ).shadowColor.withValues(alpha: 0.04),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            color: Theme.of(context).colorScheme.surface,
                            clipBehavior: Clip.antiAlias,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Left side of Card: Profile Picture (or Blurred view)
                                Expanded(
                                  flex: 6,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      _buildProfilePicture(selectedProfile),
                                      // Dark Gradient at the bottom
                                      Positioned.fill(
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              stops: const [0.6, 1.0],
                                              colors: [
                                                Colors.transparent,
                                                Colors.black.withValues(
                                                  alpha: 0.85,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Flag (Top Right)
                                      if (CountryHelper.getCode(
                                            selectedProfile.country,
                                          ) !=
                                          null)
                                        Positioned(
                                          top: 16,
                                          right: 16,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.surface,
                                                width: 2.5,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.15),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: ClipOval(
                                              child:
                                                  CountryFlag.fromCountryCode(
                                                    CountryHelper.getCode(
                                                      selectedProfile.country,
                                                    )!,
                                                    width: 32,
                                                    height: 32,
                                                  ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                // Right side of Card: Attributes & Action Buttons
                                Expanded(
                                  flex: 5,
                                  child: Padding(
                                    padding: const EdgeInsets.all(40),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Name & Age Row
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    '${selectedProfile.name}, ${selectedProfile.age}',
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 28,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          Theme.of(context)
                                                              .textTheme
                                                              .bodyLarge
                                                              ?.color ??
                                                          AppColors.textPrimary,
                                                      letterSpacing: -0.5,
                                                    ),
                                                  ),
                                                ),
                                                if (selectedProfile
                                                    .isVerified) ...[
                                                  const SizedBox(width: 8),
                                                  GestureDetector(
                                                    onTap: () {
                                                      showModalBottomSheet(
                                                        context: context,
                                                        backgroundColor:
                                                            Colors.transparent,
                                                        builder: (_) =>
                                                            VerifiedProfileBottomSheet(
                                                              profileName:
                                                                  selectedProfile
                                                                      .name,
                                                            ),
                                                      );
                                                    },
                                                    child: Icon(
                                                      Icons.verified,
                                                      color:
                                                          Colors.blue.shade600,
                                                      size: 26,
                                                    ),
                                                  ),
                                                ],
                                                if (selectedProfile
                                                    .isFoundingMember) ...[
                                                  const SizedBox(width: 8),
                                                  const FoundingMemberBadge(
                                                    size: 26,
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            // Location Row
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.location_on_outlined,
                                                  color: Colors.grey.shade600,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  '${selectedProfile.city ?? ""}${selectedProfile.city != null && selectedProfile.country != null ? ", " : ""}${selectedProfile.country ?? ""}',
                                                  style: GoogleFonts.outfit(
                                                    color: Colors.grey.shade600,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 28),
                                            Text(
                                              "About Profile",
                                              style: GoogleFonts.outfit(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    Theme.of(context)
                                                        .textTheme
                                                        .bodyLarge
                                                        ?.color ??
                                                    AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                            _buildAttributeTile(
                                              Icons.favorite_border_rounded,
                                              "Marital Status",
                                              selectedProfile.maritalStatus !=
                                                      null
                                                  ? _formatEnum(
                                                      selectedProfile
                                                          .maritalStatus!,
                                                    )
                                                  : "Not specified",
                                            ),
                                            const SizedBox(height: 16),
                                            _buildAttributeTile(
                                              Icons.location_city_rounded,
                                              "Location",
                                              selectedProfile.city ??
                                                  selectedProfile.country ??
                                                  "Not Specified",
                                            ),
                                            const SizedBox(height: 16),
                                            _buildAttributeTile(
                                              Icons.calendar_month_outlined,
                                              "Profile Created",
                                              "Recently Joined",
                                            ),
                                          ],
                                        ),
                                        Column(
                                          children: [
                                            // View Full Details click target (Solid Red Button)
                                            ElevatedButton(
                                              onPressed: () async {
                                                await context.push(
                                                  '/profile/${selectedProfile.id}',
                                                );
                                                syncWithProvider();
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Theme.of(
                                                  context,
                                                ).primaryColor,
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 18,
                                                    ),
                                                minimumSize:
                                                    const Size.fromHeight(54),
                                              ),
                                              child: Text(
                                                "View Profile",
                                                style: GoogleFonts.outfit(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                            // Action buttons Pass / Interest
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: ActionButton(
                                                    label: '',
                                                    icon: Icons
                                                        .heart_broken_rounded,
                                                    onTap: () =>
                                                        showRejectionConfirmation(
                                                          selectedProfile,
                                                        ),
                                                    primary: false,
                                                    backgroundColor:
                                                        const Color(0xFFFFF5F5),
                                                    iconColor: Theme.of(
                                                      context,
                                                    ).primaryColor,
                                                    textColor: Theme.of(
                                                      context,
                                                    ).primaryColor,
                                                    borderColor: Border.all(
                                                      color: Theme.of(context)
                                                          .primaryColor
                                                          .withValues(
                                                            alpha: 0.15,
                                                          ),
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: ActionButton(
                                                    label: '',
                                                    icon:
                                                        Icons.favorite_rounded,
                                                    onTap: () =>
                                                        handleInteraction(
                                                          selectedProfile,
                                                          'RIGHT',
                                                        ),
                                                    primary: true,
                                                    backgroundColor: Theme.of(
                                                      context,
                                                    ).primaryColor,
                                                    iconColor: Colors.white,
                                                    textColor: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Left Navigation Button
                        Positioned(
                          left: -25,
                          child: _buildNavButton(
                            isNext: false,
                            onTap: currentIndex > 0
                                ? () {
                                    setState(() {
                                      currentIndex--;
                                    });
                                  }
                                : null,
                          ),
                        ),
                        // Right Navigation Button
                        Positioned(
                          right: -25,
                          child: _buildNavButton(
                            isNext: true,
                            onTap: currentIndex < localProfiles.length - 1
                                ? () {
                                    setState(() {
                                      currentIndex++;
                                    });
                                  }
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNavButton({required bool isNext, required VoidCallback? onTap}) {
    final bool isDisabled = onTap == null;
    return MouseRegion(
      cursor: isDisabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isDisabled
                ? Theme.of(context).disabledColor.withValues(alpha: 0.1)
                : Theme.of(context).colorScheme.surface,
            shape: BoxShape.circle,
            boxShadow: isDisabled
                ? []
                : [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).shadowColor.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
            border: Border.all(
              color: isDisabled
                  ? Colors.transparent
                  : Theme.of(context).dividerColor,
              width: 1,
            ),
          ),
          child: Center(
            child: Icon(
              isNext ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
              color: isDisabled
                  ? Theme.of(context).disabledColor
                  : Theme.of(context).primaryColor,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttributeTile(IconData icon, String title, String val) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: Theme.of(context).primaryColor),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.outfit(
                color: Colors.grey.shade500,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              val,
              style: GoogleFonts.outfit(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfilePicture(MatchRecommendation profile) {
    final primaryImg = profile.images.where((img) => img.isPrimary);
    final String? imgUrl = primaryImg.isNotEmpty
        ? primaryImg.first.imageUrl
        : (profile.images.isNotEmpty ? profile.images.first.imageUrl : null);

    final bool isBlurred = primaryImg.isNotEmpty
        ? primaryImg.first.isBlurred
        : (profile.images.isNotEmpty ? profile.images.first.isBlurred : false);

    return Stack(
      fit: StackFit.expand,
      children: [
        imgUrl != null
            ? Image.network(
                imgUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _picPlaceholder(context),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _picPlaceholder(context);
                },
              )
            : _picPlaceholder(context),
        if (isBlurred)
          Align(
            alignment: Alignment.center,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Photos are Private",
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Request access to view photos.",
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 20),
                  RequestAccessButton(profile: profile),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _picPlaceholder(BuildContext context) => Container(
    color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
    child: Center(
      child: Icon(
        Icons.image_not_supported_outlined,
        color: Theme.of(context).disabledColor,
        size: 48,
      ),
    ),
  );

  String _formatEnum(String value) {
    return value
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .map(
          (w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '',
        )
        .join(' ');
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).primaryColor,
          ),
          SizedBox(height: 16),
          Text(
            "Finding best matches for you...",
            style: TextStyle(
              color:
                  Theme.of(context).textTheme.bodyMedium?.color ??
                  AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(MatchProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Connection Error',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color:
                    Theme.of(context).textTheme.bodyLarge?.color ??
                    AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color:
                    Theme.of(context).textTheme.bodyMedium?.color ??
                    AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Retry',
              onPressed: () => provider.loadRecommendations().then(
                (_) => syncWithProvider(),
              ),
              height: 48,
              borderRadius: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    'assets/images/illustrations/empty_profile.png',
                    height: 220,
                    width: 220,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.favorite_border_rounded,
                        size: 100,
                        color: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.5),
                      );
                    },
                  ),
                )
                .animate()
                .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1.0, 1.0),
                  curve: Curves.easeOutBack,
                  duration: 600.ms,
                ),
            const SizedBox(height: 40),
            Text(
                  'You\'re all caught up!',
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color:
                        Theme.of(context).textTheme.bodyLarge?.color ??
                        AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                )
                .animate()
                .fadeIn(duration: 500.ms, delay: 200.ms)
                .slideY(
                  begin: 0.1,
                  end: 0,
                  curve: Curves.easeOutCubic,
                  duration: 500.ms,
                ),
            const SizedBox(height: 16),
            Text(
                  'We are looking for more compatible profiles. Please check back in a bit for fresh recommendations.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color:
                        Theme.of(context).textTheme.bodyMedium?.color ??
                        AppColors.textSecondary,
                    fontSize: 15,
                    height: 1.5,
                  ),
                )
                .animate()
                .fadeIn(duration: 500.ms, delay: 300.ms)
                .slideY(
                  begin: 0.1,
                  end: 0,
                  curve: Curves.easeOutCubic,
                  duration: 500.ms,
                ),
            const SizedBox(height: 48),
            SizedBox(
                  width: 220,
                  child: CustomButton(
                    onPressed: () {
                      context.read<MatchProvider>().loadRecommendations().then(
                        (_) => syncWithProvider(),
                      );
                    },
                    text: 'Refresh Profiles',
                    borderRadius: 100,
                    height: 52,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                )
                .animate()
                .fadeIn(duration: 500.ms, delay: 400.ms)
                .slideY(
                  begin: 0.1,
                  end: 0,
                  curve: Curves.easeOutCubic,
                  duration: 500.ms,
                ),
          ],
        ),
      ),
    );
  }
}
