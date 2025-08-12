import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../utils/logger.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isAuthenticated => _user != null && _authService.isLoggedIn;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isEmailVerified => _user?.emailVerified ?? false;

  AuthProvider() {
    AppLogger.info(
      'Initializing authentication service',
      context: 'AuthProvider',
    );
    _initialize();
  }

  void _initialize() {
    _user = _authService.currentUser;
    if (_user != null) {
      AppLogger.auth('User already logged in: ${_user!.email}');
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    AppLogger.auth('Starting login process for: $email');
    _setLoading(true);
    _setError(null);

    try {
      final response = await _authService.login(email, password);

      // Check if login was successful by verifying we have a user and token
      if (response.user != null && response.token != null) {
        _user = response.user;
        AppLogger.logAuthAction('Login', email: email, success: true);
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        // We got a response but no user/token - likely an error message
        String errorMsg = response.message ?? "Authentication failed";
        AppLogger.logAuthAction('Login', email: email, success: false);
        _setError(errorMsg);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      AppLogger.logAuthAction('Login', email: email, success: false);
      AppLogger.error('Login failed', context: 'AuthProvider', error: e);

      // Provide a more user-friendly error message
      String errorMsg =
          "Connection failed. Please check your network and try again.";
      if (e.toString().contains("404")) {
        errorMsg = "Login service not available. Please try again later.";
      } else if (e.toString().contains("401")) {
        errorMsg = "Invalid email or password.";
      }

      _setError(errorMsg);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register(
    String firstName,
    String lastName,
    String email,
    String password,
  ) async {
    AppLogger.auth('Starting registration process for: $email');
    _setLoading(true);
    _setError(null);

    try {
      await _authService.register(firstName, lastName, email, password);
      // Registration successful - don't save auth data here since we want register -> login flow
      AppLogger.logAuthAction('Registration', email: email, success: true);
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      AppLogger.logAuthAction('Registration', email: email, success: false);
      AppLogger.error('Registration failed', context: 'AuthProvider', error: e);
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authService.logout();
      _user = null;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<bool> requestPasswordReset(String email) async {
    _setLoading(true);
    _setError(null);

    try {
      await _authService.requestPasswordReset(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    return await requestPasswordReset(email);
  }

  Future<bool> resetPassword(String token, String newPassword) async {
    _setLoading(true);
    _setError(null);

    try {
      await _authService.resetPassword(token, newPassword);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> verifyEmail(String token) async {
    _setLoading(true);
    _setError(null);

    try {
      await _authService.verifyEmail(token);
      // Refresh user data
      await refreshUser();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateProfile(String? firstName, String? lastName) async {
    _setLoading(true);
    _setError(null);

    try {
      await _authService.updateProfile(firstName, lastName);
      // Refresh user data
      await refreshUser();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    _setLoading(true);
    _setError(null);

    try {
      await _authService.changePassword(currentPassword, newPassword);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<void> refreshUser() async {
    try {
      await _authService.refreshUser();
      _user = _authService.currentUser;
      notifyListeners();
    } catch (e) {
      AppLogger.error(
        'Error refreshing user',
        error: e,
        context: 'AuthProvider',
      );
      // If refresh fails, user might be logged out
      if (e.toString().contains('401') ||
          e.toString().contains('Unauthorized')) {
        _user = null;
        notifyListeners();
      }
    }
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
}
