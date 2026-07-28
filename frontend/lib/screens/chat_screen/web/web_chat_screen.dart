import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/models/match_recommendation.dart';
import 'package:life_partner_again/providers/match_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:life_partner_again/screens/chat_screen/chat_detail_screen.dart';
import 'package:life_partner_again/main.dart';

import '../widgets/chat_controller.dart';
import '../widgets/chat_list_tile.dart';

class WebChatScreen extends StatefulWidget {
  const WebChatScreen({super.key});

  @override
  State<WebChatScreen> createState() => _WebChatScreenState();
}

class _WebChatScreenState extends State<WebChatScreen>
    with RouteAware, ChatControllerState<WebChatScreen> {
  MatchRecommendation? selectedProfile;
  int currentUserId = 0;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
  }

  Future<void> _loadCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUserId = prefs.getInt('userId') ?? 0;
    });
  }

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

  void selectProfile(MatchRecommendation profile) {
    setState(() {
      selectedProfile = profile;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1400),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Chat List
              Container(
                width: 380,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 40,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(
                    color: AppColors.borderColor.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        children: [
                          const Text(
                                'Messages',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              )
                              .animate()
                              .fadeIn(duration: 400.ms)
                              .slideX(begin: -0.1),
                        ],
                      ),
                    ),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.borderColor,
                    ),
                    Expanded(
                      child: Consumer<MatchProvider>(
                        builder: (context, provider, child) {
                          if (provider.state == MatchLoadState.loading &&
                              provider.mutualMatches.isEmpty) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                                strokeWidth: 3,
                              ),
                            );
                          }

                          final mutualMatches = provider.mutualMatches;

                          if (mutualMatches.isEmpty) {
                            return _buildEmptyChatState();
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            physics: const BouncingScrollPhysics(),
                            itemCount: mutualMatches.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              color: AppColors.borderColor.withValues(
                                alpha: 0.5,
                              ),
                              indent: 96,
                            ),
                            itemBuilder: (context, index) {
                              final match = mutualMatches[index];
                              return ChatListTile(
                                profile: match,
                                isSelected:
                                    selectedProfile?.userId == match.userId,
                                delay: Duration(milliseconds: index * 50),
                                onTap: () => selectProfile(match),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              // Right Column: Chat Detail
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 40,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    border: Border.all(
                      color: AppColors.borderColor.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: selectedProfile == null
                      ? _buildEmptySelectionState()
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(31),
                          child: ChatDetailScreen(
                            key: ValueKey(selectedProfile!.userId),
                            profile: selectedProfile!,
                            currentUserId: currentUserId,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyChatState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.forum_rounded,
              size: 48,
              color: AppColors.primary,
            ),
          ).animate().scale(
            delay: 200.ms,
            duration: 400.ms,
            curve: Curves.easeOutBack,
          ),
          const SizedBox(height: 24),
          const Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }

  Widget _buildEmptySelectionState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderColor, width: 2),
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 48,
              color: AppColors.textSecondary,
            ),
          ).animate().fadeIn(duration: 400.ms).scale(),
          const SizedBox(height: 24),
          const Text(
            'Select a conversation',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 8),
          const Text(
            'Choose a match from the list\nto start messaging.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }
}
