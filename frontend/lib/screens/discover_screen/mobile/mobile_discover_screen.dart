import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/providers/match_provider.dart';
import 'package:life_partner_again/widgets/custom_button.dart';
import 'package:provider/provider.dart';
import '../widgets/discover_components.dart';
import '../widgets/discover_controller.dart';

class MobileDiscoverScreen extends StatefulWidget {
  const MobileDiscoverScreen({super.key});

  @override
  State<MobileDiscoverScreen> createState() => _MobileDiscoverScreenState();
}

class _MobileDiscoverScreenState extends State<MobileDiscoverScreen>
    with DiscoverControllerState {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<MatchProvider>(
          builder: (context, provider, _) {
            if (provider.state == MatchLoadState.loading &&
                localProfiles.isEmpty) {
              return _buildLoading();
            }

            if (provider.state == MatchLoadState.error &&
                localProfiles.isEmpty) {
              return _buildError(provider);
            }

            if (localProfiles.isEmpty) {
              return _buildEmpty();
            }

            return Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      // Main Profile Browser
                      PageView.builder(
                        controller: pageController,
                        onPageChanged: (idx) =>
                            setState(() => currentIndex = idx),
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: localProfiles.length,
                        itemBuilder: (context, index) {
                          final profile = localProfiles[index];
                          return RefreshIndicator(
                            color: AppColors.primary,
                            onRefresh: () async {
                              await context
                                  .read<MatchProvider>()
                                  .loadRecommendations();
                              syncWithProvider();
                            },
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return SingleChildScrollView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  child: SizedBox(
                                    height: constraints.maxHeight,
                                    child: ProfileBrowserCard(
                                      profile: profile,
                                      onInterest: () =>
                                          handleInteraction(profile, 'RIGHT'),
                                      onNotInterested: () =>
                                          showRejectionConfirmation(profile),
                                      onReturnFromDetail: () {
                                        context
                                            .read<MatchProvider>()
                                            .loadRecommendations()
                                            .then((_) => syncWithProvider());
                                      },
                                      isActioning:
                                          currentIndex == index &&
                                          loadingAction != null,
                                      loadingAction: currentIndex == index
                                          ? loadingAction
                                          : null,
                                      isActioned: actionedProfileIds.contains(
                                        profile.id,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),

                      // Floating Side Navigation Buttons
                      if (currentIndex > 0)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: SideNavigationButton(
                            icon: Icons.chevron_left_rounded,
                            onTap: goToPrevious,
                            isLeft: true,
                          ),
                        ),
                      if (currentIndex < localProfiles.length - 1)
                        Align(
                          alignment: Alignment.centerRight,
                          child: SideNavigationButton(
                            icon: Icons.chevron_right_rounded,
                            onTap: goToNext,
                            isLeft: false,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
          SizedBox(height: 16),
          Text(
            "Finding best matches for you...",
            style: TextStyle(
              color: AppColors.textSecondary,
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
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
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
                color: AppColors.primary.withValues(alpha: 0.05),
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
                    color: AppColors.primary.withValues(alpha: 0.5),
                  );
                },
              ),
            ).animate().fadeIn(duration: 600.ms, curve: Curves.easeOut).scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1.0, 1.0),
                  curve: Curves.easeOutBack,
                  duration: 600.ms,
                ),
            const SizedBox(height: 40),
            Text(
              'You\'re all caught up!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(
                  begin: 0.1,
                  end: 0,
                  curve: Curves.easeOutCubic,
                  duration: 500.ms,
                ),
            const SizedBox(height: 16),
            Text(
              'We are looking for more compatible profiles. Please check back in a bit for fresh recommendations.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ).animate().fadeIn(duration: 500.ms, delay: 300.ms).slideY(
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
            ).animate().fadeIn(duration: 500.ms, delay: 400.ms).slideY(
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
