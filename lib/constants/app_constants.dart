class AppConstants {
  // API Configuration
  static const String baseUrl = 'http://localhost:8080/api';
  static const String authEndpoint = '/auth';
  static const String invoicesEndpoint = '/invoices';
  static const String notificationsEndpoint = '/notifications';
  static const String usersEndpoint = '/users';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';

  // File Upload
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png'];
  static const List<String> allowedDocumentTypes = ['pdf'];

  // Categories
  static const List<String> defaultCategories = [
    'Office Supplies',
    'Travel',
    'Meals & Entertainment',
    'Equipment',
    'Software',
    'Marketing',
    'Professional Services',
    'Utilities',
    'Rent',
    'Insurance',
    'Other',
  ];

  // Pagination
  static const int defaultPageSize = 20;

  // Timeouts
  static const int connectionTimeout = 30; // seconds
  static const int receiveTimeout = 30; // seconds
}
