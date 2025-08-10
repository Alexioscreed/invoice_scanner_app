import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Secure Storage Methods (for sensitive data like tokens)
  Future<void> setSecureString(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  Future<String?> getSecureString(String key) async {
    return await _secureStorage.read(key: key);
  }

  Future<void> removeSecureString(String key) async {
    await _secureStorage.delete(key: key);
  }

  Future<void> clearSecureStorage() async {
    await _secureStorage.deleteAll();
  }

  // Regular Storage Methods (for non-sensitive data)
  Future<void> setString(String key, String value) async {
    await _prefs?.setString(key, value);
  }

  String? getString(String key) {
    return _prefs?.getString(key);
  }

  Future<void> setBool(String key, bool value) async {
    await _prefs?.setBool(key, value);
  }

  bool getBool(String key, {bool defaultValue = false}) {
    return _prefs?.getBool(key) ?? defaultValue;
  }

  Future<void> setInt(String key, int value) async {
    await _prefs?.setInt(key, value);
  }

  int getInt(String key, {int defaultValue = 0}) {
    return _prefs?.getInt(key) ?? defaultValue;
  }

  Future<void> setDouble(String key, double value) async {
    await _prefs?.setDouble(key, value);
  }

  double getDouble(String key, {double defaultValue = 0.0}) {
    return _prefs?.getDouble(key) ?? defaultValue;
  }

  Future<void> setStringList(String key, List<String> value) async {
    await _prefs?.setStringList(key, value);
  }

  List<String> getStringList(String key) {
    return _prefs?.getStringList(key) ?? [];
  }

  Future<void> remove(String key) async {
    await _prefs?.remove(key);
  }

  Future<void> clear() async {
    await _prefs?.clear();
  }

  // JSON Storage Methods
  Future<void> setJson(String key, Map<String, dynamic> value) async {
    await setString(key, jsonEncode(value));
  }

  Map<String, dynamic>? getJson(String key) {
    final jsonString = getString(key);
    if (jsonString != null) {
      try {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      } catch (e) {
        print('Error parsing JSON for key $key: $e');
        return null;
      }
    }
    return null;
  }

  // App-specific Storage Methods
  Future<void> saveAuthToken(String token) async {
    await setSecureString(AppConstants.tokenKey, token);
  }

  Future<String?> getAuthToken() async {
    return await getSecureString(AppConstants.tokenKey);
  }

  Future<void> removeAuthToken() async {
    await removeSecureString(AppConstants.tokenKey);
  }

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    await setSecureString(AppConstants.userKey, jsonEncode(userData));
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final userDataString = await getSecureString(AppConstants.userKey);
    if (userDataString != null) {
      try {
        return jsonDecode(userDataString) as Map<String, dynamic>;
      } catch (e) {
        print('Error parsing user data: $e');
        return null;
      }
    }
    return null;
  }

  Future<void> removeUserData() async {
    await removeSecureString(AppConstants.userKey);
  }

  // Theme and Language Settings
  Future<void> setThemeMode(String themeMode) async {
    await setString(AppConstants.themeKey, themeMode);
  }

  String getThemeMode() {
    return getString(AppConstants.themeKey) ?? 'system';
  }

  Future<void> setLanguage(String languageCode) async {
    await setString(AppConstants.languageKey, languageCode);
  }

  String getLanguage() {
    return getString(AppConstants.languageKey) ?? 'en';
  }

  // App State Storage
  Future<void> setFirstLaunch(bool isFirstLaunch) async {
    await setBool('first_launch', isFirstLaunch);
  }

  bool isFirstLaunch() {
    return getBool('first_launch', defaultValue: true);
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    await setBool('onboarding_completed', completed);
  }

  bool isOnboardingCompleted() {
    return getBool('onboarding_completed', defaultValue: false);
  }

  // Cache Management
  Future<void> setCacheData(
    String key,
    Map<String, dynamic> data, {
    Duration? expiry,
  }) async {
    final cacheItem = {
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'expiry': expiry?.inMilliseconds,
    };
    await setJson('cache_$key', cacheItem);
  }

  Map<String, dynamic>? getCacheData(String key) {
    final cacheItem = getJson('cache_$key');
    if (cacheItem != null) {
      final timestamp = cacheItem['timestamp'] as int?;
      final expiryDuration = cacheItem['expiry'] as int?;

      if (timestamp != null && expiryDuration != null) {
        final expiryTime = timestamp + expiryDuration;
        if (DateTime.now().millisecondsSinceEpoch > expiryTime) {
          // Cache expired
          remove('cache_$key');
          return null;
        }
      }

      return cacheItem['data'] as Map<String, dynamic>?;
    }
    return null;
  }

  Future<void> clearCache() async {
    final keys = _prefs?.getKeys() ?? <String>{};
    for (final key in keys) {
      if (key.startsWith('cache_')) {
        await remove(key);
      }
    }
  }

  // Recent Searches
  Future<void> addRecentSearch(String query) async {
    final recentSearches = getStringList('recent_searches');
    recentSearches.remove(query); // Remove if exists
    recentSearches.insert(0, query); // Add to beginning

    // Keep only last 10 searches
    if (recentSearches.length > 10) {
      recentSearches.removeRange(10, recentSearches.length);
    }

    await setStringList('recent_searches', recentSearches);
  }

  List<String> getRecentSearches() {
    return getStringList('recent_searches');
  }

  Future<void> clearRecentSearches() async {
    await remove('recent_searches');
  }

  // Recent Categories
  Future<void> addRecentCategory(String category) async {
    final recentCategories = getStringList('recent_categories');
    recentCategories.remove(category);
    recentCategories.insert(0, category);

    if (recentCategories.length > 5) {
      recentCategories.removeRange(5, recentCategories.length);
    }

    await setStringList('recent_categories', recentCategories);
  }

  List<String> getRecentCategories() {
    return getStringList('recent_categories');
  }
}
