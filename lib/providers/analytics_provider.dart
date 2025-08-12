import 'package:flutter/foundation.dart';

import '../models/chart_data.dart';
import '../services/analytics_service.dart';

class AnalyticsProvider with ChangeNotifier {
  final AnalyticsService _analyticsService = AnalyticsService();

  // State management
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Current filter state
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedPeriod = 'monthly';
  int _selectedYear = DateTime.now().year;
  String? _selectedQuarter;

  // Getters for current filter state
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  String get selectedPeriod => _selectedPeriod;
  int get selectedYear => _selectedYear;
  String? get selectedQuarter => _selectedQuarter;

  // Data containers
  List<ChartData> _expenseData = [];
  List<ChartData> _vendorData = [];
  List<ChartData> _categoryData = [];
  List<ChartData> _taxData = [];

  // Getters for data
  List<ChartData> get expenseData => _expenseData;
  List<ChartData> get vendorData => _vendorData;
  List<ChartData> get categoryData => _categoryData;
  List<ChartData> get taxData => _taxData;

  // Available options
  List<int> _availableYears = [];
  List<int> get availableYears => _availableYears;
  List<String> get periodOptions => AnalyticsService.periodOptions;

  // Initialize data
  Future<void> init() async {
    await _loadAvailableYears();
  }

  // Set date range filter
  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    notifyListeners();
  }

  // Set period filter
  void setPeriod(String period) {
    _selectedPeriod = period;
    notifyListeners();
  }

  // Set year filter
  void setYear(int year) {
    _selectedYear = year;
    notifyListeners();
  }

  // Set quarter filter
  void setQuarter(String? quarter) {
    _selectedQuarter = quarter;
    notifyListeners();
  }

  // Load expense data
  Future<void> loadExpenseData() async {
    _setLoading(true);
    try {
      _expenseData = await _analyticsService.getExpenseChartData(
        period: _selectedPeriod,
        startDate: _startDate,
        endDate: _endDate,
      );
      _clearError();
    } catch (e) {
      _setError('Failed to load expense data: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load vendor data
  Future<void> loadVendorData() async {
    _setLoading(true);
    try {
      _vendorData = await _analyticsService.getVendorChartData(
        startDate: _startDate,
        endDate: _endDate,
      );
      _clearError();
    } catch (e) {
      _setError('Failed to load vendor data: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load category data
  Future<void> loadCategoryData() async {
    _setLoading(true);
    try {
      _categoryData = await _analyticsService.getCategoryChartData(
        startDate: _startDate,
        endDate: _endDate,
      );
      _clearError();
    } catch (e) {
      _setError('Failed to load category data: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load tax data
  Future<void> loadTaxData() async {
    _setLoading(true);
    try {
      _taxData = await _analyticsService.getTaxChartData(
        year: _selectedYear,
        quarter: _selectedQuarter,
      );
      _clearError();
    } catch (e) {
      _setError('Failed to load tax data: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load all data at once
  Future<void> loadAllData() async {
    _setLoading(true);
    try {
      await Future.wait([
        loadExpenseData(),
        loadVendorData(),
        loadCategoryData(),
        loadTaxData(),
      ]);
      _clearError();
    } catch (e) {
      _setError('Failed to load analytics data: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Refresh all data
  Future<void> refreshData() async {
    _analyticsService.clearCache();
    await loadAllData();
  }

  // Load available years
  Future<void> _loadAvailableYears() async {
    try {
      _availableYears = await _analyticsService.getAvailableYears();
      if (_availableYears.isNotEmpty) {
        _selectedYear = _availableYears.first;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading available years: $e');
      }
      // Default to current year if loading fails
      _availableYears = [DateTime.now().year];
      _selectedYear = DateTime.now().year;
    }
  }

  // Helper to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Helper to set error state
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  // Helper to clear error state
  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
