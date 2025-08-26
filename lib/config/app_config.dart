import 'package:flutter/foundation.dart';
import '../utils/logger.dart';

class AppConfig {
  // Server configuration
  static const String serverIP = '192.168.0.206'; // Your computer's IP address
  static const int serverPort = 8080;

  // API URLs
  static String get baseApiUrl => 'http://$serverIP:$serverPort/api';
  static String get authEndpoint => '$baseApiUrl/auth';
  static String get invoicesEndpoint => '$baseApiUrl/invoices';
  static String get notificationsEndpoint => '$baseApiUrl/notifications';
  static String get usersEndpoint => '$baseApiUrl/users';
  static String get analyticsEndpoint => '$invoicesEndpoint/analytics';

  // Authentication endpoints
  static String get loginUrl => '$authEndpoint/login';
  static String get registerUrl => '$authEndpoint/register';
  static String get refreshTokenUrl => '$authEndpoint/refresh';
  static String get logoutUrl => '$authEndpoint/logout';
  static String get verifyEmailUrl => '$authEndpoint/verify-email';
  static String get forgotPasswordUrl => '$authEndpoint/forgot-password';
  static String get resetPasswordUrl => '$authEndpoint/reset-password';

  // File upload configuration
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB in bytes
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'pdf'];

  // App configuration
  static const bool enableDebugLogs = true;
  static const bool enableDetailedErrorLogs = true;

  // Network timeouts (in seconds)
  static const int connectionTimeout = 15;
  static const int receiveTimeout = 30;
  static const int sendTimeout = 30;
  static const int otpTimeout = 20;

  // Retry configuration
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // Storage keys
  static const String tokenStorageKey = 'auth_token';
  static const String refreshTokenStorageKey = 'refresh_token';
  static const String userStorageKey = 'user_data';
  static const String settingsStorageKey = 'app_settings';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // OCR Processing
  static const Duration ocrPollingInterval = Duration(seconds: 2);
  static const Duration maxOcrProcessingTime = Duration(minutes: 5);

  // App metadata
  static const String appName = 'Invoice Scanner';
  static const String appVersion = '1.0.0';
  static const String supportEmail = 'support@invoicescanner.com';

  // Development helpers
  static void printConfig() {
    if (enableDebugLogs && !kReleaseMode) {
      // Use the AppLogger instead of print for consistent logging
      AppLogger.info('Invoice Scanner App Started');
      AppLogger.debug('API Endpoint: $baseApiUrl');
    }
  }

  // Network configuration helper
  static Map<String, dynamic> get httpClientConfig => {
    'connectTimeout': connectionTimeout * 1000,
    'receiveTimeout': receiveTimeout * 1000,
    'sendTimeout': sendTimeout * 1000,
    'followRedirects': true,
    'maxRedirects': 3,
  };
}
