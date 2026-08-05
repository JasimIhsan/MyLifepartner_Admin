import 'package:flutter/material.dart';
import 'package:life_partner_again/providers/notification_provider.dart';
import 'package:provider/provider.dart';

class NotificationScreen extends StatefulWidget {
  final VoidCallback onBack;

  const NotificationScreen({super.key, required this.onBack});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<NotificationProvider>();
      provider.fetchNotifications().then((_) {
        provider.markAllAsRead();
      });
    });
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
                    if (provider.notifications.isEmpty) return const SizedBox();
                    return Text(
                      "${provider.notifications.length} Total",
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
          const Divider(height: 1),

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
                    await provider.fetchNotifications();
                    await provider.markAllAsRead();
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: provider.notifications.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 64),
                    itemBuilder: (context, index) {
                      final notification = provider.notifications[index];
                      final iconData = _getNotificationIcon(notification.type);
                      final iconColor = _getIconColor(notification.type);

                      return Container(
                        color: notification.isRead
                            ? Colors.transparent
                            : Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.06),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: iconColor.withValues(
                                  alpha: 0.12,
                                ),
                                child: Icon(
                                  iconData,
                                  color: iconColor,
                                  size: 22,
                                ),
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
                                        color: Theme.of(
                                          context,
                                        ).scaffoldBackgroundColor,
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
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatTimeAgo(notification.createdAt),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
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
