import '../models/notification.dart';
import '../models/api_models.dart';
import 'api_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final ApiService _apiService = ApiService();

  Future<PaginatedResponse<AppNotification>> getNotifications({
    int page = 0,
    int size = 20,
  }) async {
    try {
      return await _apiService.getNotifications(page: page, size: size);
    } catch (e) {
      throw e;
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _apiService.markNotificationAsRead(int.parse(notificationId));
    } catch (e) {
      throw e;
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _apiService.deleteNotification(int.parse(notificationId));
    } catch (e) {
      throw e;
    }
  }

  Future<void> clearAllNotifications() async {
    try {
      await _apiService.clearAllNotifications();
    } catch (e) {
      throw e;
    }
  }

  Future<AppNotification> createNotification(
    String title,
    String message, {
    String type = 'SYSTEM_ALERT',
    Map<String, dynamic>? data,
  }) async {
    try {
      return await _apiService.createNotification(
        title,
        message,
        type: type,
        data: data,
      );
    } catch (e) {
      throw e;
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _apiService.markAllNotificationsAsRead();
    } catch (e) {
      throw e;
    }
  }

  Future<int> getUnreadCount() async {
    try {
      return await _apiService.getUnreadNotificationCount();
    } catch (e) {
      return 0; // Return 0 if API fails
    }
  }

  String getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.PROCESSING_COMPLETE:
        return '✅';
      case NotificationType.PROCESSING_FAILED:
        return '❌';
      case NotificationType.EMAIL_VERIFICATION:
        return '📧';
      case NotificationType.PASSWORD_RESET:
        return '🔒';
      case NotificationType.SYSTEM_ALERT:
        return 'ℹ️';
      case NotificationType.INVOICE_UPLOAD:
        return '📄';
      case NotificationType.EXPORT_READY:
        return '📥';
    }
  }

  String getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.PROCESSING_COMPLETE:
        return '#4CAF50'; // Green
      case NotificationType.PROCESSING_FAILED:
        return '#F44336'; // Red
      case NotificationType.EMAIL_VERIFICATION:
        return '#2196F3'; // Blue
      case NotificationType.PASSWORD_RESET:
        return '#FF9800'; // Orange
      case NotificationType.SYSTEM_ALERT:
        return '#9C27B0'; // Purple
      case NotificationType.INVOICE_UPLOAD:
        return '#607D8B'; // Blue Grey
      case NotificationType.EXPORT_READY:
        return '#00BCD4'; // Cyan
    }
  }

  bool isImportantNotification(NotificationType type) {
    return [
      NotificationType.PROCESSING_FAILED,
      NotificationType.EMAIL_VERIFICATION,
      NotificationType.PASSWORD_RESET,
      NotificationType.SYSTEM_ALERT,
    ].contains(type);
  }

  String formatNotificationTime(DateTime? createdAt) {
    if (createdAt == null) return '';

    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  List<AppNotification> sortNotificationsByImportance(
    List<AppNotification> notifications,
  ) {
    return notifications..sort((a, b) {
      // First sort by read status (unread first)
      if (a.isRead != b.isRead) {
        return a.isRead ? 1 : -1;
      }

      // Then by importance
      final aImportant = isImportantNotification(a.type);
      final bImportant = isImportantNotification(b.type);

      if (aImportant != bImportant) {
        return aImportant ? -1 : 1;
      }

      // Finally by creation time (newest first)
      if (a.createdAt != null && b.createdAt != null) {
        return b.createdAt!.compareTo(a.createdAt!);
      }

      return 0;
    });
  }

  List<AppNotification> filterNotificationsByType(
    List<AppNotification> notifications,
    List<NotificationType> types,
  ) {
    return notifications
        .where((notification) => types.contains(notification.type))
        .toList();
  }

  List<AppNotification> getUnreadNotifications(
    List<AppNotification> notifications,
  ) {
    return notifications.where((notification) => !notification.isRead).toList();
  }

  Map<NotificationType, int> getNotificationCountsByType(
    List<AppNotification> notifications,
  ) {
    final Map<NotificationType, int> counts = {};

    for (final notification in notifications) {
      counts[notification.type] = (counts[notification.type] ?? 0) + 1;
    }

    return counts;
  }
}
