class AppNotification {
  final int? id;
  final int? userId;
  final String title;
  final String message;
  final NotificationType type;
  final bool isRead;
  final int? relatedEntityId;
  final String? relatedEntityType;
  final DateTime? createdAt;
  final DateTime? readAt;

  AppNotification({
    this.id,
    this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.isRead = false,
    this.relatedEntityId,
    this.relatedEntityType,
    this.createdAt,
    this.readAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      userId: json['userId'],
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.SYSTEM_ALERT,
      ),
      isRead: json['isRead'] ?? false,
      relatedEntityId: json['relatedEntityId'],
      relatedEntityType: json['relatedEntityType'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type.name,
      'isRead': isRead,
      'relatedEntityId': relatedEntityId,
      'relatedEntityType': relatedEntityType,
      'createdAt': createdAt?.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
    };
  }

  AppNotification copyWith({
    int? id,
    int? userId,
    String? title,
    String? message,
    NotificationType? type,
    bool? isRead,
    int? relatedEntityId,
    String? relatedEntityType,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      relatedEntityId: relatedEntityId ?? this.relatedEntityId,
      relatedEntityType: relatedEntityType ?? this.relatedEntityType,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  String get timeAgo {
    if (createdAt == null) return '';

    final now = DateTime.now();
    final difference = now.difference(createdAt!);

    if (difference.inDays > 7) {
      return '${createdAt!.day}/${createdAt!.month}/${createdAt!.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  String toString() {
    return 'AppNotification{id: $id, title: $title, type: $type, isRead: $isRead}';
  }
}

enum NotificationType {
  PROCESSING_COMPLETE,
  PROCESSING_FAILED,
  EMAIL_VERIFICATION,
  PASSWORD_RESET,
  SYSTEM_ALERT,
  INVOICE_UPLOAD,
  EXPORT_READY,
}

extension NotificationTypeExtension on NotificationType {
  String get displayName {
    switch (this) {
      case NotificationType.PROCESSING_COMPLETE:
        return 'Processing Complete';
      case NotificationType.PROCESSING_FAILED:
        return 'Processing Failed';
      case NotificationType.EMAIL_VERIFICATION:
        return 'Email Verification';
      case NotificationType.PASSWORD_RESET:
        return 'Password Reset';
      case NotificationType.SYSTEM_ALERT:
        return 'System Alert';
      case NotificationType.INVOICE_UPLOAD:
        return 'Invoice Upload';
      case NotificationType.EXPORT_READY:
        return 'Export Ready';
    }
  }

  String get iconName {
    switch (this) {
      case NotificationType.PROCESSING_COMPLETE:
        return 'check_circle';
      case NotificationType.PROCESSING_FAILED:
        return 'error';
      case NotificationType.EMAIL_VERIFICATION:
        return 'email';
      case NotificationType.PASSWORD_RESET:
        return 'lock_reset';
      case NotificationType.SYSTEM_ALERT:
        return 'info';
      case NotificationType.INVOICE_UPLOAD:
        return 'upload';
      case NotificationType.EXPORT_READY:
        return 'download';
    }
  }
}
