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
        logPrint: (obj) => print('[API] $obj'),
      ),
    );
  }

  // Auth APIs
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response = await _dio.post('/auth/login', data: request.toJson());
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
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

  // Export APIs
  Future<Response> exportInvoices({
    String format = 'csv',
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    List<int>? invoiceIds,
  }) async {
    try {
      final queryParams = <String, dynamic>{'format': format};

      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String().split('T')[0];
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String().split('T')[0];
      }
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }
      if (invoiceIds != null && invoiceIds.isNotEmpty) {
        queryParams['invoiceIds'] = invoiceIds.join(',');
      }

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

  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message =
            e.response?.data?['message'] ?? 'Unknown error occurred';
        switch (statusCode) {
          case 400:
            return 'Bad request: $message';
          case 401:
            return 'Unauthorized. Please login again.';
          case 403:
            return 'Forbidden. You don\'t have permission to perform this action.';
          case 404:
            return 'Resource not found.';
          case 500:
            return 'Server error. Please try again later.';
          default:
            return 'Error: $message';
        }
      case DioExceptionType.cancel:
        return 'Request was cancelled';
      case DioExceptionType.unknown:
        return 'Network error. Please check your internet connection.';
      default:
        return 'An unexpected error occurred.';
    }
  }
}
