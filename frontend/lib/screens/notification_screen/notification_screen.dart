import 'package:flutter/material.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/models/in_app_notification.dart';
import 'package:life_partner_again/providers/notification_provider.dart';
import 'package:provider/provider.dart';

class NotificationScreen extends StatefulWidget {
  final VoidCallback onBack;

  const NotificationScreen({super.key, required this.onBack});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<NotificationProvider>();
      provider.fetchNotifications(isRefresh: true).then((_) {
        provider.markAllAsRead();
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<NotificationProvider>();
      if (!provider.isLoadingNotifications && provider.hasMore) {
        provider.fetchNotifications();
      }
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'NEW_MESSAGE':
        return Icons.chat_bubble_outline_rounded;
      case 'NEW_LIKE':
      case 'NEW_MATCH':
      case 'INTEREST_ACCEPTED':
        return Icons.favorite_rounded;
      case 'IMAGE_ACCESS_REQUESTED':
      case 'IMAGE_ACCESS_GRANTED':
        return Icons.lock_open_rounded;
      case 'SUBSCRIPTION_SUCCESS':
      case 'SUBSCRIPTION_EXPIRING':
      case 'PAYMENT_FAILED':
        return Icons.card_membership_rounded;
      case 'MISSED_CALL':
        return Icons.phone_missed_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'NEW_LIKE':
      case 'NEW_MATCH':
      case 'INTEREST_ACCEPTED':
        return Colors.pink;
      case 'NEW_MESSAGE':
        return Colors.blue;
      case 'IMAGE_ACCESS_REQUESTED':
      case 'IMAGE_ACCESS_GRANTED':
        return Colors.purple;
      case 'SUBSCRIPTION_SUCCESS':
        return Colors.green;
      case 'PAYMENT_FAILED':
      case 'MISSED_CALL':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _getDateGroup(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (date == today) return 'Today';
    if (date == yesterday) return 'Yesterday';
    return 'Earlier';
  }

  Widget _buildCategoryChip(
    BuildContext context,
    String category,
    NotificationProvider provider,
  ) {
    final isSelected = provider.selectedCategory == category;
    IconData? icon;
    Color? iconColor;

    switch (category) {
      case 'Messages':
        icon = Icons.chat_bubble_outline_rounded;
        iconColor = Colors.blue;
        break;
      case 'Subscriptions':
        icon = Icons.workspace_premium_outlined;
        iconColor = Colors.orange;
        break;
      case 'Alerts':
        icon = Icons.warning_amber_rounded;
        iconColor = Colors.red;
        break;
      case 'System':
        icon = Icons.settings_outlined;
        iconColor = Colors.green;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => provider.selectCategory(category),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accent : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.accent : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? Colors.white : iconColor,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    InAppNotification notification,
  ) {
    final iconData = _getNotificationIcon(notification.type);
    final iconColor = _getIconColor(notification.type);

    return InkWell(
      onTap: () {
        if (!notification.isRead) {
          context.read<NotificationProvider>().markAsRead(notification.id);
        }
      },
      child: Container(
        color: notification.isRead
            ? Colors.transparent
            : Theme.of(context).primaryColor.withValues(alpha: 0.06),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: iconColor.withValues(alpha: 0.12),
                child: Icon(iconData, color: iconColor, size: 22),
              ),
              if (!notification.isRead)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: notification.isRead
                  ? FontWeight.w500
                  : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(
                notification.body,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTimeAgo(notification.createdAt),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        widget.onBack();
      },
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Notifications",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Consumer<NotificationProvider>(
                  builder: (context, provider, _) {
                    if (provider.totalCount == 0 &&
                        provider.notifications.isEmpty) {
                      return const SizedBox();
                    }
                    return Text(
                      "${provider.totalCount} Total",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Filter Chips
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              final categories = [
                'All',
                'Messages',
                'Subscriptions',
                'Alerts',
                'System',
              ];
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: categories
                      .map((c) => _buildCategoryChip(context, c, provider))
                      .toList(),
                ),
              );
            },
          ),

          // Content
          Expanded(
            child: Consumer<NotificationProvider>(
              builder: (context, provider, child) {
                if (provider.isLoadingNotifications &&
                    provider.notifications.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.notifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No notifications yet",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "We'll notify you when something important happens",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await provider.fetchNotifications(isRefresh: true);
                    await provider.markAllAsRead();
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount:
                        provider.notifications.length +
                        (provider.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == provider.notifications.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final notification = provider.notifications[index];
                      final currentGroup = _getDateGroup(
                        notification.createdAt,
                      );
                      final isFirstInGroup =
                          index == 0 ||
                          _getDateGroup(
                                provider.notifications[index - 1].createdAt,
                              ) !=
                              currentGroup;

                      Widget itemWidget = _buildNotificationItem(
                        context,
                        notification,
                      );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isFirstInGroup)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Text(
                                currentGroup,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          itemWidget,
                          if (index < provider.notifications.length - 1)
                            const Divider(
                              height: 1,
                              indent: 20,
                              endIndent: 20,
                              color: AppColors.borderColor,
                            ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
