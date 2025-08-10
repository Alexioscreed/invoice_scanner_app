import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

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
    _initialize();
  }

  void _initialize() {
    _user = _authService.currentUser;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _authService.login(email, password);
      _user = response.user;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
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
    _setLoading(true);
    _setError(null);

    try {
      final response = await _authService.register(
        firstName,
        lastName,
        email,
        password,
      );
      _user = response.user;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
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
      print('Error refreshing user: $e');
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
