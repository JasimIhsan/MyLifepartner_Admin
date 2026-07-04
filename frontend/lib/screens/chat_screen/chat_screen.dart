import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/models/match_recommendation.dart';
import 'package:life_partner_again/providers/chat_provider.dart';
import 'package:life_partner_again/providers/match_provider.dart';
import 'package:life_partner_again/screens/chat_screen/chat_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:life_partner_again/main.dart';

class ChatPlaceholderScreen extends StatefulWidget {
  const ChatPlaceholderScreen({super.key});

  @override
  State<ChatPlaceholderScreen> createState() => _ChatPlaceholderScreenState();
}

class _ChatPlaceholderScreenState extends State<ChatPlaceholderScreen> with RouteAware {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChatData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _loadChatData();
  }

  Future<void> _loadChatData() async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            pinned: true,
            centerTitle: false,
            expandedHeight: 100,
            automaticallyImplyLeading: false,
            flexibleSpace: const FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                'Messages',
                style: TextStyle(
                  color: AppColors.textPrimary,
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
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
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
                    return _ChatListTile(
                      profile: match,
                      delay: Duration(milliseconds: index * 50),
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
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 8),
          const Text(
            'When you match with someone,\nyou can chat with them here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ).animate().fadeIn(delay: 500.ms),
        ],
      ),
    );
  }
}

class _ChatListTile extends StatefulWidget {
  final MatchRecommendation profile;
  final Duration delay;

  const _ChatListTile({required this.profile, required this.delay});

  @override
  State<_ChatListTile> createState() => _ChatListTileState();
}

class _ChatListTileState extends State<_ChatListTile> {
  bool _isTapped = false;

  String? get _imageUrl {
    final primary = widget.profile.images.where((img) => img.isPrimary);
    if (primary.isNotEmpty) return primary.first.imageUrl;
    if (widget.profile.images.isNotEmpty) {
      return widget.profile.images.first.imageUrl;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final conversation = chatProvider.conversations
        .where((c) => c.otherUserId == widget.profile.userId)
        .firstOrNull;
    final lastMessageStr = chatProvider.isUserTyping(widget.profile.userId)
        ? 'typing...'
        : (conversation?.displayLastMessage ?? 'Tap to start chatting');
    final hasUnread = chatProvider.hasUnreadNudge(widget.profile.userId);
    final isOnline = chatProvider.isUserOnline(widget.profile.userId);
    final isTyping = chatProvider.isUserTyping(widget.profile.userId);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isTapped = true),
      onTapUp: (_) => setState(() => _isTapped = false),
      onTapCancel: () => setState(() => _isTapped = false),
      onTap: () async {
        final prefs = await SharedPreferences.getInstance();
        final currentUserId = prefs.getInt('userId') ?? 0;
        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(
              profile: widget.profile,
              currentUserId: currentUserId,
            ),
          ),
        );
      },
      child:
          AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                color: _isTapped
                    ? AppColors.divider.withValues(alpha: 0.5)
                    : Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    _buildAvatar(isOnline),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.profile.name,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (hasUnread)
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              else if (conversation == null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'NEW',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (lastMessageStr == 'Attachment' ||
                                  lastMessageStr.toLowerCase().contains(
                                    'video call',
                                  ) ||
                                  lastMessageStr.toLowerCase().contains(
                                    'audio call',
                                  )) ...[
                                Icon(
                                  lastMessageStr == 'Attachment'
                                      ? Icons.attachment_rounded
                                      : lastMessageStr.toLowerCase().contains(
                                          'video call',
                                        )
                                      ? Icons.videocam_rounded
                                      : Icons.call_rounded,
                                  size: 14,
                                  color: lastMessageStr.startsWith('Missed')
                                      ? Colors.red
                                      : (hasUnread
                                            ? AppColors.textPrimary
                                            : AppColors.textSecondary),
                                ),
                                const SizedBox(width: 4),
                              ],
                              Expanded(
                                child: Text(
                                  lastMessageStr,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: isTyping
                                        ? AppColors.primary
                                        : (lastMessageStr.startsWith('Missed')
                                              ? Colors.red
                                              : (conversation == null
                                                    ? AppColors.textSecondary
                                                    : (hasUnread
                                                          ? AppColors
                                                                .textPrimary
                                                          : AppColors
                                                                .textSecondary))),
                                    fontWeight: isTyping || hasUnread
                                        ? FontWeight.w600
                                        : (conversation == null
                                              ? FontWeight.normal
                                              : FontWeight.w400),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
              .animate()
              .fadeIn(delay: widget.delay, duration: 400.ms)
              .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
    );
  }

  Widget _buildAvatar(bool isOnline) {
    return Stack(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: _imageUrl != null
                ? Image.network(
                    _imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildFallbackAvatar(),
                  )
                : _buildFallbackAvatar(),
          ),
        ),
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFallbackAvatar() {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.1),
      child: Center(
        child: Text(
          widget.profile.name.isNotEmpty
              ? widget.profile.name[0].toUpperCase()
              : '?',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
