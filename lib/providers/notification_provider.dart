import 'package:flutter/foundation.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;
  int _unreadCount = 0;

  List<AppNotification> get notifications => _notifications;
  List<AppNotification> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _unreadCount;
  bool get hasUnread => _unreadCount > 0;

  Future<void> loadNotifications() async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _notificationService.getNotifications();
      _notifications = response.content;
      _updateUnreadCount();
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<void> markAsRead(String notificationId) async {
    _setError(null);

    try {
      await _notificationService.markAsRead(notificationId);

      final index = _notifications.indexWhere(
        (n) => n.id.toString() == notificationId,
      );
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        _updateUnreadCount();
        notifyListeners();
      }
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> markAllAsRead() async {
    _setLoading(true);
    _setError(null);

    try {
      await _notificationService.markAllAsRead();

      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      _updateUnreadCount();
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<bool> deleteNotification(String notificationId) async {
    _setError(null);

    try {
      await _notificationService.deleteNotification(notificationId);

      _notifications.removeWhere((n) => n.id.toString() == notificationId);
      _updateUnreadCount();
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<void> clearAllNotifications() async {
    _setLoading(true);
    _setError(null);

    try {
      await _notificationService.clearAllNotifications();

      _notifications.clear();
      _updateUnreadCount();
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<AppNotification?> createNotification(
    String title,
    String message, {
    String type = 'info',
    Map<String, dynamic>? data,
  }) async {
    _setError(null);

    try {
      final notification = await _notificationService.createNotification(
        title,
        message,
        type: type,
        data: data,
      );

      _notifications.insert(0, notification);
      _updateUnreadCount();
      notifyListeners();
      return notification;
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  void addLocalNotification(AppNotification notification) {
    _notifications.insert(0, notification);
    _updateUnreadCount();
    notifyListeners();
  }

  void _updateUnreadCount() {
    _unreadCount = _notifications.where((n) => !n.isRead).length;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void refresh() {
    loadNotifications();
  }

  // Real-time notification handling
  void handlePushNotification(Map<String, dynamic> data) {
    try {
      final notification = AppNotification.fromJson(data);
      addLocalNotification(notification);
    } catch (e) {
      print('Error handling push notification: $e');
    }
  }

  // Filter notifications by type
  List<AppNotification> getNotificationsByType(NotificationType type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  // Get recent notifications (last 24 hours)
  List<AppNotification> getRecentNotifications() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return _notifications
        .where((n) => n.createdAt?.isAfter(yesterday) == true)
        .toList();
  }
}
