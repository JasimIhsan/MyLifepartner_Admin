import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:life_partner_again/main.dart';
import 'package:life_partner_again/models/match_recommendation.dart';
import 'package:life_partner_again/providers/match_provider.dart';
import 'package:life_partner_again/services/match_service.dart';
import 'package:life_partner_again/widgets/bottomsheet/feature_exhausted_modal.dart';
import 'package:provider/provider.dart';

mixin DiscoverControllerState<T extends StatefulWidget> on State<T>
    implements RouteAware {
  final PageController pageController = PageController();
  final Set<int> actionedProfileIds = {};
  List<MatchRecommendation> localProfiles = [];
  int currentIndex = 0;
  String? loadingAction;

  MatchProvider? _matchProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        fetchRecommendations();
      }
    });
  }

  void _onProviderChanged() {
    // Sync whenever the provider's profile list changes (e.g. after a swipe
    // done by ProfileActionBar inside the inline detail view).
    if (!mounted) return;
    syncWithProvider();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute is PageRoute) {
      routeObserver.subscribe(this, modalRoute);
    }

    final provider = Provider.of<MatchProvider>(context, listen: false);
    if (_matchProvider != provider) {
      _matchProvider?.removeListener(_onProviderChanged);
      _matchProvider = provider;
      _matchProvider?.addListener(_onProviderChanged);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    pageController.dispose();
    _matchProvider?.removeListener(_onProviderChanged);
    _matchProvider = null;
    super.dispose();
  }

  @override
  void didPopNext() {
    syncWithProvider();
  }

  @override
  void didPush() {}

  @override
  void didPop() {}

  @override
  void didPushNext() {}

  void fetchRecommendations() {
    if (!mounted) return;
    final provider =
        _matchProvider ?? Provider.of<MatchProvider>(context, listen: false);
    provider.loadRecommendations().then((_) {
      if (mounted) {
        syncWithProvider(resetIndex: true);
      }
    });
  }

  void syncWithProvider({bool resetIndex = false}) {
    if (!mounted) return;
    final provider = _matchProvider;
    if (provider == null) return;
    setState(() {
      localProfiles = List.from(provider.profiles);
      if (resetIndex) {
        currentIndex = 0;
      } else {
        if (currentIndex >= localProfiles.length) {
          currentIndex = localProfiles.length - 1;
        }
        if (currentIndex < 0) {
          currentIndex = 0;
        }
      }
    });
    if (pageController.hasClients && resetIndex) {
      pageController.jumpToPage(0);
    } else if (pageController.hasClients &&
        pageController.page?.round() != currentIndex) {
      pageController.jumpToPage(currentIndex);
    }
  }

  void goToNext() {
    if (currentIndex < localProfiles.length - 1) {
      if (pageController.hasClients) {
        pageController.nextPage(duration: 500.ms, curve: Curves.easeOutCubic);
      } else {
        setState(() {
          currentIndex++;
        });
      }
    } else {
      final provider = _matchProvider ??
          (mounted ? Provider.of<MatchProvider>(context, listen: false) : null);
      provider?.loadRecommendations().then((_) {
        if (mounted) {
          syncWithProvider();
        }
      });
    }
  }

  void goToPrevious() {
    if (currentIndex > 0) {
      if (pageController.hasClients) {
        pageController.previousPage(
          duration: 500.ms,
          curve: Curves.easeOutCubic,
        );
      } else {
        setState(() {
          currentIndex--;
        });
      }
    }
  }

  void selectProfile(int index) {
    if (index >= 0 && index < localProfiles.length) {
      setState(() {
        currentIndex = index;
      });
      if (pageController.hasClients) {
        pageController.jumpToPage(index);
      }
    }
  }

  void showRejectionConfirmation(MatchRecommendation profile) {
    handleInteraction(profile, 'LEFT');
  }

  Future<void> handleInteraction(
    MatchRecommendation profile,
    String action,
  ) async {
    if (actionedProfileIds.contains(profile.id) || loadingAction != null) {
      return;
    }

    setState(() {
      loadingAction = action;
    });

    try {
      await MatchService.swipe(targetProfileId: profile.id, action: action);

      if (mounted) {
        _matchProvider?.removeProfile(profile.id);

        setState(() {
          actionedProfileIds.add(profile.id);
          localProfiles.removeWhere((p) => p.id == profile.id);
          loadingAction = null;

          if (currentIndex >= localProfiles.length) {
            currentIndex = localProfiles.length - 1;
            if (currentIndex < 0) currentIndex = 0;
          }
        });

        if (pageController.hasClients) {
          pageController.jumpToPage(currentIndex);
        }

        if (localProfiles.isEmpty) {
          _matchProvider?.loadRecommendations().then((_) {
            if (mounted) {
              syncWithProvider();
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Action Failed: $e");
      if (mounted) {
        setState(() {
          loadingAction = null;
        });
      }

      if (mounted && e is DioException && e.response?.statusCode == 402) {
        FeatureExhaustedModal.show(context, featureType: 'Interest');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to perform action. Please try again.'),
            ),
          );
        }
      }
    }
  }
}
