import 'package:flutter/material.dart';

import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/models/match_recommendation.dart';
import 'package:life_partner_again/providers/match_provider.dart';
import 'package:provider/provider.dart';
import 'package:life_partner_again/screens/discover_screen/widgets/dating_profile_card.dart';
import 'package:life_partner_again/services/match_service.dart';
import 'package:life_partner_again/main.dart'; // Make sure to import main.dart

class DatingDiscoverTab extends StatefulWidget {
  final String title;

  const DatingDiscoverTab({super.key, this.title = ''});

  @override
  State<DatingDiscoverTab> createState() => _DatingDiscoverTabState();
}

class _DatingDiscoverTabState extends State<DatingDiscoverTab> with RouteAware {
  final PageController _pageController = PageController();
  final Set<int> _swipedProfileIds = {};

  // We keep a local snapshot of profiles to prevent the PageView from
  // abruptly shifting when MatchProvider modifies its internal array format.
  List<MatchRecommendation> _localProfiles = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = context.read<MatchProvider>();
        if (provider.state == MatchLoadState.idle ||
            provider.profiles.isEmpty) {
          provider.loadRecommendations().then((_) => _syncProfiles());
        } else {
          _syncProfiles();
        }
      }
    });
  }

  void _syncProfiles() {
    final providerProfiles = context.read<MatchProvider>().profiles;
    setState(() {
      _localProfiles = List.from(providerProfiles);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute is PageRoute) {
      routeObserver.subscribe(this, modalRoute);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    // Reload recommendations when returning to this tab from another screen
    final provider = context.read<MatchProvider>();
    provider.loadRecommendations().then((_) => _syncProfiles());
  }

  void _goToNext() {
    if (_pageController.page != null &&
        _pageController.page!.toInt() < _localProfiles.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPrevious() {
    if (_pageController.page != null && _pageController.page!.toInt() > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _handleNotInterested(MatchRecommendation profile) async {
    if (_swipedProfileIds.contains(profile.id)) return;

    setState(() {
      _swipedProfileIds.add(profile.id);
    });

    // Animate to next profile immediately for good UX
    _goToNext();

    try {
      // Fire and forget backend call so we don't block the UI
      await MatchService.swipe(targetProfileId: profile.id, action: 'LEFT');
    } catch (e) {
      // Revert if error occurs (optional)
      debugPrint("Failed to record Not Interested: $e");
    }
  }

  Future<void> _handleInterest(MatchRecommendation profile) async {
    if (_swipedProfileIds.contains(profile.id)) return;

    setState(() {
      _swipedProfileIds.add(profile.id);
    });

    _goToNext();

    try {
      await MatchService.swipe(targetProfileId: profile.id, action: 'RIGHT');
    } catch (e) {
      debugPrint("Failed to send Interest: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MatchProvider>(
      builder: (context, provider, _) {
        if (provider.state == MatchLoadState.loading &&
            _localProfiles.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.black),
          );
        }

        if (provider.state == MatchLoadState.error && _localProfiles.isEmpty) {
          return _buildError(provider);
        }

        if (_localProfiles.isEmpty) {
          return _buildEmpty(provider);
        }

        return PageView.builder(
          controller: _pageController,
          physics:
              const NeverScrollableScrollPhysics(), // We manually control scrolling with buttons/swipe zones
          itemCount: _localProfiles.length + 1, // +1 for the end "refresh" card
          itemBuilder: (context, index) {
            if (index == _localProfiles.length) {
              return _buildEndOfList(provider);
            }

            final profile = _localProfiles[index];
            final hasSwiped = _swipedProfileIds.contains(profile.id);

            return DatingProfileCard(
              profile: profile,
              isSwiped: hasSwiped,
              onNotInterested: () => _handleNotInterested(profile),
              onInterest: () => _handleInterest(profile),
              onNext: _goToNext,
              onPrevious: _goToPrevious,
              showPreviousButton: index > 0,
              showNextButton: true,
            );
          },
        );
      },
    );
  }

  Widget _buildError(MatchProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.error ?? 'Check your network and try again',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            _buildRetryButton(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(MatchProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline_rounded, size: 48),
            const SizedBox(height: 24),
            Text(
              'No profiles found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We are searching for more matches. Check back later!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            _buildRetryButton(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildEndOfList(MatchProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            size: 60,
            color: Colors.green,
          ),
          const SizedBox(height: 24),
          Text(
            "You're all caught up!",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "You've seen all recommendations for now.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          _buildRetryButton(provider),
        ],
      ),
    );
  }

  Widget _buildRetryButton(MatchProvider provider) {
    return ElevatedButton(
      onPressed: () async {
        setState(() {
          _localProfiles.clear();
          _swipedProfileIds.clear();
        });
        if (_pageController.hasClients) {
          _pageController.jumpToPage(0);
        }
        await provider.loadRecommendations();
        _syncProfiles();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
      ),
      child: Text(
        'Refresh',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
