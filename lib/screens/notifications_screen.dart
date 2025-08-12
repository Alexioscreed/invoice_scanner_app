import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/notification_provider.dart';
import '../utils/date_formatter.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshNotifications();
    });
  }

  Future<void> _refreshNotifications() async {
    await Provider.of<NotificationProvider>(
      context,
      listen: false,
    ).loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: () {
              _markAllAsRead();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear all',
            onPressed: () {
              _showClearConfirmation();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshNotifications,
        child: Consumer<NotificationProvider>(
          builder: (context, notificationProvider, child) {
            final notifications = notificationProvider.notifications;

            if (notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_off_outlined,
                      size: 70,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No notifications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You\'re all caught up!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: notifications.length,
              padding: const EdgeInsets.all(8),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final isUnread = !notification.isRead;

                return Dismissible(
                  key: Key('notification_${notification.id}'),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    notificationProvider.deleteNotification(
                      notification.id!.toString(),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notification deleted'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Card(
                    elevation: isUnread ? 2 : 1,
                    margin: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isUnread
                          ? BorderSide(color: Colors.blue.shade200, width: 1)
                          : BorderSide.none,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: _getNotificationColor(
                          notification.type.name,
                        ),
                        child: Icon(
                          _getNotificationIcon(notification.type.name),
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight: isUnread
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(notification.message),
                          const SizedBox(height: 4),
                          Text(
                            DateFormatter.formatDateTime(
                              notification.createdAt!,
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                      trailing: isUnread
                          ? IconButton(
                              icon: const Icon(Icons.done),
                              tooltip: 'Mark as read',
                              onPressed: () {
                                notificationProvider.markAsRead(
                                  notification.id!.toString(),
                                );
                              },
                            )
                          : null,
                      onTap: () {
                        if (notification.relatedEntityType == 'INVOICE' &&
                            notification.relatedEntityId != null) {
                          // Mark as read
                          if (isUnread) {
                            notificationProvider.markAsRead(
                              notification.id!.toString(),
                            );
                          }
                          // Navigate to related invoice
                          context.go(
                            '/invoice-detail/${notification.relatedEntityId}',
                          );
                        }
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _markAllAsRead() async {
    final notificationProvider = Provider.of<NotificationProvider>(
      context,
      listen: false,
    );
    await notificationProvider.markAllAsRead();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text(
          'Are you sure you want to clear all notifications? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final notificationProvider = Provider.of<NotificationProvider>(
                context,
                listen: false,
              );
              await notificationProvider.clearAllNotifications();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All notifications cleared'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('CLEAR'),
          ),
        ],
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type.toUpperCase()) {
      case 'SYSTEM_ALERT':
        return Colors.red;
      case 'INVOICE_REMINDER':
        return Colors.orange;
      case 'INVOICE_PROCESSED':
        return Colors.green;
      case 'ACCOUNT_UPDATE':
        return Colors.blue;
      default:
        return Colors.purple;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toUpperCase()) {
      case 'SYSTEM_ALERT':
        return Icons.warning_outlined;
      case 'INVOICE_REMINDER':
        return Icons.event_outlined;
      case 'INVOICE_PROCESSED':
        return Icons.description_outlined;
      case 'ACCOUNT_UPDATE':
        return Icons.person_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }
}
