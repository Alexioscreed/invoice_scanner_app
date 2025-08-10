import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import '../models/user.dart';
import '../models/auth_models.dart';
import 'api_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final ApiService _apiService = ApiService();

  User? _currentUser;
  String? _currentToken;

  User? get currentUser => _currentUser;
  String? get currentToken => _currentToken;
  bool get isLoggedIn => _currentToken != null && _currentUser != null;

  Future<void> init() async {
    await _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      _currentToken = await _storage.read(key: AppConstants.tokenKey);
      final userJson = await _storage.read(key: AppConstants.userKey);

      if (userJson != null) {
        _currentUser = User.fromJson(jsonDecode(userJson));
      }
    } catch (e) {
      print('Error loading auth data from storage: $e');
      await clearAuth();
    }
  }

  Future<AuthResponse> login(String email, String password) async {
    try {
      final request = LoginRequest(email: email, password: password);
      final response = await _apiService.login(request);

      if (response.token != null && response.user != null) {
        await _saveAuthData(response.token!, response.user!);
      }

      return response;
    } catch (e) {
      throw e;
    }
  }

  Future<AuthResponse> register(
    String firstName,
    String lastName,
    String email,
    String password,
  ) async {
    try {
      final request = RegisterRequest(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
      );

      final response = await _apiService.register(request);

      if (response.token != null && response.user != null) {
        await _saveAuthData(response.token!, response.user!);
      }

      return response;
    } catch (e) {
      throw e;
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.logout();
    } catch (e) {
      print('Error during logout: $e');
    } finally {
      await clearAuth();
    }
  }

  Future<void> requestPasswordReset(String email) async {
    try {
      final request = PasswordResetRequest(email: email);
      await _apiService.requestPasswordReset(request);
    } catch (e) {
      throw e;
    }
  }

  Future<void> verifyEmail(String token) async {
    try {
      await _apiService.verifyEmail(token);

      // Refresh user data after email verification
      if (isLoggedIn) {
        await refreshUser();
      }
    } catch (e) {
      throw e;
    }
  }

  Future<void> updateProfile(String? firstName, String? lastName) async {
    try {
      final request = UpdateProfileRequest(
        firstName: firstName,
        lastName: lastName,
      );

      final updatedUser = await _apiService.updateProfile(request);
      _currentUser = updatedUser;

      await _storage.write(
        key: AppConstants.userKey,
        value: jsonEncode(updatedUser.toJson()),
      );
    } catch (e) {
      throw e;
    }
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final request = ChangePasswordRequest(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      await _apiService.changePassword(request);
    } catch (e) {
      throw e;
    }
  }

  Future<void> refreshUser() async {
    try {
      if (!isLoggedIn) return;

      final user = await _apiService.getCurrentUser();
      _currentUser = user;

      await _storage.write(
        key: AppConstants.userKey,
        value: jsonEncode(user.toJson()),
      );
    } catch (e) {
      print('Error refreshing user: $e');
      // If refresh fails due to auth error, clear auth data
      if (e.toString().contains('401') ||
          e.toString().contains('Unauthorized')) {
        await clearAuth();
      }
      throw e;
    }
  }

  Future<void> _saveAuthData(String token, User user) async {
    _currentToken = token;
    _currentUser = user;

    await _storage.write(key: AppConstants.tokenKey, value: token);
    await _storage.write(
      key: AppConstants.userKey,
      value: jsonEncode(user.toJson()),
    );
  }

  Future<void> clearAuth() async {
    _currentToken = null;
    _currentUser = null;

    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.userKey);
  }

  bool get isEmailVerified => _currentUser?.emailVerified ?? false;

  String get userFullName => _currentUser?.fullName ?? 'User';
  String get userEmail => _currentUser?.email ?? '';
  int? get userId => _currentUser?.id;
}
