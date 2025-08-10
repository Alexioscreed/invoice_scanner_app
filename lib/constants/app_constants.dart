import '../config/app_config.dart';

class AppConstants {
  // API Configuration - now using AppConfig
  static String get baseUrl => AppConfig.baseApiUrl;
  static String get authEndpoint => AppConfig.authEndpoint;
  static String get invoicesEndpoint => AppConfig.invoicesEndpoint;
  static String get notificationsEndpoint => AppConfig.notificationsEndpoint;
  static String get usersEndpoint => AppConfig.usersEndpoint;

  // Storage Keys - using AppConfig
  static String get tokenKey => AppConfig.tokenStorageKey;
  static String get userKey => AppConfig.userStorageKey;
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';

  // File Upload - using AppConfig
  static int get maxFileSize => AppConfig.maxFileSize;
  static List<String> get allowedImageTypes => AppConfig.allowedImageTypes;
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

  // Pagination - using AppConfig
  static int get defaultPageSize => AppConfig.defaultPageSize;

  // Timeouts - using AppConfig
  static int get connectionTimeout => AppConfig.connectionTimeout;
  static int get receiveTimeout => AppConfig.receiveTimeout;
}
