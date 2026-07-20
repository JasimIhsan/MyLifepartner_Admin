import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:life_partner_again/providers/match_provider.dart';

mixin LikesControllerState<T extends StatefulWidget>
    on State<T>, TickerProviderStateMixin<T>, RouteAware {
  late TabController tabController;
  late AnimationController headerController;
  late Animation<double> headerAnimation;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
    tabController.addListener(_handleTabSelection);

    headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    headerAnimation = CurvedAnimation(
      parent: headerController,
      curve: Curves.easeInOutCubic,
    );
    headerController.value = 1.0; // Initially visible

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDataForCurrentTab();
    });
  }

  // To be used by RouteAware
  void subscribeToRoute(RouteObserver<ModalRoute<void>> routeObserver) {
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  void unsubscribeFromRoute(RouteObserver<ModalRoute<void>> routeObserver) {
    routeObserver.unsubscribe(this);
  }

  @override
  void didPopNext() {
    _loadDataForCurrentTab();
  }

  void _handleTabSelection() {
    if (tabController.indexIsChanging) {
      _loadDataForCurrentTab();
    }
  }

  void _loadDataForCurrentTab() {
    final provider = context.read<MatchProvider>();
    switch (tabController.index) {
      case 0:
        provider.loadMutualMatches();
        break;
      case 1:
        provider.loadReceivedInterests();
        break;
      case 2:
        provider.loadSentInterests();
        break;
    }
  }

  @override
  void dispose() {
    tabController.dispose();
    headerController.dispose();
    super.dispose();
  }

  void setHeaderVisible(bool visible) {
    if (visible) {
      headerController.forward();
    } else {
      headerController.reverse();
    }
  }
}
