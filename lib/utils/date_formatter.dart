import 'package:intl/intl.dart';

class DateFormatter {
  static String formatDate(DateTime date) {
    return DateFormat('MM/dd/yyyy').format(date);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MM/dd/yyyy hh:mm a').format(dateTime);
  }

  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year(s) ago';
    }
    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month(s) ago';
    }
    if (difference.inDays > 0) {
      return '${difference.inDays} day(s) ago';
    }
    if (difference.inHours > 0) {
      return '${difference.inHours} hour(s) ago';
    }
    if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute(s) ago';
    }
    return 'Just now';
  }

  // Convert to ISO format for API communication
  static String toIsoDate(DateTime date) {
    return date.toIso8601String().split('T')[0]; // YYYY-MM-DD
  }

  // Parse ISO format date from API
  static DateTime fromIsoDate(String isoDate) {
    return DateTime.parse(isoDate);
  }
}
