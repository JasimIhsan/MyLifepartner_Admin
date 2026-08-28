import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/core/app_routes.dart';
import 'package:life_partner_again/main.dart';
import 'package:life_partner_again/providers/match_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/chat_controller.dart';
import '../widgets/chat_list_tile.dart';

class MobileChatScreen extends StatefulWidget {
  const MobileChatScreen({super.key});

  @override
  State<MobileChatScreen> createState() => _MobileChatScreenState();
}

class _MobileChatScreenState extends State<MobileChatScreen>
    with RouteAware, ChatControllerState<MobileChatScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).canvasColor,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Theme.of(context).canvasColor,
              elevation: 0,
              pinned: true,
              centerTitle: false,
              expandedHeight: 100,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: false,
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                title: Text(
                  'Messages',
                  style: TextStyle(
                      color:
                          Theme.of(context).textTheme.bodyLarge?.color ??
                          AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: true,
              child: Consumer<MatchProvider>(
                builder: (context, provider, child) {
                  if (provider.state == MatchLoadState.loading &&
                      provider.mutualMatches.isEmpty) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).primaryColor,
                        strokeWidth: 3,
                      ),
                    );
                  }

                  final mutualMatches = provider.mutualMatches;

                  if (mutualMatches.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 40),
                    physics: const BouncingScrollPhysics(),
                    itemCount: mutualMatches.length,
                    itemBuilder: (context, index) {
                      final match = mutualMatches[index];
                      return ChatListTile(
                        profile: match,
                        delay: Duration(milliseconds: index * 50),
                        onTap: () async {
                          final prefs = await SharedPreferences.getInstance();
                          final currentUserId = prefs.getInt('userId') ?? 0;
                          if (!context.mounted) return;
                          context.push(
                            '/chat-detail/${match.id}',
                            extra: ChatDetailArguments(
                              profile: match,
                              currentUserId: currentUserId,
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.forum_rounded,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
          ).animate().scale(
            delay: 200.ms,
            duration: 400.ms,
            curve: Curves.easeOutBack,
          ),
          const SizedBox(height: 24),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color:
                  Theme.of(context).textTheme.bodyLarge?.color ??
                  AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 8),
          Text(
            'When you match with someone,\nyou can chat with them here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color:
                  Theme.of(context).textTheme.bodyMedium?.color ??
                  AppColors.textSecondary,
              height: 1.5,
            ),
          ).animate().fadeIn(delay: 500.ms),
        ],
      ),
    );
  }
}
