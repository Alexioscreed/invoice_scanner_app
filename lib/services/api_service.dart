import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';
import '../constants/app_constants.dart';
import '../models/auth_models.dart';
import '../models/api_models.dart';
import '../models/user.dart';
import '../models/invoice.dart';
import '../models/notification.dart';
import '../utils/logger.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  void init() {
    AppLogger.info('🚀 Initializing API Service', context: 'ApiService');
    AppConfig.printConfig();

    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseApiUrl,
        connectTimeout: Duration(seconds: AppConfig.connectionTimeout),
        receiveTimeout: Duration(seconds: AppConfig.receiveTimeout),
        sendTimeout: Duration(seconds: AppConfig.sendTimeout),
        headers: {'Content-Type': 'application/json'},
        validateStatus: (status) =>
            status! < 500, // Accept all responses except server errors
      ),
    );

    // Add interceptor for token and logging
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: AppConfig.tokenStorageKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // Add start time to track request duration
          options.extra['start_time'] = DateTime.now();

          // Log the API request
          AppLogger.logApiRequest(
            method: options.method,
            url: options.uri.toString(),
            headers: options.headers,
            body: options.data,
          );

          handler.next(options);
        },
        onResponse: (response, handler) {
          final endTime = DateTime.now();
          final startTime =
              response.requestOptions.extra['start_time'] as DateTime? ??
              endTime;
          final duration = endTime.difference(startTime);

          AppLogger.logApiResponse(
            method: response.requestOptions.method,
            url: response.requestOptions.uri.toString(),
            statusCode: response.statusCode ?? 0,
            duration: duration,
            response: response.data,
          );

          handler.next(response);
        },
        onError: (error, handler) async {
          final endTime = DateTime.now();
          final startTime =
              error.requestOptions.extra['start_time'] as DateTime? ?? endTime;
          final duration = endTime.difference(startTime);

          AppLogger.logApiResponse(
            method: error.requestOptions.method,
            url: error.requestOptions.uri.toString(),
            statusCode: error.response?.statusCode ?? 0,
            duration: duration,
            response: error.response?.data,
          );

          if (AppConfig.enableDetailedErrorLogs) {
            AppLogger.error(
              'API Error Details: ${error.message}',
              context: 'ApiService',
              error: error,
            );
            print('Error Message: ${error.message}');
          }

          if (error.response?.statusCode == 401) {
            // Token expired, clear storage and redirect to login
            await _storage.delete(key: AppConfig.tokenStorageKey);
            await _storage.delete(key: AppConfig.userStorageKey);
          }
          handler.next(error);
        },
      ),
    );

    // Add logging interceptor in debug mode
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => AppLogger.debug('$obj', context: 'API'),
      ),
    );
  }

  // Auth APIs
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      AppLogger.info(
        'Attempting login for user: ${request.email}',
        context: 'API',
      );
      // Use the configured login URL from AppConfig
      final response = await _dio.post(
        AppConfig.loginUrl,
        data: request.toJson(),
      );

      AppLogger.debug(
        'Login response type: ${response.data.runtimeType}, status: ${response.statusCode}',
        context: 'API',
      );

      // Handle different response types
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is Map<String, dynamic>) {
          AppLogger.info(
            'Login successful for: ${request.email}',
            context: 'API',
          );
          return AuthResponse.fromJson(response.data);
        } else if (response.data is String) {
          // If response is a string, create a simple response with just the message
          return AuthResponse(message: response.data);
        } else {
          // Unexpected response format but successful status
          return AuthResponse(
            message: "Login successful but unexpected response format",
          );
        }
      } else {
        // Non-error status code but not 200/201
        return AuthResponse(
          message: "Login failed with status: ${response.statusCode}",
        );
      }
    } on DioException catch (e) {
      // Log the full error for debugging
      AppLogger.error('Login API error: ${e.type}', context: 'API', error: e);

      // Get more detailed error info if available
      String errorDetails = '';
      if (e.response?.data != null) {
        errorDetails = e.response?.data is String
            ? e.response?.data
            : e.response?.data.toString();
      }

      AppLogger.error('Login error details: $errorDetails', context: 'API');
      throw _handleDioError(e);
    }
  }

  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: request.toJson(),
      );
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('${AppConstants.authEndpoint}/logout');
    } catch (e) {
      // Ignore logout errors
    } finally {
      await _storage.delete(key: AppConstants.tokenKey);
      await _storage.delete(key: AppConstants.userKey);
    }
  }

  Future<void> requestPasswordReset(PasswordResetRequest request) async {
    try {
      await _dio.post(
        '${AppConstants.authEndpoint}/reset-password',
        data: request.toJson(),
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> resetPassword(ResetPasswordRequest request) async {
    try {
      await _dio.post(
        '${AppConstants.authEndpoint}/reset-password/confirm',
        data: request.toJson(),
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> verifyEmail(String token) async {
    try {
      await _dio.get('${AppConstants.authEndpoint}/verify-email?token=$token');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // User APIs
  Future<User> getCurrentUser() async {
    try {
      final response = await _dio.get('${AppConstants.usersEndpoint}/me');
      return User.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<User> updateProfile(UpdateProfileRequest request) async {
    try {
      final response = await _dio.put(
        '${AppConstants.usersEndpoint}/me',
        data: request.toJson(),
      );
      return User.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> changePassword(ChangePasswordRequest request) async {
    try {
      await _dio.put(
        '${AppConstants.usersEndpoint}/me/password',
        data: request.toJson(),
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Invoice APIs
  Future<PaginatedResponse<Invoice>> getInvoices(
    InvoiceSearchRequest request,
  ) async {
    try {
      final response = await _dio.get(
        AppConstants.invoicesEndpoint,
        queryParameters: request.toQueryParams(),
      );
      return PaginatedResponse.fromJson(response.data, Invoice.fromJson);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Invoice> getInvoice(int id) async {
    try {
      final response = await _dio.get('${AppConstants.invoicesEndpoint}/$id');
      return Invoice.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> createInvoice(Map<String, dynamic> data) async {
    try {
      return await _dio.post(AppConstants.invoicesEndpoint, data: data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Invoice> updateInvoice(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(
        '${AppConstants.invoicesEndpoint}/$id',
        data: data,
      );
      return Invoice.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Invoice> uploadInvoiceFile(File file) async {
    try {
      final fileName = file.path.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final response = await _dio.post(
        '${AppConstants.invoicesEndpoint}/upload',
        data: formData,
      );

      return Invoice.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> exportInvoices({
    required String format,
    List<int>? invoiceIds,
    String? dateRange,
    String? category,
  }) async {
    try {
      final queryParams = <String, dynamic>{'format': format};

      if (invoiceIds != null && invoiceIds.isNotEmpty) {
        queryParams['ids'] = invoiceIds.join(',');
      }

      if (dateRange != null) {
        queryParams['dateRange'] = dateRange;
      }

      if (category != null) {
        queryParams['category'] = category;
      }

      return await _dio.get(
        '${AppConstants.invoicesEndpoint}/export',
        queryParameters: queryParams,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Accept': _getContentTypeForFormat(format)},
        ),
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  String _getContentTypeForFormat(String format) {
    switch (format.toLowerCase()) {
      case 'csv':
        return 'text/csv';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> deleteInvoice(int id) async {
    try {
      await _dio.delete('${AppConstants.invoicesEndpoint}/$id');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Invoice> uploadInvoice(File file) async {
    try {
      String fileName = file.path.split('/').last;
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final response = await _dio.post(
        '${AppConstants.invoicesEndpoint}/upload',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      return Invoice.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ProcessingStatusResponse> getProcessingStatus(String uploadId) async {
    try {
      final response = await _dio.get(
        '${AppConstants.invoicesEndpoint}/processing-status/$uploadId',
      );
      return ProcessingStatusResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<String>> getCategories() async {
    try {
      final response = await _dio.get(
        '${AppConstants.invoicesEndpoint}/categories',
      );
      return List<String>.from(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<String>> getVendors() async {
    try {
      final response = await _dio.get(
        '${AppConstants.invoicesEndpoint}/vendors',
      );
      return List<String>.from(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Export APIs with date ranges
  Future<Response> exportInvoicesWithDateRange({
    String format = 'csv',
    DateTime? startDate,
    DateTime? endDate,
    String? category, // Not used by backend but kept for backward compatibility
    List<int>?
    invoiceIds, // Not used by backend but kept for backward compatibility
  }) async {
    try {
      final queryParams = <String, dynamic>{'format': format};

      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String().split('T')[0];
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String().split('T')[0];
      }
      // Note: The backend doesn't support filtering by category or invoiceIds,
      // but we keep these parameters for future implementation

      return await _dio.get(
        '${AppConstants.invoicesEndpoint}/export',
        queryParameters: queryParams,
        options: Options(responseType: ResponseType.bytes),
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Notification APIs
  Future<PaginatedResponse<AppNotification>> getNotifications({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _dio.get(
        AppConstants.notificationsEndpoint,
        queryParameters: {'page': page, 'size': size},
      );
      return PaginatedResponse.fromJson(
        response.data,
        AppNotification.fromJson,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> markNotificationAsRead(int id) async {
    try {
      await _dio.put('${AppConstants.notificationsEndpoint}/$id/read');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    try {
      await _dio.put('${AppConstants.notificationsEndpoint}/mark-all-read');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<int> getUnreadNotificationCount() async {
    try {
      final response = await _dio.get(
        '${AppConstants.notificationsEndpoint}/unread-count',
      );
      return response.data['count'] ?? 0;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> deleteNotification(int id) async {
    try {
      await _dio.delete('${AppConstants.notificationsEndpoint}/$id');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> clearAllNotifications() async {
    try {
      await _dio.delete('${AppConstants.notificationsEndpoint}/clear-all');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<AppNotification> createNotification(
    String title,
    String message, {
    String type = 'SYSTEM_ALERT',
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dio.post(
        AppConstants.notificationsEndpoint,
        data: {'title': title, 'message': message, 'type': type, 'data': data},
      );
      return AppNotification.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Analytics APIs
  Future<Map<String, dynamic>> getAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String().split('T')[0];
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String().split('T')[0];
      }

      final response = await _dio.get(
        '${AppConstants.invoicesEndpoint}/analytics',
        queryParameters: queryParams,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getExpenseSummary({
    required String period,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Get all analytics data for the specified period
      final analytics = await getAnalytics(
        startDate: startDate,
        endDate: endDate,
      );

      // Return the monthly spending data from the analytics response
      // and format it according to the requested period
      return {
        'totalAmount': analytics['totalAmount'] ?? 0,
        'monthlyData': analytics['monthlySpending'] ?? [],
        'period': period,
      };
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getVendorAnalysis({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 10,
  }) async {
    try {
      // Get all analytics data and extract vendor information
      final analytics = await getAnalytics(
        startDate: startDate,
        endDate: endDate,
      );

      // Return the vendor spending data from the analytics response
      return {'vendorSpending': analytics['vendorSpending'] ?? []};
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getCategoryAnalysis({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Get all analytics data and extract category information
      final analytics = await getAnalytics(
        startDate: startDate,
        endDate: endDate,
      );

      // Return the category spending data from the analytics response
      return {'categorySpending': analytics['categorySpending'] ?? []};
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getTaxReport({
    required int year,
    String? quarter,
  }) async {
    try {
      // Calculate date range for the tax report
      final DateTime startDate = DateTime(
        year,
        quarter == null ? 1 : ((int.parse(quarter) - 1) * 3 + 1),
        1,
      );
      final DateTime endDate = quarter == null
          ? DateTime(year, 12, 31)
          : DateTime(
              year,
              int.parse(quarter) * 3,
              DateTime(year, int.parse(quarter) * 3 + 1, 0).day,
            );

      // Get analytics data for the specified period
      final analytics = await getAnalytics(
        startDate: startDate,
        endDate: endDate,
      );

      // Since backend doesn't have specific tax endpoint, we'll create simulated tax data
      double totalTaxable = 0.0;
      double totalTaxPaid = 0.0;
      List<Map<String, dynamic>> items = [];

      // Process category spending data to create tax items
      if (analytics.containsKey('categorySpending') &&
          analytics['categorySpending'] is List) {
        for (
          int i = 0;
          i < (analytics['categorySpending'] as List).length;
          i++
        ) {
          final categoryData = analytics['categorySpending'][i];
          if (categoryData is List && categoryData.length >= 2) {
            final category = categoryData[0]?.toString() ?? 'Uncategorized';
            final amount = categoryData[1] is num
                ? (categoryData[1] as num).toDouble()
                : 0.0;

            // Apply different tax rates for different categories (simulated)
            double taxRate = 0.0;
            if (category.toLowerCase().contains('office')) {
              taxRate = 0.05; // 5% for office expenses
            } else if (category.toLowerCase().contains('travel')) {
              taxRate = 0.08; // 8% for travel expenses
            } else if (category.toLowerCase().contains('meals') ||
                category.toLowerCase().contains('entertainment')) {
              taxRate = 0.10; // 10% for meals and entertainment
            } else {
              taxRate = 0.07; // 7% default tax rate
            }

            final taxPaid = amount * taxRate;
            totalTaxable += amount;
            totalTaxPaid += taxPaid;

            items.add({
              'category': category,
              'taxableAmount': amount,
              'taxPaid': taxPaid,
            });
          }
        }
      }

      // Return the simulated tax data
      return {
        'totalTaxable': totalTaxable,
        'totalTaxPaid': totalTaxPaid,
        'items': items,
      };
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  String _handleDioError(DioException e) {
    // Extract request details for better logging
    final requestUrl = e.requestOptions.uri.toString();
    final method = e.requestOptions.method;
    final statusCode = e.response?.statusCode;

    // Log the detailed error for debugging
    AppLogger.error(
      'API Error: ${e.type}',
      context: 'ApiService',
      error:
          'Method: $method, URL: $requestUrl, Status: $statusCode, Message: ${e.message}',
    );

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. The server is taking too long to respond. Please try again later.';

      case DioExceptionType.badResponse:
        var message = 'Unknown error occurred';

        // Try to extract message from different response formats
        if (e.response?.data is Map<String, dynamic>) {
          final responseData = e.response?.data as Map<String, dynamic>;
          // Check for different common field names for error messages
          message =
              responseData['message'] ??
              responseData['error'] ??
              responseData['errorMessage'] ??
              responseData['errorDescription'] ??
              message;
        } else if (e.response?.data is String && e.response!.data.isNotEmpty) {
          message = e.response!.data;
        }

        switch (statusCode) {
          case 400:
            return 'The request was invalid: $message';
          case 401:
            return 'Authentication failed. Please log in again.';
          case 403:
            return 'You don\'t have permission to access this resource.';
          case 404:
            // Give more specific message for 404 on auth endpoints
            if (requestUrl.contains('/auth/login')) {
              return 'Login service is not available. Please check that the backend server is running.';
            }
            return 'The requested resource could not be found. Please verify the server is configured properly.';
          case 500:
          case 502:
          case 503:
            return 'Server error. Our team has been notified of this issue.';
          default:
            return 'Error ($statusCode): $message';
        }

      case DioExceptionType.cancel:
        return 'Request was cancelled';

      case DioExceptionType.unknown:
        // More helpful message for common connection issues
        if (e.message?.contains('SocketException') ?? false) {
          return 'Cannot connect to the server at ${AppConfig.serverIP}:${AppConfig.serverPort}. Please check that the server is running and your network connection is active.';
        } else if (e.message?.contains('Network is unreachable') ?? false) {
          return 'Network is unreachable. Please check your internet connection.';
        } else if (e.message?.contains('Connection refused') ?? false) {
          return 'Connection refused by the server. Please verify the server is running at ${AppConfig.serverIP}:${AppConfig.serverPort}.';
        }
        return 'Network error. Please check your connection and try again.';

      default:
        return 'An unexpected error occurred. Please try again later.';
    }
  }
}
