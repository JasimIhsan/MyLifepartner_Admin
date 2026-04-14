import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mylifepartner/core/app_colors.dart';
import 'package:mylifepartner/models/match_recommendation.dart';
import 'package:mylifepartner/providers/match_provider.dart';
import 'package:mylifepartner/providers/chat_provider.dart';
import 'package:mylifepartner/screens/chat_screen/chat_detail_screen.dart';

class ChatPlaceholderScreen extends StatefulWidget {
  const ChatPlaceholderScreen({super.key});

  @override
  State<ChatPlaceholderScreen> createState() => _ChatPlaceholderScreenState();
}

class _ChatPlaceholderScreenState extends State<ChatPlaceholderScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MatchProvider>().loadMutualMatches();
      context.read<ChatProvider>().loadConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textPrimary, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'Messages',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Consumer<MatchProvider>(
        builder: (context, provider, child) {
          if (provider.state == MatchLoadState.loading &&
              provider.mutualMatches.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            );
          }

          final mutualMatches = provider.mutualMatches;

          if (mutualMatches.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: AppColors.textPrimary, width: 1.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.message_outlined, size: 36),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No messages yet',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'When you match with someone,\nyou can chat with them here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: mutualMatches.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              indent: 86,
              color: AppColors.black.withValues(alpha: 0.05),
            ),
            itemBuilder: (context, index) {
              final match = mutualMatches[index];
              return _ChatListTile(profile: match);
            },
          );
        },
      ),
    );
  }
}

class _ChatListTile extends StatelessWidget {
  final MatchRecommendation profile;

  const _ChatListTile({required this.profile});

  String? get _imageUrl {
    final primary = profile.images.where((img) => img.isPrimary);
    if (primary.isNotEmpty) return primary.first.imageUrl;
    if (profile.images.isNotEmpty) return profile.images.first.imageUrl;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Watch ChatProvider for getting the latest conversation summary
    final chatProvider = context.watch<ChatProvider>();
    final conversation = chatProvider.conversations.where((c) => c.otherUserId == profile.id).firstOrNull;
    final lastMessageStr = conversation?.lastMessage ?? 'Tap to start chatting';
    
    return InkWell(
      onTap: () async {
        final prefs = await SharedPreferences.getInstance();
        final currentUserId = prefs.getInt('userId') ?? 0;
        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(
              profile: profile,
              currentUserId: currentUserId,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.divider,
                image: _imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(_imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _imageUrl == null
                  ? const Center(
                      child: Icon(Icons.person,
                          color: AppColors.textSecondary),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        profile.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (conversation == null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'New Match',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    lastMessageStr,
                    style: TextStyle(
                      fontSize: 14,
                      color: conversation == null ? AppColors.textSecondary : AppColors.textPrimary,
                      fontWeight: conversation == null ? FontWeight.normal : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
