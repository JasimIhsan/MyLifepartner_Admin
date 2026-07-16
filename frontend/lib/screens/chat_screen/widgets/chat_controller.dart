import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:life_partner_again/providers/chat_provider.dart';
import 'package:life_partner_again/providers/match_provider.dart';

mixin ChatControllerState<T extends StatefulWidget> on State<T>, RouteAware {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadChatData();
    });
  }

  void subscribeToRoute(RouteObserver<ModalRoute<void>> routeObserver) {
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  void unsubscribeFromRoute(RouteObserver<ModalRoute<void>> routeObserver) {
    routeObserver.unsubscribe(this);
  }

  @override
  void didPopNext() {
    loadChatData();
  }

  Future<void> loadChatData() async {
    if (!mounted) return;
    final matchProvider = context.read<MatchProvider>();
    final chatProvider = context.read<ChatProvider>();

    await matchProvider.loadMutualMatches();
    await chatProvider.loadConversations();

    if (mounted) {
      final userIds = matchProvider.mutualMatches
          .map((m) => m.userId)
          .toList();
      if (userIds.isNotEmpty) {
        chatProvider.subscribeToUsersStatus(userIds);
      }
    }
  }
}
